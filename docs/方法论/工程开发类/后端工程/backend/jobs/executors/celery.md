---
description: Celery 执行器接入通用异步 Job 规则
---

# Celery 执行器规则

本规则只说明 Celery 如何接入 `../async-job.md` 定义的通用 Job 生命周期。Celery 不是 Job 状态事实源，Celery result backend、broker、worker 事件和日志只能作为过程旁证。

## 接入边界

适用场景：

- 项目选择 Celery 作为后台任务执行器。
- 需要 broker、worker concurrency、soft / hard time limit 或 Celery Beat。
- 需要把通用 Job 的消息标识映射为 Celery task id。

不负责：

- 定义 Job 状态机、终态幂等或恢复扫描语义。
- 定义 `job_type` handler、执行计划和结果分层。
- 定义 FastAPI route、Typer 排障命令或部署平台入口。

## 标识映射

创建 Job 时应预生成 `celery_task_id` 或等价字段，并写入 Job 记录。投递 Celery task 时使用该 id，Worker 领取后必须校验消息 task id 与 Job 记录一致。

Celery task id 只表示执行器消息，不表示业务终态。业务状态必须读取 Job 持久化记录。

## Broker 与 Result Backend

Redis、RabbitMQ 或其他 broker 只负责消息投递，不负责业务状态权威。

不要依赖 Celery result backend 表达业务状态。result backend 可用于调试或执行器旁证，但不能替代 Job 表、状态迁移事件或审计记录。

## Worker 与 Beat

Celery Worker 只执行已入库 Job，不在 task 内创建业务 Job。Worker 必须通过 CAS 状态转移从 `queued` 领取到 `running`，并在终态写入前检查终态幂等守卫。

Celery Beat 如用于恢复扫描、callback 重试或定期补偿，生产环境必须单实例运行，或使用明确的分布式互斥机制。Beat 不得与普通 Worker Deployment 混合成无法判断实例数的进程形态。

## 超时与并发

Celery 配置必须映射到通用超时链路：

- SDK / 外部调用 timeout 是业务调用主截断。
- Celery soft time limit 是协作式中断边界。
- Celery hard time limit 是进程级终止边界。
- stale running 扫描阈值必须晚于 hard time limit。

`CELERY_WORKER_CONCURRENCY` 控制单 worker 并发，Worker Pod 或进程数控制水平扩展容量。`MAX_ACTIVE_JOBS` 或等价接单上限仍由 Job 系统维护，不由 Celery concurrency 隐式替代。

## 恢复与重投递

Celery 消息可能重复投递或在 Worker 崩溃后重新执行。Worker 必须以 Job 记录为准，通过消息 id 校验、CAS 状态转移和终态保护保证幂等。

补偿投递只处理已入库但未确认发布的 Job。补偿任务不得从 Celery 队列状态反向推断业务状态。
