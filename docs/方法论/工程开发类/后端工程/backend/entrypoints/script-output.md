---
description: 后端项目脚本面向人的可视化输出、状态词、失败提示与工具输出透传规则
---

# 脚本输出规范

脚本输出规范负责让开发者、运维者和 Agent 在不阅读脚本实现的情况下，快速判断命令正在做什么、结果是否成功、失败后下一步看哪里。它只约束脚本面向人的终端输出，不替代应用结构化日志、机器可读协议、部署平台事件或业务排障结果定义。

## 心智模型

项目脚本是操作门面，不是应用日志系统。脚本输出应优先回答三个问题：

```text
当前执行到哪一组动作
每个动作的结果是什么
失败或异常时下一步该做什么
```

好的脚本输出不是把所有底层命令原样打印出来，而是在保留必要证据的同时，把动作、状态、对象和下一步组织成可扫读的结构。底层工具输出可以透传，但必须让读者知道它属于哪个阶段、是否影响脚本最终结果。

## 输出层级

脚本输出默认使用三层结构：

| 层级 | 形式 | 负责 |
| --- | --- | --- |
| 阶段 | `== Env Config ==` | 标明当前检查、启动、部署或排障阶段 |
| 事件 | `OK        .env.example present` | 用固定状态词描述一个对象的一次结果 |
| 细节 | `    log:      logs/api.log` | 补充 URL、PID、日志、端口、下一步命令等证据 |

阶段名称使用短英文标题，保持稳定、可搜索、便于 Agent 和 CI 日志定位。事件行必须能独立理解：状态词、对象和说明缺一不可。

示例：

```text
== Application ==
STARTED   api        pid=18241 log=logs/api.log url=http://127.0.0.1:8100
READY     api        http://127.0.0.1:8100/health
```

## 状态词

脚本状态词使用固定大写英文，不翻译成中文。状态词是扫读锚点，也便于在终端、日志和 Agent 输出中搜索。

| 状态词 | 含义 | 使用场景 |
| --- | --- | --- |
| `OK` | 单项检查通过 | 文件存在、语法检查、配置校验、help smoke |
| `ERROR` | 命令失败且脚本应退出 | 缺文件、非法参数、健康检查超时、配置冲突 |
| `WARN` | 有风险但当前命令仍可继续 | 非阻塞弃用项、开发态安全提醒、可延后处理的问题 |
| `SKIP` | 有意跳过 | 目标不存在、可选能力未启用、当前模式不需要执行 |
| `INFO` | 中性信息 | 模式说明、边界说明、当前选择的配置文件 |
| `RUN` | 即将执行外部命令 | build、compose、pytest、migration 等耗时动作 |
| `READY` | 依赖或服务已可用 | 容器 healthy、API health 通过 |
| `STARTED` | 服务进程已启动 | API、worker、scheduler 等后台进程 |
| `RUNNING` | 服务此前已经运行 | 重复 start 时发现已有进程 |
| `STOPPING` | 正在停止 | stop/restart 的中间状态 |
| `STOPPED` | 已停止或确认未运行 | 服务停止结果 |
| `STALE` | 记录存在但事实已失效 | pid 文件失效、容器记录残留 |

不要为同一语义创造多个状态词，例如不要混用 `PASS`、`SUCCESS`、`DONE` 表示 `OK`。需要表达更具体的业务状态时，把状态放在对象或说明里，不扩展脚本状态词。

## 中英文边界

脚本输出允许中文和英文混合，但两者职责不同。

| 内容 | 语言规则 |
| --- | --- |
| 状态词 | 固定英文大写，例如 `OK`、`ERROR`、`READY` |
| 阶段名 | 优先短英文，例如 `Files`、`Env Config`、`Compose Config` |
| 命令、路径、配置键、服务名、协议、状态码 | 保留英文原文，例如 `.env.example`、`DATABASE_URL`、`api`、`HTTP 503` |
| 原因、影响、边界、下一步 | 使用中文说明，必要时嵌入英文命令或配置键 |
| help 文档 | 中文为主，命令、参数、路径和配置键保留英文 |

避免把所有内容机械翻译成中文。例如 `Dockerfile present` 可以保留为稳定事件说明；但失败原因应写成中文或中英混合的完整句子：

```text
ERROR: .env 缺少 DATABASE_URL；先运行 ./scripts/dev.sh bootstrap，或从 .env.example 补齐该键
```

## 成功输出

成功输出应短、稳定、可扫读。每个阶段只输出关键结果，不输出实现细节。

推荐：

```text
== Files ==
OK        Dockerfile present
OK        .env.example present

== Scripts ==
OK        scripts/dev.sh syntax
OK        scripts/verify.sh syntax
```

不推荐：

```text
checking file Dockerfile...
Dockerfile is ok
now checking env example...
everything seems fine
```

成功输出不需要解释“为什么成功”，但需要在涉及副作用时说明结果位置，例如 PID、日志文件、URL、镜像 tag、生成文件路径。

## 失败输出

失败输出必须包含对象、原因和下一步。不要只打印底层命令的错误，也不要用宽泛提示让用户自行猜测。

推荐结构：

```text
ERROR: api health check failed after 30s；查看日志：./scripts/dev.sh logs api
```

更复杂的失败可以使用阶段、事件和细节：

```text
== Env Config ==
ERROR     .env       unknown key: OPENAI_MODEL
    hint:     删除派生配置 OPENAI_MODEL；模型选择应由 Settings 中的 ai_provider 配置派生
```

失败时不得 silent fallback。脚本可以在失败前输出必要证据，例如最近日志、compose 状态、端口占用 PID，但这些证据必须围绕失败对象，不要倾倒整段无关输出。

## 工具输出透传

脚本可以调用 `pytest`、`docker compose`、`alembic`、`uv`、`curl` 等外部工具。工具输出分两类处理：

| 类型 | 处理方式 |
| --- | --- |
| 脚本需要归纳的检查 | 静默执行，成功后输出一行脚本事件，例如 `OK compose-full docker compose --profile app config` |
| 工具本身就是用户要看的结果 | 透传原始输出，但必须先用阶段名标明来源，例如 `== Test ==` |

透传工具输出时，脚本仍要保证边界清楚：

- 阶段名必须说明这段输出属于什么工具或任务。
- 成功或失败标准必须能在 help 或命令说明中找到。
- 如果工具输出包含大量噪声，优先使用工具的 quiet 模式，再由脚本输出摘要。
- 应用日志被验证脚本触发时，应尽量隔离或降噪，避免用户误以为它是脚本状态。
- 失败时可以保留工具原始错误，但脚本应补一条可执行的中文下一步。

例如 `verify.sh check` 透传 pytest 是合理的，因为测试结果本身需要被用户看到；但 registry 检查中如果应用启动日志不是判断结果的一部分，应优先降噪或在阶段中明确这是被检查模块的启动日志。

## 命令类型规则

不同脚本命令的输出关注点不同。

| 命令类型 | 必须输出 | 避免输出 |
| --- | --- | --- |
| `help` | 作用域、命令、参数、成功标准、保护边界 | 实现细节、过长教程、临时排障记录 |
| `check` | 检查阶段、每项结果、失败对象、最终失败原因 | 大量无关工具日志、重复解释成功项 |
| `start` | 启动对象、PID、日志、URL、健康检查结果 | 后台服务完整日志、重复打印环境变量 |
| `stop` | 停止对象、PID、已停止或 stale 状态 | 不必要的进程列表 |
| `status` | 服务状态、健康检查、端口、日志位置 | 启动命令全文、敏感配置 |
| `logs` | 明确服务名后透传日志 | 同时混合多个服务日志且无标签 |
| `deploy` | 部署模式、配置文件、compose 或发布阶段、最终状态 | 平台无关的生产操作猜测 |
| `smoke` / `e2e` | 目标环境、测试对象、关键 ID、最终结果、失败下一步 | 隐藏真实调用副作用、吞掉外部系统错误 |

脚本职责边界读取 [`project-entrypoints.md`](project-entrypoints.md) 和 [`script-topology.md`](script-topology.md)。运行时排障脚本的查询字段和证据完整性读取 [`runtime-troubleshooting.md`](runtime-troubleshooting.md)。

## 机器可读输出

面向人的输出不应被当作稳定机器协议。如果命令需要被 CI、平台、Agent 或其他脚本稳定解析，应提供显式机器输出模式，例如：

```text
./scripts/dev.sh ports --format json
./scripts/ops.sh job show --job-id <id> --format json
```

机器输出模式必须满足：

- 只输出目标格式，不混入彩色文本、进度条或解释性自然语言。
- 字段名稳定，新增字段保持向后可忽略。
- 错误输出仍走 `stderr`，退出码表达成功或失败。
- 敏感值默认脱敏，除非命令明确是受控授权入口。

不要让下游解析 `OK        api healthy` 这类人读表格；表格可以调整，JSON schema 才能作为机器契约。

## 安全与脱敏

脚本输出默认不得泄露：

- token、API key、password、cookie、authorization header。
- 完整数据库连接串中的用户名、密码和公网地址。
- 完整请求体、模型输入文本、供应商原始响应、隐私字段。
- Kubernetes Secret、完整 ConfigMap、云平台凭证。

配置检查可以输出键名和文件名，不输出密钥值。URL 如包含凭证必须脱敏；本地端口、健康检查 URL、日志路径、PID 可以直接输出。

开发态安全提醒应使用 `WARN` 或清晰中文提示，并说明只适用于本地。例如：

```text
WARN      registry  insecure HTTP auth/caller header disable flag enabled；仅限本地开发
```

## Shell 实现约束

Shell 脚本应把输出格式集中到公共函数中维护，不在各脚本里随手 `echo` 出不同格式。

推荐公共函数：

```bash
section "Env Config"
event "OK" ".env.example" "present"
row "api" "running" "pid=18241"
detail "log" "logs/api.log"
die ".env 缺少 DATABASE_URL；运行 ./scripts/dev.sh bootstrap"
```

入口脚本和原子脚本都应复用同一套 helper。新增 helper 前先判断是否是稳定输出层级；不要为了单个脚本创建一次性格式。

## 验收清单

新增或修改脚本输出时，至少确认：

- `help` 说明了命令作用域、成功标准和保护边界。
- 每段输出有稳定阶段名。
- 每个事件行都有状态词、对象和说明。
- 成功输出短而稳定；副作用输出包含 PID、日志、URL 或文件位置。
- 失败输出包含对象、原因和下一步。
- 外部工具输出要么被 quiet 后汇总，要么有明确阶段边界。
- 面向人的表格没有被其他脚本当作机器协议解析。
- 密钥、token、连接串和隐私内容不会出现在 stdout 或 stderr。
- shell 文件通过语法检查；涉及 JSON 输出时有最小解析验证。
