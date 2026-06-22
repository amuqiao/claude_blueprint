---
description: FastAPI、异步 Job、Typer 与 AI 能力服务 MVP 骨架基线
---

# AI 能力服务 MVP 骨架基线

本规则定义一个可长期演进的 AI 能力服务在 MVP 阶段必须落下的最小骨架。它不替代项目骨架、服务契约、配置、数据库、Job、AI 或部署专项规则，而是把这些规则收敛成新项目起盘时可检查的最小交付清单。

适用场景：服务以 FastAPI 暴露能力，以异步 Job 执行长任务，以 Typer 提供运行时排障或受控管理入口，并接入数据库、模型供应商和可选 callback / artifact 存储。

## 最小模块

MVP 骨架至少包含以下模块或等价职责：

| 模块 | 最小职责 | 事实源 |
| --- | --- | --- |
| `api/` | FastAPI route、依赖注入、异常 handler、OpenAPI 投影 | `project-skeleton.md`、`../fastapi/` |
| `schemas/` | `ResponseEnvelope`、`ErrorDetail`、`JobView`、`CallbackEnvelope` 和公共 schema | `../contracts/service-contract.md`、`../contracts/schema-composition.md` |
| `core/` | Settings、日志、时间工具、metrics 初始化 | `../fastapi/configuration/settings.md`、`../fastapi/observability/` |
| `db/` | engine、session、迁移、Job 状态事实源 | `../persistence/database.md` |
| `repositories/` | 数据读写、查询表达、CAS 状态迁移 | `../persistence/database.md` |
| `services/` | 用例编排、事务边界、业务判断 | `layering.md` |
| `jobs/` | Job lifecycle、publisher、recovery、registry 接入 | `../jobs/async-job.md` |
| `workflows/` | `job_type` handler、params/result schema、执行计划 | `../jobs/workflow-handler.md` |
| `integrations/ai/` | provider adapter、Prompt、结构化输出、成本摘要 | `../ai/capability-service.md` |
| `integrations/storage/` | artifact 引用、hash、权限和过期策略 | `../integrations/artifact-storage.md` |
| `integrations/callback/` | callback client、重试、幂等和环境保护 | `../integrations/external-service.md` |
| `cli/` | Typer 只读排障；如有写动作，进入独立管理入口 | `../typer/ops-cli.md`、`../typer/admin-cli.md` |
| `tests/contracts/` | envelope、schema、Job/callback、日志、metrics 和配置契约 | 本文和各专项规则 |

不得为了 MVP 省略 schema、错误码、handler registry、Job 持久化或配置校验，然后用 route、worker task 或脚本里的临时代码补齐。MVP 可以少能力，但不能少事实源边界。

## 最小真源

MVP 项目必须具备以下可执行或可检查真源：

- Settings 字段、分类、env key 映射、废弃 key 拒绝清单和允许清单。
- 统一 envelope、错误对象、JobView、CallbackEnvelope 和公共 schema。
- 错误码注册表，至少覆盖服务级错误码和项目子错误码。
- `operation_id` 或等价公开操作清单。
- `job_type` / workflow handler registry。
- `job_params`、`runtime_fields`、`canonical_result`、`public_result`、`callback_data` 的 schema version 或等价版本。
- provider adapter 配置、Prompt 版本和结构化输出契约。
- artifact 引用 schema；如暂不启用 artifact，应明确声明不启用。

文档、README 示例、OpenAPI、CLI help 和 SDK 类型只能作为这些真源的投影，不得成为第二套事实源。

## 最小接口

异步 AI 能力服务至少提供：

- `POST /jobs` 或等价创建入口。
- `GET /jobs/{job_id}` 或等价查询入口。
- `/health` 或等价健康检查。
- `/openapi.json` 或等价接口投影。
- Typer `ops health`、`ops job show`、`ops job timeline` 或等价只读排障入口。

如果项目只有同步 AI 接口，可以不启用通用异步 Job，但必须在 README 或架构说明中明确“不启用异步 Job、callback、worker 和 recovery”，并保留同步接口的 envelope、错误码、日志和配置校验。

## 最小进程

启用异步 Job 时，MVP 至少明确以下进程边界：

- API 进程：鉴权、请求校验、Job 入库、投递和查询。
- Worker 进程：通过 CAS 领取 Job、执行 handler、写入终态。
- Recovery 或 scheduler：恢复孤儿 queued、僵死 running 和 callback 重试；如果暂不单独部署，必须说明由哪个进程在何时触发。
- Typer CLI：读取同一 Settings、Repository、handler registry 和 Job 状态事实源。

API、Worker、scheduler 和 Typer CLI 必须共享同一配置语义和数据库模型。任何一个进程配置校验失败，都不得开始监听、接单、执行副作用或返回假健康。

## 最小验证

MVP 骨架不能只靠人工阅读规则。至少提供以下验证入口：

- Settings 初始化、敏感字段保护、未知 / 废弃 env key 拒绝。
- OpenAPI 或 schema 快照。
- 全局异常转换：校验错误、业务错误、未知错误。
- 错误码注册表与接口错误示例一致性。
- `job_type` registry 唯一性和 handler 契约校验。
- Job 创建、查询运行中、成功终态、失败终态和 CAS 终态幂等。
- runtime snapshot hash、schema version 和历史 Job 读取校验。
- AI provider adapter 成功、超时、限流、输出非法和 schema 校验失败。
- public result 与 callback data 从同一 canonical result 派生。
- Typer JSON 输出和退出码。
- 结构化日志字段和最小 metrics 字段。
- artifact 引用、hash、权限和过期策略；未启用时验证“不启用”声明。

如果某项能力暂不启用，必须在 README、架构说明或能力清单中明确写出“不启用”和原因，不保留空实现、默认 fallback 或无法验证的半成品入口。

## MVP 完成判断

一个 FastAPI + Job + Typer + AI 能力服务只有在满足以下条件时，才能视为骨架稳定：

- 新增同步接口只需要新增 request / data schema、route、service、必要 repository 和 contract tests。
- 新增 `job_type` 只需要新增 params/result/callback schema、handler、registry 注册、必要 integration 和 contract tests。
- 切换 Celery / Taskiq 执行器时，不需要重写公开状态机、Job 表、callback envelope 或 handler result schema。
- 调用方能通过 `request_id`、`trace_id`、`job_id`、`job_type`、错误码、日志事件和 Typer timeline 定位完整链路。
- 失败会以稳定错误码、终态或启动失败暴露，不依赖 silent fallback、空结果兼容或隐式降级。
