---
description: Taskiq 执行器接入通用异步 Job 规则
---

# Taskiq 执行器规则

本规则只说明 Taskiq 如何接入 `../async-job.md` 定义的通用 Job 生命周期。Taskiq broker、result backend、worker 事件和 scheduler 只能作为过程旁证，不反向定义 Job 状态。

## 接入边界

适用场景：

- 项目选择 Taskiq 作为后台任务执行器。
- 需要 Taskiq worker、broker、middleware、schedule source 或 task labels。
- 需要把通用 Job 的消息标识映射到 Taskiq task message。

不负责：

- 定义 Job 状态机、终态幂等或恢复扫描语义。
- 定义 `job_type` handler、执行计划和结果分层。
- 定义 FastAPI route、Typer 排障命令或部署平台入口。

## 标识映射

创建 Job 时应预生成消息标识或 Taskiq task id 等价字段，并写入 Job 记录。投递 Taskiq task 时携带该标识，Worker 领取后必须校验消息标识与 Job 记录一致。

Taskiq 的 task message 只表示执行器消息，不表示业务终态。业务状态必须读取 Job 持久化记录。

## Broker 与 Result Backend

Taskiq broker 只负责消息投递，不负责业务状态权威。

如果项目启用 Taskiq result backend，它只作为执行器旁证或调试信息，不替代 Job 表、状态迁移事件或审计记录。公开查询接口不得直接暴露 result backend 作为业务结果事实源。

## Worker 与 Scheduler

Taskiq Worker 只执行已入库 Job，不在 task 内创建业务 Job。Worker 必须通过 CAS 状态转移从 `queued` 领取到 `running`，并在终态写入前检查终态幂等守卫。

如果使用 Taskiq scheduler 或等价定时机制执行恢复扫描、callback 重试或补偿任务，生产环境必须明确单实例、分布式锁或幂等并发策略。scheduler 不得绕过通用恢复规则直接修改终态。

## 超时与并发

Taskiq 项目必须把执行器超时、外部调用 timeout 和 stale running 扫描阈值映射到通用超时链路：

- SDK / 外部调用 timeout 是业务调用主截断。
- 执行器协作式取消或 middleware timeout 是软边界。
- 进程级终止、平台杀进程或 worker 超时是硬边界。
- stale running 扫描阈值必须晚于硬边界。

Worker 并发和实例数只表示执行容量。`MAX_ACTIVE_JOBS` 或等价接单上限仍由 Job 系统维护，不由 Taskiq worker 并发隐式替代。

## 恢复与重投递

Taskiq 消息可能重复投递、延迟投递或在 Worker 崩溃后重新执行。Worker 必须以 Job 记录为准，通过消息标识校验、CAS 状态转移和终态保护保证幂等。

补偿投递只处理已入库但未确认发布的 Job。补偿任务不得从 broker 或 result backend 状态反向推断业务状态。
