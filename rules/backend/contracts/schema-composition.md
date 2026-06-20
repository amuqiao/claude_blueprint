---
description: 后端服务 Schema 组合、泛型 envelope、JobView 与 Callback 复用规则
---

# Schema 组合与复用规则

本规则定义后端服务如何复用 envelope、错误、JobView、CallbackEnvelope 和业务 schema，避免每个接口或 `job_type` 重新定义一套结构。它是 `service-contract.md` 的实现组织补充，不替代服务契约事实源。

## 核心原则

Schema 分为稳定外壳和业务扩展：

```text
ResponseEnvelope[TData]
ErrorEnvelope / ErrorDetail
JobView[TResult]
CallbackEnvelope[TData]
Operation Request / Data
JobType Params / CanonicalResult / PublicResult / CallbackData
```

稳定外壳只能统一定义一次。新增接口只能定义自己的 request schema 和业务 data schema；新增 `job_type` 只能定义自己的 params、canonical result、public result 和 callback data schema。

## 统一定义

项目应在公共 schema 模块中统一维护：

| Schema | 负责 | 禁止 |
| --- | --- | --- |
| `ResponseEnvelope[TData]` | HTTP `code/msg/data/request_id/server_time` | 在每个 route 中复制 envelope 字段 |
| `ErrorDetail` | `http_status/sub_code/details/retryable` 等错误细节 | 直接暴露库异常、堆栈或供应商原文 |
| `JobView[TResult]` | `job_id/job_type/status/progress/result/error/callback` | 复制多个 Job 查询响应结构 |
| `CallbackEnvelope[TData]` | callback 事件顶层字段 | 为每个 `job_type` 扩展 callback 顶层 |
| `Page/DataRef/ArtifactRef` | 分页、资源引用、大产物引用等公共结构 | 将大文件或大 JSON 直接塞进默认响应 |

如果使用 Pydantic，应优先使用泛型模型、组合模型或等价类型别名表达复用关系。若框架或语言版本不支持泛型，也必须通过统一工厂、基类或文档生成规则保持一个事实源。

## 接口 Schema 归属

新增同步接口只定义：

- `XxxRequest`：请求体或查询参数的业务字段。
- `XxxData`：成功响应 `data` 中的业务字段。
- 必要的业务子对象、枚举和资源引用。

接口不得重新定义：

- `code`、`msg`、`request_id`、`server_time`。
- 通用错误对象。
- 通用分页、artifact 引用或 Job 壳。
- 与其他接口同名但语义不同的公共字段。

## Job Type Schema 归属

新增 `job_type` 只定义：

- `ParamsSchema`：`job_params` 的业务输入。
- `CanonicalResultSchema`：Worker 内部完整结果。
- `PublicResultSchema`：轮询 `JobView.result` 的公开结果；可显式为 `null`。
- `CallbackDataSchema`：callback `data`；未声明时默认引用 `PublicResultSchema`。

通用 `CreateJobRequest`、`JobView`、`CallbackEnvelope` 和错误结构不得为某个 `job_type` 单独复制或扩展顶层字段。

## 组合规则

Schema 组合必须让调用方能稳定判断结构：

```text
POST /jobs -> ResponseEnvelope[CreateJobAcceptedData]
GET /jobs/{job_id} -> ResponseEnvelope[JobView[PublicResult]]
callback -> CallbackEnvelope[CallbackData]
```

当 `CallbackDataSchema` 与 `PublicResultSchema` 不一致时，必须声明二者如何从同一个 `CanonicalResultSchema` 派生。投影字段不得包含轮询结果中不存在或无法追溯的业务结论。

## OpenAPI 与文档投影

OpenAPI、SDK 类型、README 示例、CLI help 和接口文档都是 schema 的投影，不是第二套事实源。

必须满足：

- OpenAPI 不暴露未声明的顶层字段。
- 接口文档中的字段说明、必选/可选、类型、约束和示例来自 schema 或与 schema 对齐。
- README 示例不得手写一套与 schema 不一致的 envelope。
- SDK 类型生成失败或 schema 快照变化时，必须回到 schema 或契约测试修正。

## 兼容性

允许新增可选字段，但不得改变已有字段类型、枚举、`null` 语义、默认省略语义或业务判断条件。改变 `PublicResultSchema`、`CallbackDataSchema` 或二者映射属于契约变更，必须按 `service-contract.md` 的版本策略处理。

## 验收要求

Schema 组合至少通过以下检查：

- envelope、error、JobView、CallbackEnvelope 只有一个公共定义。
- 新接口 contract tests 覆盖 `ResponseEnvelope[TData]` 成功和失败结构。
- 新 `job_type` contract tests 覆盖 `JobView[PublicResult]` 与 `CallbackEnvelope[CallbackData]` 的一致性或映射关系。
- OpenAPI/schema 快照不出现重复 envelope、裸错误对象或未声明顶层字段。
