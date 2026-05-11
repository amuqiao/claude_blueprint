---
name: python-script
description: 新建批量 API 调用脚本时调用；Review 现有脚本时对照自检清单。识别方法：输入是一批任务，输出是每个任务的文件产物，核心操作是调用外部 API。触发词：批量脚本、API 调用脚本、Job 并发、批量处理、批量生成
---

# Python 脚本编写规范

> **文档职责**：定义跨项目可复用的批量 API 调用 Python 脚本架构标准，覆盖模块结构、数据模型、函数职责、并发、重试、输出等层面；不约束具体实现细节。
> **适用场景**：新建批量 API 调用脚本前、Review 现有脚本时、向 Claude 描述脚本需求前澄清标准。
> **目标读者**：全栈项目开发者及 Claude CLI；具备 Python 中级水平，熟悉 HTTP API 调用。
> **维护规范**：新增或修改脚本模式时，须先更新本文档对应章节；脚本实现与规范冲突时以规范为准，偏差须在对应章节注明原因。

---

## 适用边界

| 规范 | 适用场景 | 核心关切 |
|------|---------|---------|
| `shell服务管理规范.md` | `dev.sh` 类 Bash 脚本 | 进程生命周期（start/stop/restart） |
| **本规范** | 批量 API 调用脚本 | Job 并发、重试、文件输出 |
| `python运维CLI规范.md` | 运维诊断 CLI 工具 | 数据诊断、跨层查询、安全变更 |

**识别方法**：满足以下全部条件时适用本规范：
- 输入是一批任务（task list），输出是每个任务的文件产物
- 核心操作是调用外部 API（每个 job 一次或多次 HTTP 请求）
- 关键挑战是并发控制、失败重试和文件输出管理

---

## 0. 设计原则

| 原则 | 含义 |
|---|---|
| 职责单一 | `call_one` 只调 API、`run_jobs` 只编排、`write_report` 只写文件，三者互不越界 |
| 边界清晰 | 层间只传 dataclass（Job / Result），禁止传散装参数 |
| 依赖单向 | Config → Task → Job → Result，下层不引用上层 |
| 对扩展开放 | 新任务只改 `cfg.tasks`；新维度只改 `Task` + `build_job_list()`；核心函数签名不动 |

---

## 1. 文件整体结构

模块内顺序固定，不可调换：

1. 模块文档字符串
2. 标准库 import（按字母序）
3. 第三方库 import（按字母序）
4. logging 初始化
5. PROJECT_ROOT 常量（指向项目根目录）
6. Config dataclass（仅类定义）
7. Task dataclass
8. `cfg = Config(...)` 实例
9. Job / Result dataclass
10. 常量（大型字符串等）
11. 纯工具函数
12. 核心 API 调用函数（`call_one`）
13. `retry_call`
14. `build_job_list`
15. 报告写出函数（`write_task_report` / `write_report`）
16. `_dry_run()`
17. `main()`
18. `if __name__ == "__main__": main()`

---

## 2. 模块文档字符串

必须包含以下各节，无内容的可选节省略：

| 节 | 内容 | 是否必填 |
|---|---|---|
| 功能 | 脚本做什么、面向谁，列出各功能点 | 必填 |
| 依赖 | 输入文件路径与格式、Python 依赖包及版本 | 有则必填 |
| 配置方式 | 说明用户应修改 `cfg = Config(...)` 哪些字段 | 必填 |
| 输出 | 输出目录结构 | `log_to_file=False` 且 `write_report=False` 时省略 |
| 运行方式 | `uv run <script>.py [--help] [--dry-run]` | 必填 |

`--dry-run` 行为：不调 API，不写文件，打印配置摘要和完整 job 清单；`cfg.tasks` 为空则警告退出。

---

## 3. Config 规范

Config 字段分为四组，组内顺序固定：

| 组 | 内容 | 默认值策略 |
|---|---|---|
| 1. 任务 | `tasks: list[Task]`、`output_dir` | 结构性默认值 |
| 2. 业务参数 | 用户每次运行必须决策的参数 | **无默认值**（缺失则 Python 报错） |
| 3. 运行参数 | `workers`、`request_timeout_sec`、重试参数、`log_to_file`、`write_report` | `workers` 等有默认值；超时与重试次数**无默认值**，各脚本必须显式决策 |
| 4. API 凭证 | `api_key`、`model` | 留空走环境变量 |

**规则：**
- 有默认值 = 用户通常不改；无默认值 = 用户每次必须决策
- `api_key` 留空时由 `main()` 从环境变量解析；Config 自身不调用环境变量
- `cfg` 显式传入每个需要它的函数（`main()` / `_dry_run()` 除外）
- Task 的业务参数无默认值；结构性可选字段保留默认值

**配置说明：**
- `cfg = Config(...)` 按四组配置时，每组前添加分组注释
- 需要用户决策的配置项，应补充可选值与简要说明，使用户无需阅读实现即可完成配置

---

## 4. 数据结构：Task / Job / Result

三个 dataclass 职责严格分层：

| dataclass | 职责 | 关键约束 |
|---|---|---|
| Task | 表达用户意图的业务配置 | 业务参数无默认值；`task_name` 必填，禁止含路径分隔符 |
| Job | 单次 API 调用的完整上下文 | `key` 只含结构维度，禁止放 prompt；含 `task_output_dir` |
| Result | 单次调用的结果快照 | `saved_paths: list[Path]`（空列表 = 失败）；`error: Exception \| None` |

Job `key` 格式：`"{task_name}|{dim1}|{dim2}..."`，只含可枚举的结构维度。

**参数归属规则：** 每个参数只在一个层级声明，禁止跨层覆盖链（如 Config 全局默认 + 子对象局部覆盖）。同一字段存在多种变体时，每种变体定义独立 dataclass，以类型做分支，不用字符串字段。

---

## 5. main() 初始化顺序

顺序固定，不可调换：

1. flag 处理（`--help` / `--dry-run`）
2. API Key 校验；未配置则 `sys.exit`
3. 输入文件校验（按需）；缺失则 `sys.exit`
4. 计算 `run_dir`；仅当需要输出时 `mkdir`；立即设 `run_t0`
5. `log_to_file` 时挂载 summary 级 FileHandler
6. `build_job_list()` + 打印启动日志
7. `log_to_file` 时为每个 task 挂载 per-task FileHandler
8. `run_jobs()` → `list[Result]`
9. `write_report` 时写报告
10. 打印统计摘要；全部失败时 `sys.exit(1)`

---

## 6. 函数职责

| 函数 | 可以做 | 禁止做 |
|---|---|---|
| 工具函数 | 纯计算、字符串处理 | 调用 API、写文件、打印日志 |
| `call_one` | 单次 API 调用 + 保存，成功返回 `list[Path]`，失败只抛异常 | 重试、返回空列表表示失败 |
| `retry_call` | 重试和退避 | 含业务逻辑 |
| `run_jobs` | 并发编排，收集 `list[Result]` | 直接调 API、写文件 |
| `write_report` | 读 `list[Result]`、写 Markdown | 调用 API、修改 results |
| `main()` | 校验、初始化、编排、统计 | 业务计算、直接调 API |

函数参数上限 5 个。

---

## 7. 并发规范

- 使用 `ThreadPoolExecutor`
- `jobs` 在进入 executor 前完整构建，不在内部动态追加
- 某 job 失败：封装为 `Result(job, saved_paths=[], error=exc)`，继续其他 job
- task 最后一个 job 完成后立即写任务级报告（Ctrl+C 中断后已完成 task 仍有报告）
- `workers` 默认 4，不超过 10

---

## 8. 超时与重试规范

**作用层级：两者均作用于 Job 级别（单次 API 调用），不作用于 Task 级别。**

- 超时对应单次 HTTP 调用的响应等待上限，在 `call_one` 处通过 HTTP client 配置
- 重试是对单次调用失败的响应，由 `retry_call` 包裹 `call_one` 实现
- Task 不设超时和重试；Task 的失败状态由其下所有 `Result.saved_paths` 为空来表达，上层统计，不干预执行

两者的具体取值（超时秒数、重试次数）属于各脚本的业务决策，在 Config 第 3 组中显式配置，规范不设全局默认值。

**重试机制：**
- 捕获 `APIConnectionError` 和 `APIStatusError`
- 可重试状态码：`{408, 409, 429, 500, 502, 503, 504}`
- 指数退避；重试次数在 Config 中配置
- 4xx 非可重试状态码直接 raise；其他异常类型穿透，不触发重试
- `call_one()` 内部不含重试逻辑

---

## 9. 日志规范

日志格式：`%(asctime)s  %(levelname)-8s  %(message)s`，时间格式 `%H:%M:%S`。

| 阶段 | 级别 | 内容要点 |
|---|---|---|
| 启动摘要 | INFO | 模型、workers、总 job 数、输出目录 |
| 每 job 完成 | INFO | `✓ 完成  [key]  → file  耗时 Xs` |
| 每 job 失败 | ERROR | `✗ 失败  [key]  耗时 Xs  原因：...` |
| 重试触发 | WARNING | `重试 N/N，Xs 后，原因：...` |
| 任务完成摘要 | INFO | 墙钟 + avg/min/max |
| 脚本完成 | INFO | `全部完成  成功 N  失败 N  总耗时 Xs` |
| 脚本耗时明细 | INFO | `  └ task  墙钟 Xs  成功 N  avg Xs` |

禁止使用 `print()`；只用模块级 `log`。

**计时层级：**
- Job 级：job 执行闭包内计时，随完成日志打印，不存入 Result
- Task 级：第一个 job 开始 → 最后一个 job 结束（墙钟）
- 脚本级：`run_t0` 在 `run_dir` 计算后立即设置

---

## 10. 输出与报告

### 目录结构

```text
data/
└── <script_stem>/
    └── <YYYYMMDD_HHMMSS>/
        ├── summary_run.log     ← log_to_file=True 时生成
        ├── summary_report.md   ← write_report=True 时生成
        └── <task_name>/
            ├── run.log         ← log_to_file=True 时生成
            ├── report.md       ← write_report=True 时生成
            └── <输出文件>
```

`summary_` 前缀 = 跨任务聚合层；无前缀 = 单任务层。两者均 False 时不创建 `run_dir`。

### 文件命名

格式：`{dim}_{n:02d}_{model_safe}.{ext}`

- `dim`：job key 最后一个 `|` 后的部分
- `n`：两位补零（01、02……）
- `model_safe`：路径非法字符（`/ \ : * ? " < > |`）替换为 `-`，空则用 `unnamed`

### 报告格式

```markdown
# 任务报告：<task_name>

生成时间：YYYY-MM-DD HH:MM:SS

## <维度>：<描述>

![filename](filename)
_生成失败：{error}_
```

图片路径相对于 `report.md` 所在目录，禁止绝对路径。

---

## 11. 错误处理

| 错误类型 | 处理方式 |
|---|---|
| API Key 未填 | `sys.exit` in `main()` |
| 输入文件不存在 | `sys.exit` in `main()` |
| 单个 job 可重试失败 | 退避重试，耗尽后抛异常 |
| 单个 job 最终失败 | `Result(job, saved_paths=[], error=exc)`，继续其他 |
| 全部失败 | `sys.exit(1)` |
| 未知异常 | 穿透 `retry_call`，由 `run_jobs` 兜底 |

---

## 12. 代码规范

| 对象 | 命名规范 | 示例 |
|---|---|---|
| 函数 / 变量 | `snake_case` | `build_job_list` |
| 私有函数 | `_snake_case` | `_safe_name` |
| 常量 | `UPPER_SNAKE_CASE` | `PROMPT_TEMPLATE` |
| dataclass | `PascalCase` | `Config` / `Task` / `Job` / `Result` |
| job key | `"{task_name}|{dim...}"` | `"封面|西语"` |
| 输出文件 | `{dim}_{n:02d}_{model_safe}.{ext}` | `西语_01_gpt-4o.txt` |

- 所有函数有完整参数类型注解和返回值注解；联合类型用 `X | None`，不用 `Optional`
- 只写 WHY 注释，不写 WHAT

---

## 13. 自检清单

**文档与配置**
- [ ] 文档字符串包含：功能 / 依赖 / 配置方式 / 运行方式
- [ ] Config 字段分 4 组，顺序正确；业务参数无默认值，可选字段有默认值
- [ ] `cfg = Config(...)` 含分组注释；需要用户决策的配置项有可选值与简要说明
- [ ] `cfg` 显式传入每个需要它的函数

**数据结构**
- [ ] 层间传递 dataclass，未用裸 dict
- [ ] `Job.key` 只含结构维度，未混入 prompt
- [ ] `Result.saved_paths` 为空列表表示失败，不用 None
- [ ] 每个参数只在一个层级声明，无跨层覆盖链；多变体时独立 dataclass，不用字符串字段分支

**函数职责**
- [ ] `call_one` 失败只抛异常，不返回空列表，无重试逻辑
- [ ] `retry_call` 无业务逻辑
- [ ] 各函数参数不超过 5 个

**并发与稳定性**
- [ ] job 列表在进入 executor 前完整构建
- [ ] 单 job 失败不中断其他；全部失败时 `sys.exit(1)`

**输出控制**
- [ ] `log_to_file=False` 时不创建任何日志文件
- [ ] `write_report=False` 时不写任何 Markdown 报告
- [ ] 两者均 False 时不创建 `run_dir`

**main() 顺序**
- [ ] 初始化顺序与 §5 一致

**输出格式**
- [ ] 文件名含两位补零序号，model 名经非法字符处理
- [ ] report 图片路径为相对路径，禁止绝对路径
