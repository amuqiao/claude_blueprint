# 成熟模式索引

这是一份模式地图，不是强制规则。只有场景确实需要时才采用对应模式。

## 需求信号到成熟模式

先识别用户真正要保证的结果，再匹配模式。用户通常不会直接说出模式名，而是用现象、担忧或实现细节描述问题。

| 需求信号 | 真实工程问题 | 优先考虑的成熟模式 |
|---|---|---|
| “任务存了但队列消息不能丢” | 数据库状态和消息发布意图要一致 | Transactional outbox |
| “队列可能重复投递，不能重复扣费/执行” | 消费者要承受重复消息 | Idempotent consumer、幂等键、唯一约束 |
| “worker 崩了任务要继续” | 长任务领取状态必须可恢复 | Lease + heartbeat、sweeper / reconciler |
| “失败任务不能静默消失” | 失败需要可观察、可重放、可人工处理 | Dead letter queue、failed jobs table、runbook-visible states |
| “外部服务偶尔失败/限流” | 瞬时失败需要有节制地重试 | Exponential backoff + jitter、retry budget |
| “多服务多步骤不能部分成功后烂尾” | 跨边界流程无法用单一事务回滚 | Saga / process manager、补偿动作 |
| “重复点击/重复请求不能创建两次” | 客户端重试和并发提交要幂等 | Idempotency key + unique constraint |
| “余额、积分、用量、成本不能算错” | 关键事实需要可审计、不可丢 | Append-only ledger、materialized summary |
| “查询要快但写入事实不能乱” | 写模型和读模型有不同形态 | Read model projection、materialized summary |
| “异步完成后通知外部系统” | 回调要防伪造、可重试、可追踪 | Signed webhook callback、outbox、delivery log |
| “权限判断散落各处容易漏” | 认证授权边界需要集中治理 | Central auth boundary、capability allowlist |
| “筛选、分页、tab 刷新后要保留” | 可分享 UI 状态应有稳定来源 | URL as state |

如果一个需求同时命中多个信号，组合模式，而不是强行找一个“大一统”模式。例如可靠任务系统常见组合是：Transactional outbox + Idempotent consumer + Lease + DLQ + Reconciler + Structured logs。

## 可靠性与异步流程

- Transactional outbox：在同一个数据库事务里写业务状态和待发布消息意图；后台 publisher 负责投递。适用于“DB commit 成功但消息发布不能丢”的场景。
- Idempotent consumer：消费者必须能承受重复消息。通常和 at-least-once delivery 配套。
- Lease + heartbeat：worker 领取任务时持有可过期租约，长任务崩溃后可恢复。
- Dead letter queue：重试耗尽后保留失败任务，便于排查和人工修复。
- Exponential backoff + jitter：用于网络、provider、限流等瞬时失败。
- Sweeper / reconciler：周期性修复 stuck、stale、orphaned 状态。
- Saga / process manager：用于无法分布式回滚的多步骤业务流程。

## 数据与一致性

- Optimistic concurrency / CAS：只允许从预期旧状态更新到新状态，避免并发覆盖。
- Unique constraint + idempotency key：安全处理客户端重复提交。
- Append-only ledger：用于资金、积分、用量、审计、计费等不可丢事实。
- Materialized summary：从不可变事实派生读友好的聚合结果。
- Read model projection：把写入真相源和查询视图分开。

## API 与合同

- Stable envelope：统一响应结构，包含 request id、code、message、data 等稳定字段。
- Versioned API contract：外部客户端依赖字段时，使用版本化合同。
- Capability-specific route：当操作输入/输出合同差异很大时，每个能力独立路由。
- Generic command route：当多个操作生命周期、权限、状态一致，仅类型不同，使用统一命令入口。
- Signed webhook callback：异步终态通知需要签名，防止伪造事件。

## 前端与交互状态

- Server state cache：服务端数据缓存交给 query/cache 类库管理。
- Client state machine：当 UI 流程有明确状态和转移时，用状态机建模。
- Optimistic UI with rollback：只有冲突可控且可回滚时使用。
- URL as state：筛选、分页、tab、导航等可分享状态应进入 URL。

## 安全与访问控制

- Central auth boundary：认证授权走统一边界，避免每个入口重复发明。
- Capability allowlist：显式限制 provider、model、operation 组合。
- Secret separation：密钥不进入源码、日志或可公开配置。
- Signed callbacks / webhooks：防止伪造回调和终态事件。
- Rate limit / bulkhead：隔离滥用调用方或昂贵能力。

## 运维与可观测性

- Health / readiness split：区分进程存活和依赖可用。
- Structured logs with correlation IDs：串起 request、job、attempt、外部调用。
- Saturation metrics：队列深度、活跃任务数、重试次数、延迟、失败率。
- Runbook-visible states：恢复路径应依赖持久化状态，而不是隐式内存状态。
