---
description: 复杂 Job、执行计划、Work Item 与 Celery Canvas / Taskiq 执行器编排边界规则
---

# 复杂 Job 执行计划规则

本规则定义当一个 Job 内部需要多个步骤、分片、并行处理、merge 或 finalize 时如何建模。Job 仍是调用方可见的基本处理单元；复杂度下沉到执行计划、work item 和生命周期事件，不把执行器的编排能力暴露为公开 Job 状态机。

## 基本原则

公开层保持：

```text
one client request
  -> one Job
  -> one job_type
  -> one public status
  -> one canonical result
  -> one public result / callback data projection
```

内部可以拆成多个 work item：

```text
Job
  -> execution_plan
  -> work_item[n]
  -> merge
  -> finalize
```

不得把 Celery group / chord、Taskiq schedule、broker message 或 worker task 直接暴露为调用方需要理解的业务任务。调用方只依赖 JobView、callback 和 artifact 引用。

## 引入复杂执行计划的条件

只有满足以下条件时才引入复杂执行计划：

- 输入可自然分片，且分片之间可以并行或有明确顺序。
- 单 Job 执行时间、内存、模型上下文或外部限流需要拆分。
- 需要 partial progress、resume、merge 或 finalize。
- 团队能维护 work item 状态、恢复和幂等。

不要因为执行器支持 canvas、group、scheduler 或 result graph，就默认把简单 Job 拆成复杂 workflow。

## 执行计划事实源

复杂 Job 的执行计划必须持久化或可从 runtime snapshot 稳定重建。计划至少包含：

- `plan_id` 和 schema version。
- `job_id`、`job_type`。
- work item 列表和顺序 / 依赖关系。
- 每个 work item 的 `kind`、输入引用、输出引用、重试策略、timeout 和资源预算。
- merge / finalize 条件。
- 失败策略：任一失败即 Job failed、允许部分失败、或进入人工处理。
- artifact 和 callback 交付策略。

Worker 不得根据当前 Settings、当前代码默认值或执行器 result graph 重新推导历史 Job 的执行计划。

## Work Item 状态

Work item 状态是 Job 内部状态，不等于公开 Job 状态。建议最小状态：

```text
pending -> running -> succeeded
pending -> running -> failed
pending -> skipped
```

公开 Job 状态仍保持 `queued/running/succeeded/failed`。Work item 状态变化应写入生命周期事件或等价持久化事实，供 Typer timeline、recovery 和审计使用。

## Finalize 规则

`finalize` 是唯一允许把分片结果收敛为 Job 终态的阶段。Finalize 必须：

- 校验所有必要 work item 已完成或按失败策略收敛。
- 从 work item 结果和 artifact 引用生成 canonical result。
- 从 canonical result 派生 public result 和 callback data。
- 使用 CAS 或等价机制写入不可变终态。
- 记录 `job.succeeded` 或 `job.failed` 生命周期事件。

不得让多个分片直接竞争写 Job 终态。不得让 callback 或第三方写回在 finalize 前发生。

## 执行器编排边界

Celery Canvas、Taskiq scheduler、Taskiq labels、broker 延迟投递、result backend 和执行器依赖注入都只能作为执行器实现手段。项目可以使用这些能力提升执行效率，但不能让它们成为业务状态事实源。

执行器编排必须映射到项目自己的执行计划和 work item：

- Celery `chain` 可映射为顺序 work item。
- Celery `group` 可映射为并行 work item。
- Celery `chord` 可映射为并行 work item + finalize。
- Celery `chunks` 可映射为分片 work item。
- Taskiq scheduler 可用于定时扫描、补偿或延迟触发，但生产环境必须有单实例或互斥策略。
- Taskiq task labels 可承载 timeout、schedule 或诊断标签，但不替代 Job runtime snapshot。
- Taskiq dependencies / state 可用于 Worker 依赖初始化，但不替代 Settings、Repository 或 Unit of Work。

如果执行器 result graph 与数据库 work item 状态冲突，排障输出必须报告冲突，以数据库事实源为准。

## 恢复与幂等

复杂执行计划必须支持恢复：

- pending work item 可重新投递。
- running 超过 stale 阈值的 work item 可按策略失败或重投。
- succeeded work item 不重复执行，除非 handler 明确支持幂等重算。
- finalize 可重复触发，但只能有一次成功写入终态。
- 终态 Job 不被 work item 重试或执行器重复消息覆盖。

每个 work item 的外部副作用必须有幂等键。没有幂等保护的副作用不得放在可重复执行的 work item 中。

## 验收要求

引入复杂执行计划时至少验证：

- 执行计划可序列化、可校验、可 hash。
- work item 状态迁移和 Job 公开状态不混用。
- 并行分片成功后只有 finalize 写入终态。
- 单个分片失败、重复消息、Worker 崩溃和 finalize 重复触发都有测试。
- Typer timeline 能展示计划、work item、merge/finalize 和证据缺失。
- 执行器 result backend 不会替代 Job / work item 持久化事实源。
