---
description: 后端异步 Job 生命周期、状态权威、投递、恢复与运行时快照规则
---

# 异步 Job 通用规则

本规则定义异步 Job 的技术无关契约。它适用于需要任务创建、状态查询、后台执行、结果恢复、callback 或长链路排障的后端服务，不绑定 FastAPI、Celery、Taskiq、Typer 或具体部署平台。

执行器专项规则只能说明如何把本规则映射到具体技术；不得重新定义状态机、状态权威、恢复语义或终态幂等。对调用方可见的 HTTP envelope、错误码、异常转换、Job/Callback 骨架和日志字段见 `../contracts/service-contract.md`。多 `job_type` handler 细节见 [`workflow-handler.md`](workflow-handler.md)，外部 client 和对外写入副作用见 `../integrations/external-service.md`，部署形态和迁移执行见 `../deployment/service-deployment.md`。

运行时排障脚本只展示本规则定义的状态语义，不重新定义状态机。

## 选择原则

优先同步接口。只有满足以下信号时才引入异步 Job：

- 请求耗时不可控或调用方不应等待。
- 需要任务 id、状态查询、结果恢复或 callback。
- 需要后台排队、并发控制、重试或失败恢复。
- 批量规模会导致同步接口超时或部分失败难以表达。

复杂 workflow 不是默认起点。只有子任务可并行、有明确 finalize、需要步骤状态，且团队能维护执行计划和恢复路径时才引入。

当一个 Job 服务需要支持多个 `job_type` 或可插拔执行器时，加载 [`workflow-handler.md`](workflow-handler.md)，不要把业务分支硬编码在创建入口或执行器 task 中。

## 接口契约

异步 Job 至少提供：

- 创建任务入口，成功返回可查询的 `job_id`。
- 查询状态和结果的入口。
- 可选 callback 只作为补充通知，不替代轮询。
- 可选 `client_request_id` 用于请求级幂等。

HTTP API、CLI 或内部调用可以有不同入口形式，但公开字段语义必须稳定。

当 Job 通过 HTTP 暴露时，创建响应、查询响应和错误响应必须套用 `../contracts/service-contract.md` 定义的服务 envelope。Job 查询接口查询成功时即使 Job 自身为 `failed`，HTTP 层也应表达查询成功，失败原因进入 Job `error`。

状态字段必须稳定：

```text
queued -> running -> succeeded
queued -> running -> failed
```

`succeeded` 和 `failed` 是不可变终态。消费层必须实现终态幂等守卫，防止消息重投递、重复扫描或手动补偿覆盖终态。

## 生命周期分层

Job 生命周期至少分为四层，不要把所有运行细节都塞进公开 `status`：

| 层级 | 作用 | 示例 |
| --- | --- | --- |
| 公开状态 | 调用方判断任务是否完成 | `queued`、`running`、`succeeded`、`failed` |
| 进度阶段 | 说明正在做什么，不作为终态判断 | `fetching_input`、`calling_model`、`writing_result` |
| 生命周期事件 | 排障、审计、恢复和 timeline 的事实来源 | `job.created`、`job.started`、`job.failed` |
| 副作用状态 | callback、第三方写回或对象存储交付状态 | `pending`、`delivered`、`retrying`、`failed` |

公开状态必须少而稳定；新增处理阶段或执行器旁证时，优先扩展进度阶段、事件或诊断字段，不扩展公开状态机。

生命周期事件至少覆盖：

- `job.created`：Job 持久化记录创建完成。
- `job.publish_requested`：已生成消息标识，准备投递执行器。
- `job.published`：执行器消息投递确认完成。
- `job.started`：Worker 通过 CAS 从 `queued` 领取到 `running`。
- `job.progressed`：进度阶段、work item 或摘要发生变化。
- `job.succeeded`：成功终态写入完成。
- `job.failed`：失败终态写入完成。
- `job.recovered`：恢复扫描执行了补偿或收敛动作。
- `callback.scheduled`：终态 callback 或写回副作用已排队。
- `callback.delivered`：callback 或写回确认成功。
- `callback.failed`：callback 或写回失败并记录可恢复信息。

事件记录应包含事件名、Job 标识、状态迁移、时间、触发来源、错误分类和必要摘要。Typer `timeline`、运行时排障脚本和审计视图应读取事件或等价持久化事实，不从普通日志里临时反推生命周期。

## 状态权威

持久化 Job 记录是状态权威。队列、执行器 result backend、日志、trace、Pod 状态和本地缓存只能作为过程旁证。

排障脚本、日志、trace、运行平台和队列信息与 Job 状态冲突时，应报告状态不一致，不应覆盖状态权威。

创建 Job 必须遵守可靠投递流程。推荐顺序：

1. 在持久化存储写入 `queued` 任务。
2. 预生成消息标识或执行器 task id。
3. 将消息标识写入 Job 记录并提交。
4. 投递执行器任务。
5. 投递成功后回写发布确认字段。

如果创建入口在提交后、投递前崩溃，必须能通过 `queued + task_id exists + published_at is null` 或等价条件补偿投递。如果投递成功但消息重复，Worker 必须校验消息 id 与 Job 记录一致，并通过 CAS 状态转移防止双执行。

Job 创建阶段只负责校验、入库和投递。callback 发送和第三方写入只能发生在后续阶段；对外副作用协议见 `../integrations/external-service.md`。

## 并发与积压

异步 Job 应显式控制并发和积压：

- 单 worker 并发。
- Worker 实例数或进程数。
- queued + running 积压上限。
- 队列满时的拒绝策略。

积压上限是业务接单保护，不等价于严格分布式锁。需要强一致容量控制时，应引入数据库锁、CAS 更新或专门队列治理。

## 超时链路

不要只依赖外部 SDK timeout。完整链路应至少区分：

- 业务调用主截断。
- 执行器软超时或协作式取消。
- 执行器硬超时或进程级终止。
- stale running 扫描阈值。

超时配置必须单调递增，并保留 buffer。非法超时配置必须启动失败。

## 恢复机制

必须实现至少一层恢复：

- Worker 启动扫描孤儿 queued 和僵死 running。
- 长时间运行进程推荐增加定期扫描。
- 生产环境如使用 scheduler，必须明确单实例或分布式锁边界。

扫描规则必须幂等。恢复动作不得覆盖终态任务。

恢复扫描至少区分：

- 未分配消息标识的 orphan queued。
- 已分配消息标识但未确认发布的 queued。
- 超过 stale 阈值的 running。
- 到期未送达的 callback。
- 已过期且生命周期收敛的终态 Job。

多 Worker 并发恢复时，应使用数据库锁、CAS 更新或 `skip locked` 等价机制避免重复补偿。

## 运行时快照

异步 Job 的执行语义应在创建时固定。任务执行依赖的规范化入参、执行模式、模型、Prompt、外部目标、输出目标等应进入运行时快照或等价结构。

运行时快照必须可校验：

- 保存 Job 类型或执行模式。
- 保存规范化入参引用和 hash；规范化入参来自服务契约和 handler schema 的共同约束。
- 保存会影响历史执行语义的运行时字段。
- 保存输出目标。
- Worker 读取时校验 hash、类型和引用结构。

不要让长期排队的历史 Job 在执行时被当前 settings 的语义变化意外影响。多个 `job_type` 的 handler 如何生成 `runtime_fields`，由 [`workflow-handler.md`](workflow-handler.md) 负责补充。

## 进程边界

创建入口、Worker、scheduler 和恢复扫描器应有清晰进程或 Deployment 边界。创建入口和 Worker 可以水平扩展；scheduler 如启用必须有单实例或分布式互斥机制。

本节只规定 Job 系统需要哪些进程边界，不规定具体 Docker、Compose、K8s 或迁移执行方式。部署形态、健康检查和新环境迁移执行由 `../deployment/service-deployment.md` 负责。
