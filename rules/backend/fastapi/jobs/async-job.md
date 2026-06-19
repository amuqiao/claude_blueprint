---
description: FastAPI 异步 Job、Celery、状态机、幂等与恢复规则
---

# FastAPI 异步 Job 规则

本规则适用于 FastAPI + Celery + PostgreSQL + Redis 的异步 Job 系统，尤其是 10 秒到 30 分钟的 AI 工作负载。亚秒级任务、纯同步接口和流式/SSE 响应不默认使用本规则。

异步 Job 规则负责 Job 生命周期、状态权威、可靠投递、并发积压、超时链路、恢复和运行时快照。多 `job_type` handler 细节见 [`workflow-handler.md`](workflow-handler.md)，外部 client 和对外写入副作用见 `../../integrations/external-service.md`，部署形态和迁移执行见 `../../deployment/service-deployment.md`。

## 选择原则

优先同步接口。只有满足以下信号时才引入异步 Job：

- 请求耗时不可控或调用方不应等待。
- 需要 task_id、状态查询、结果恢复或 callback。
- 需要后台排队、并发控制、重试或失败恢复。
- 批量规模会导致同步接口超时或部分失败难以表达。

Canvas / workflow 不是默认起点。只有子任务可并行、有明确 finalize、需要步骤状态，且团队能维护 Celery Canvas 时才引入。

当一个 Job 服务需要支持多个 `job_type` 或可插拔执行器时，加载 [`workflow-handler.md`](workflow-handler.md)，不要把业务分支硬编码在 API route 或 Celery task 中。

## 接口契约

异步 Job 至少提供：

- `POST /jobs` 创建任务，成功返回 `202 Accepted`。
- `GET /jobs/{job_id}` 查询状态和结果。
- 可选 callback 只作为补充通知，不替代轮询。
- 可选 `client_request_id` 用于请求级幂等。

状态字段必须稳定：

```text
queued -> running -> succeeded
queued -> running -> failed
```

`succeeded` 和 `failed` 是不可变终态。消费层必须实现终态幂等守卫，防止消息重投递覆盖终态。

## 状态权威

DB 是状态权威，Redis 只是消息投递通道。不要依赖 Celery result backend 表达业务状态。

创建 Job 必须遵守可靠投递流程。推荐顺序：

1. 在 DB 写入 `queued` 任务。
2. 预生成 `celery_task_id` 或等价消息标识。
3. 将消息标识写入 DB 并提交。
4. 投递 Celery task。
5. 投递成功后回写 `celery_published_at` 或等价发布确认字段。

如果 API 在提交后、投递前崩溃，必须能通过 `queued + task_id exists + published_at is null` 补偿投递。如果投递成功但消息重复，Worker 必须校验消息 task id 与 DB task id 一致，并通过 CAS 状态转移防止双执行。

Job 创建阶段只负责校验、入库和投递。callback 发送和第三方写入只能发生在后续阶段；对外副作用协议见 `../../integrations/external-service.md`。

## 并发与积压

AI 任务应显式控制并发和积压：

- `CELERY_WORKER_CONCURRENCY` 控制单 worker 并发。
- Worker Pod 数控制水平扩展容量。
- `MAX_ACTIVE_JOBS` 控制 queued + running 积压上限。
- 队列满应返回 503，而不是无限接单。

`MAX_ACTIVE_JOBS` 是软限制，不等价于严格分布式锁。需要强一致容量控制时，应引入数据库锁或专门队列治理。

## 超时链路

不要只依赖 SDK timeout。完整链路应至少区分：

- 模型调用主截断。
- Celery soft time limit。
- Celery hard time limit。
- stale running 扫描阈值。

超时配置必须单调递增，并保留 buffer。非法超时配置必须启动失败。

## 恢复机制

必须实现至少一层恢复：

- Worker 启动扫描孤儿 queued 和僵死 running。
- 长时间运行进程推荐增加定期扫描。
- 生产环境可使用单实例 Celery Beat，但不得与普通 Worker Deployment 混合。

扫描规则必须幂等。恢复动作不得覆盖终态任务。

恢复扫描至少区分：

- 未分配 task id 的 orphan queued。
- 已分配 task id 但未确认发布的 queued。
- 超过 stale 阈值的 running。
- 到期未送达的 callback。
- 已过期且生命周期收敛的终态 Job。

多 Worker 并发恢复时，应使用数据库锁、CAS 更新或 `skip locked` 避免重复补偿。

## 运行时快照

异步 Job 的执行语义应在创建时固定。任务执行依赖的规范化入参、执行模式、模型、Prompt、外部目标、输出目标等应进入运行时快照或等价结构。

运行时快照必须可校验：

- 保存 Job 类型或执行模式。
- 保存规范化入参引用和 hash。
- 保存会影响历史执行语义的运行时字段。
- 保存输出目标。
- Worker 读取时校验 hash、类型和引用结构。

不要让长期排队的历史 Job 在执行时被当前 settings 的语义变化意外影响。多个 `job_type` 的 handler 如何生成 `runtime_fields`，由 [`workflow-handler.md`](workflow-handler.md) 负责补充。

## 进程边界

API、Worker、Beat 应有清晰进程或 Deployment 边界。API 和 Worker 可以水平扩展；Beat 如启用必须单实例。

本节只规定 Job 系统需要哪些进程边界，不规定具体 Docker、Compose、K8s 或迁移执行方式。部署形态、健康检查和新环境迁移执行由 `../../deployment/service-deployment.md` 负责。
