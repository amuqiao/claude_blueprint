# Python Script

## 适用边界

这份真源只处理一类脚本：

- 输入是一批任务
- 核心操作是调用外部 API
- 最终为每个任务生成文件产物
- 难点集中在并发、重试、日志、报告和输出目录管理

## 最小结构

推荐至少包含这些层次：

1. 模块文档字符串
2. `Config`
3. `Task`
4. `Job`
5. `Result`
6. 工具函数
7. `call_one`
8. `retry_call`
9. `build_job_list`
10. `write_report`
11. `_dry_run`
12. `main`

## 数据结构边界

- `Config`：运行参数和全局配置
- `Task`：用户意图或业务任务
- `Job`：单次 API 调用的完整上下文
- `Result`：单次调用的结果快照

规则：

- 层间优先传 dataclass，不传散装参数
- 一个参数只在一个层级定义
- `Job` 应足够表达单次调用与保存上下文

## 函数职责边界

- `call_one`：只做单次 API 调用和结果保存
- `retry_call`：只做重试和退避
- `build_job_list`：只做任务展开
- `write_report`：只做报告写出
- `main`：只做初始化、校验和编排

## 并发规则

如果需要并发：

- 先完整构建 `jobs`
- 再进入 executor
- 某个 job 失败时，记录失败结果，但不阻断全部任务

## 超时与重试

- 超时和重试都作用于单个 job，不作用于整个 task
- 在 `call_one` 处设置单次调用超时
- 在 `retry_call` 处统一处理可重试错误

## 日志、输出与 dry-run

至少要明确：

- 输出目录放在哪
- 日志放在哪
- 报告是否生成
- `--dry-run` 做什么，不做什么

`--dry-run` 的最低要求：

- 不调 API
- 不写文件
- 打印配置摘要和 job 展开结果
