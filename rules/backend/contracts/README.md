---
description: 后端服务契约规则索引
---

# 后端服务契约规则

本目录维护后端服务对调用方、异步任务、外部回调和排障系统暴露的稳定契约。契约规则回答“调用方看到什么、字段如何说明、schema 如何复用、错误如何判断、日志如何串联、如何新增接口或 Job 而不破坏一致性”。

## 子树边界

| 文件 | 负责 | 不负责 |
| --- | --- | --- |
| `service-contract.md` | HTTP envelope、输入输出骨架、错误码分层、异常转换、Job/Callback 对外契约、时间格式、结构化日志字段和接入验收 | FastAPI API、Celery / Taskiq API、具体业务字段、具体供应商协议 |
| `schema-composition.md` | `ResponseEnvelope[T]`、`ErrorDetail`、`JobView[TResult]`、`CallbackEnvelope[TData]` 与业务 schema 的组合复用 | 重新定义 envelope、错误码、Job 状态机、具体业务字段 |
| `registry-source.md` | 错误码、公开操作、schema version 和 `job_type` registry 的可检查事实源 | 具体业务字段、执行器 API、OpenAPI 样式 |
| `api-operation-template.md` | 新接口文档模板、字段说明、必选/可选、类型、约束、`null` / 省略语义、示例、错误码和验收清单 | 服务级 envelope、Job 状态机、Callback 顶层字段事实源 |

服务契约是上层事实源。FastAPI、Job、Workflow Handler、外部集成、AI 能力和可观测规则只能说明如何接入本契约，不得重新定义另一套响应 envelope、错误结构、时间格式或日志主字段。

## 加载顺序

新建后端服务时，应在确定分层后尽早加载服务契约：

1. `../architecture/layering.md`：确定服务职责和分层。
2. `service-contract.md`：确定调用方可见的输入、输出、错误、日志、时间和 Job 扩展规则。
3. `schema-composition.md`：确定公共 envelope、错误、JobView、CallbackEnvelope 和业务 schema 如何组合。
4. `registry-source.md`：当项目需要错误码、operation、schema version 或 `job_type` registry 时确定可检查事实源。
5. `api-operation-template.md`：新增接口时确定字段表、示例、错误码和验收项。
6. `../entrypoints/project-entrypoints.md`：确定本地开发和验证入口。
7. `../jobs/`、`../fastapi/`、`../integrations/`、`../ai/`：按项目能力接入契约。

如果项目已经存在接口或 Job，再引入本规则时必须先梳理兼容策略。不要在没有版本计划的情况下直接破坏已发布响应结构。
