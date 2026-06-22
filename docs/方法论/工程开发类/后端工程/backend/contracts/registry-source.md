---
description: 后端错误码、操作、Schema 与 Job Type 注册表事实源规则
---

# 注册表事实源规则

本规则定义后端服务中错误码、公开操作、schema version 和 `job_type` 的注册表边界。它补充 `service-contract.md` 和 `schema-composition.md`，避免接口、Job、OpenAPI、README 示例和 Typer help 各自维护一套事实。

## 适用边界

满足任一条件时，项目必须建立注册表或等价可检查真源：

- 有超过一个公开 HTTP 操作。
- 有异步 Job 或多个 `job_type`。
- 有 callback、第三方写回或 Typer CLI 投影。
- 错误码、schema version 或 OpenAPI 需要长期兼容演进。

注册表可以是 Python 类型定义、枚举、结构化配置、生成脚本输入或测试 fixture，但必须能被测试或生成检查消费。不要只在 Markdown 表格里维护注册表。

## 错误码注册表

错误码注册表至少记录：

| 字段 | 规则 |
| --- | --- |
| `code` | 服务级错误码，必须来自 `service-contract.md` 的基线或项目扩展。 |
| `sub_code` | 项目子错误码，命名空间稳定。 |
| `http_status` | HTTP 接口使用的真实状态码；Job failed 场景可标注为终态错误。 |
| `retryable` | 调用方默认重试语义。 |
| `message` | 短消息模板，不作为机器判断依据。 |
| `details_schema` | 对外允许暴露的 details 字段。 |
| `log_fields` | 日志必须记录的排障字段。 |

新增错误码必须同步 contract tests。对外错误不得临时拼接未注册 `sub_code`，也不得把底层库异常、供应商错误码或数据库错误原样暴露为项目错误码。

## 操作注册表

公开操作必须有稳定 `operation_id`。操作注册表至少记录：

- `operation_id`。
- 通道：HTTP、CLI、callback、外部写回或内部服务调用。
- 调用方和鉴权边界。
- request schema、response data schema 或 callback data schema。
- 错误码集合。
- 幂等键和副作用说明。
- 日志事件和 metrics 名称。
- 版本、兼容策略和废弃策略。

FastAPI route、OpenAPI、README 示例和 CLI help 都必须引用或生成自操作注册表或等价真源。禁止两个 route 使用同一个 `operation_id` 表达不同语义。

## Schema Version 注册表

凡是会影响执行语义或对外契约的 schema，都必须有版本或等价 hash：

- HTTP request / data schema。
- `job_params_schema`。
- `runtime_fields_schema`。
- `canonical_result_schema`。
- `public_result_schema`。
- `callback_data_schema`。
- artifact ref schema。

版本注册表必须能回答：某个历史 Job 使用哪个 schema 版本创建、Worker 读取时如何校验、投影文档使用哪个 schema 版本生成。破坏性变更必须新版本化，不得在原版本上改变字段类型、枚举、空值语义或业务判断条件。

## Job Type 注册表

每个 `job_type` 必须在统一 registry 中声明：

- 稳定唯一的 `job_type`。
- handler 入口。
- params schema 和版本。
- runtime fields schema 和版本。
- canonical result schema 和版本。
- public result schema 和版本；允许显式为 `null`。
- callback data schema 和版本；未声明时默认引用 public result schema。
- 是否允许 callback、artifact、外部写回、bounded repair。
- 默认超时、成本预算、队列或并发分类。
- 支持的执行计划类型，例如 `single`、`chunked`、`chunked + finalize`。

API 进程、Worker、scheduler、recovery 和 Typer CLI 必须读取同一份 registry。不得维护“HTTP 专用 job_type 列表”和“Worker 专用 job_type 列表”。

## 生成与检查

项目至少应提供一个测试或脚本检查：

- 错误码、操作、schema version 和 `job_type` 注册表没有重复键。
- OpenAPI、README 示例、Typer help 和 callback 示例没有引用未注册对象。
- 每个公开操作的错误码都在错误码注册表中。
- 每个 `job_type` 的 params/result/callback schema 都有版本。
- 每个 `job_type` 的 public result 与 callback data 映射可从 canonical result 追溯。
- 删除或改名注册项时必须有版本策略、迁移窗口和兼容说明。

注册表检查失败时，应阻止合并或发布。不要在运行时用默认值补造缺失注册项。
