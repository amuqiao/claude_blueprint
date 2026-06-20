---
description: 后端数据库、持久化、Repository、迁移与 Job 状态事实源规则
---

# 数据库与持久化规则

本规则定义后端服务的数据库配置、连接生命周期、Repository 边界、迁移和 Job 持久化事实源。它适用于 FastAPI API、Worker、scheduler 和 Typer CLI 共享同一数据库模型的项目。

本文只规定数据库事实源和持久化边界，不定义 HTTP envelope、Job 状态机、AI 输出 schema 或部署平台流程。对外输入输出读取 `../contracts/service-contract.md`，Job 生命周期读取 `../jobs/async-job.md`，配置注入读取 `../fastapi/configuration/settings.md` 和 `../deployment/service-deployment.md`。

## 数据库配置

数据库配置必须独立成 `DatabaseSettings` 或等价子对象，不得混入 AI、HTTP、Job 或业务参数配置。

`DatabaseSettings` 至少明确：

- 主连接 URL 或 DSN。
- 连接池大小、溢出、获取连接超时和回收策略。
- 是否启用 SQL echo 或慢查询日志。
- 迁移使用的连接来源。
- 读写分离、只读副本或多库边界；未明确支持时不得在代码中隐式切换。
- 敏感字段序列化保护，数据库 URL、密码和 token 不进入日志、错误和 settings dump。

数据库配置必须在进程启动时校验。API、Worker、scheduler 和 Typer CLI 使用同一配置语义；不要让 CLI 读取一套临时数据库变量，也不要让 Worker 通过 `os.environ` 绕过 Settings。

## 连接与 Session 生命周期

数据库 engine、连接池和 session 生命周期必须集中管理。

FastAPI API 进程应通过 dependency 或应用级生命周期管理 session；Worker 和 Typer CLI 应通过同一套 session factory 或 Unit of Work 初始化。不要在 route、handler、repository 或命令函数里临时创建 engine。

连接生命周期必须满足：

- engine 在进程启动时初始化或首次使用时集中初始化。
- session scope 与请求、Job 执行阶段或 CLI 命令边界对齐。
- 事务提交、回滚和关闭由 Service 或 Unit of Work 管理。
- Repository 不持有跨请求、跨 Job 或跨命令的长生命周期 session。
- 连接失败必须快速暴露，不得返回空结果或假健康状态。

## Repository 与 Unit of Work

Repository 是数据库访问边界，只负责读写和查询表达，不负责业务判断、HTTP 响应、执行器投递或外部服务调用。

事务边界应位于 Service 或明确的 Unit of Work 层：

```text
API / Worker / Typer
  -> Service / Use Case
  -> Unit of Work
  -> Repository
  -> DB
```

禁止：

- API route 直接拼 SQL 或返回 ORM 对象。
- Worker task 跳过 Service，直接改 Job 终态。
- Typer command 直接拼 SQL 执行业务修复。
- Repository 调用外部 HTTP client、AI provider、broker publisher 或 callback sender。

## Job 持久化事实源

当服务启用异步 Job，Job 表或等价持久化记录是状态权威。执行器 task id、broker 队列、result backend、日志和 trace 只能作为旁证。

Job 持久化记录至少应能表达：

| 字段类别 | 说明 |
| --- | --- |
| 标识 | `job_id`、`client_request_id`、`caller_id`、`job_type`、执行器消息 id |
| 状态 | `status`、进度阶段、终态时间、错误对象 |
| 输入 | 规范化 `job_params` 引用或快照、`input_hash`、`schema_version` |
| 运行时 | `runtime_fields`、模型、Prompt 版本、外部目标、输出目标 |
| 结果 | `canonical_result`、`public_result`、对象存储引用、结果 hash |
| callback | callback 目标、状态、尝试次数、下次重试时间、最后错误摘要 |
| 审计 | 创建、发布、开始、完成、恢复和副作用事件 |

大文本、大文件、大 JSON 和完整敏感载荷不得默认存入普通 Job 响应字段。需要持久化时应写入对象存储或专用 artifact 表，并在 JobView 中返回引用、hash、大小、内容类型和过期时间。

## 状态迁移与并发控制

Job 状态迁移必须使用 CAS、行锁、唯一约束或等价机制保护，不得依赖内存锁或执行器单次投递假设。

关键迁移至少包括：

- 创建 `queued` Job 和预生成消息标识在一个可靠持久化流程中完成。
- Worker 领取时使用 CAS 从 `queued` 迁移到 `running`。
- 终态写入前检查当前状态不是 `succeeded` 或 `failed`。
- 恢复扫描只补偿非终态 Job，不覆盖终态。
- callback 或第三方写回状态与 Job 终态分开记录，不反向修改 Job 业务终态。

重复消息、Worker 崩溃、恢复扫描并发和手动补偿都必须以数据库事实源为准。状态权威与旁证冲突时，排障命令应报告冲突，不应自动修正。

## Schema Version 与 Hash

持久化结构中凡是会影响执行语义或输出契约的 JSON 字段，都应记录 schema version 或等价版本信息。

至少应考虑：

- `job_params_schema_version`。
- `runtime_fields_schema_version`。
- `canonical_result_schema_version`。
- `public_result_schema_version`。
- `callback_data_schema_version`。
- 输入、runtime fields 和结果的 hash。

Worker 读取历史 Job 时必须校验类型、版本和 hash。不要让当前代码或当前 Settings 重新推导历史 Job 的模型、Prompt、输出目标或公开结果语义。

## 迁移规则

使用 Alembic 或等价迁移工具时，数据库模型、迁移文件和部署流程必须同步维护。

迁移规则：

- 新环境首次部署必须执行迁移。
- 迁移失败必须阻止 API、Worker、scheduler 继续启动或发布。
- API、Worker、scheduler 和 Typer CLI 共享模型时，迁移必须先于依赖它的进程启动。
- 新增 Job 字段、索引、唯一约束和事件表时，必须同时补 contract tests 或迁移验证。
- 不得让业务代码在启动时静默创建或修补生产表结构。

## 索引与约束

Job 服务至少评估以下索引和约束：

| 对象 | 建议约束或索引 | 用途 |
| --- | --- | --- |
| Job id | 唯一约束 | 查询和状态权威 |
| `caller_id + client_request_id + job_type` | 唯一或冲突检测 | 请求幂等 |
| `status + created_at` | 普通索引 | 积压、列表、恢复扫描 |
| `status + updated_at` | 普通索引 | stale running 扫描 |
| `published_at is null` | 条件索引或等价查询优化 | 未确认发布补偿 |
| callback 状态与下次重试时间 | 普通索引 | callback 恢复扫描 |
| 事件 `job_id + created_at` | 普通索引 | Typer timeline 和审计 |

索引设计应服务查询和恢复路径，不为了“可能有用”提前堆叠无消费方索引。

## Typer 与排障

Typer 运行时命令读取数据库事实源时，必须通过 query service、Repository 或只读查询模块，不直接散落 SQL。默认命令只读；重试、补偿、callback 重放和 DB 修改必须进入独立修复入口或 runbook。

CLI JSON 输出字段必须引用服务契约、Job 规则和本规则的事实源。数据库不可达、证据缺失或状态权威与旁证冲突时，命令必须返回明确失败原因和稳定退出码。

## 验收要求

数据库与持久化规则至少通过以下检查落地：

- Settings 测试覆盖 `DatabaseSettings` 必填、敏感字段保护和非法配置失败。
- 迁移验证覆盖新环境建表、索引和约束。
- Repository 或 Unit of Work 测试覆盖事务提交、回滚和连接关闭。
- Job 状态迁移测试覆盖 CAS 领取、重复消息、终态幂等和恢复扫描。
- Typer 只读查询测试覆盖对象不存在、数据库不可达和证据冲突。
