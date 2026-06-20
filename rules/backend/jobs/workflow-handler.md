---
description: 后端异步 Job workflow handler、job_type 与运行时扩展规则
---

# Workflow Handler 通用规则

Workflow Handler 规则适用于一个异步 Job 服务需要支持多个 `job_type`、多个执行模式或多个业务处理器的场景。它补充 [`async-job.md`](async-job.md)，不替代状态机、队列投递、恢复扫描、执行器映射或外部集成规则。

## 适用边界

适用场景：

- 同一个 Job 壳承载多个任务类型。
- 不同 `job_type` 有不同入参、执行计划、结果契约或 callback 策略。
- 需要在通用 Job 系统上接入 AI、文件处理、第三方写回或分片执行。

不适用场景：

- 只有一个稳定同步接口。
- 只有一个简单后台任务，且没有扩展 `job_type` 的需求。
- 业务流程编排平台。Job 服务只执行单个任务，不决定上层业务步骤如何串联。

## Job 壳与业务处理器

通用 Job 壳应稳定，业务差异下沉到 handler：

```text
create job
  -> stable job envelope
  -> job_type
  -> WorkflowHandler
  -> execution plan
  -> work items
  -> canonical result
  -> public result / callback
```

创建入口的顶层字段应保持少量稳定字段，例如 `client_request_id`、`job_type`、`job_params`、`callback`、`metadata`、`options`。具体业务入参由 `job_type` 对应的 `job_params` schema 定义。

## Handler 契约

每个 handler 至少明确：

- `job_type`：稳定、唯一、可向调用方暴露。
- `params_schema`：校验并规范化 `job_params`。
- `runtime_job_fields`：生成执行时需要的模型、Prompt、外部服务目标或其他运行时字段。
- `build_execution_plan`：返回 `single` 或 `chunked` 等执行计划。
- `canonical_result_schema`：服务内部完整结果契约。
- `public_result_schema`：对调用方暴露的结果契约；允许显式为 `null`。
- `allow_callback`：声明该 `job_type` 是否支持 callback。

handler 注册必须有统一入口。创建入口、Worker、scheduler 和排障命令都必须读取同一份已注册 handler 契约。

## 执行计划

执行计划应保存为可恢复、可校验的数据，而不是只存在于内存：

```text
single
  -> whole
  -> finalize

chunked
  -> chunk[n]
  -> merge
  -> finalize

chunked + memory
  -> memory
  -> chunk[n]
  -> merge
  -> finalize

chunked + scan
  -> chunk[n]
  -> scan
  -> finalize
```

具体项目可以使用不同名称，但必须明确 work item 的 `kind`、顺序、输入引用、结果引用和失败策略。`finalize` 只能在必要 work item 完成后写入终态。

## 运行时字段

异步 Job 的快照原则由 [`async-job.md`](async-job.md) 负责。Workflow Handler 只负责为不同 `job_type` 生成会影响执行语义的 `runtime_fields`，并保证创建入口和 Worker 读取同一份已注册 handler 契约。

Handler 生成的运行时字段至少应满足：

- 来源可追踪到规范化后的 `job_params`、settings 或明确外部目标。
- 字段结构可序列化、可校验、可 hash。
- 不包含密钥、token、完整敏感载荷或大文件内容。
- Worker 不需要重新推导会改变历史 Job 语义的字段。

外部服务目标字段的取舍见 `../integrations/external-service.md`。

运行时排障脚本可以展示 `job_type`、执行计划、work item 和结果分层，但不定义 handler 契约。

## 结果边界

结果至少分两层：

| 层级 | 职责 |
| --- | --- |
| canonical result | 服务内部完整结果、审计信息、第三方写回记录、调试 artifact |
| public result | 对调用方公开的稳定结果，可为 `null` |

大文本、大 JSON 或可下载产物应写入对象存储或等价存储，JobView 中只返回引用、hash、大小和类型。不要把大产物默认塞进数据库响应。

## 副作用钩子

handler 可以声明终态后的副作用钩子，但本文件只负责说明某个 `job_type` 是否存在钩子以及钩子由哪个 handler 执行。

对外写入、callback 发送、幂等键、审计摘要、失败分类、恢复路径和生产 opt-in 统一由 `../integrations/external-service.md` 负责。Job 创建阶段不得执行这些终态副作用。
