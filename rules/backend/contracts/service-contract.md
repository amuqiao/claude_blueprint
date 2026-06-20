---
description: 后端服务输入输出、错误码、异常转换、Job 契约、Callback 和日志字段规则
---

# 后端服务契约规则

本规则定义可复用后端服务的对外契约骨架：调用方无论接入同步接口、异步 Job、callback 还是外部写回，都应看到一致的输入边界、错误语义、关联字段、兼容性规则和排障入口。HTTP 业务接口、callback 事件和外部系统响应可以有不同顶层协议；统一的是服务语义，不是所有通道强行共用同一个 envelope。

## 文档职责

本文负责定义：

- HTTP 输入输出 envelope。
- 错误码、HTTP status 和项目子错误码的关系。
- 异常到对外错误的转换边界。
- 异步 Job 创建、查询、终态和 callback 的对外骨架。
- 结构化日志必须携带的关联字段。
- 新增接口或新增 `job_type` 的契约验收要求。

本文不负责定义：

- 具体 Web 框架 API。
- Celery、Taskiq 或其他执行器 API。
- 具体业务字段、Prompt、模型参数、供应商协议。
- Job 状态机、投递、恢复和执行计划细节。

专项规则只能引用本文并说明接入方式，不得另起一套响应格式、错误结构或日志字段事实源。

## 核心模型

服务契约分为稳定层和扩展层：

| 层级 | 归属 | 规则 |
| --- | --- | --- |
| HTTP 服务 envelope | `code`、`msg`、`data`、`request_id`、`server_time` | 所有 HTTP 业务接口统一 |
| Callback 事件 envelope | `schema_version`、`event`、`event_id`、`job_id`、`status`、`data` | 所有终态事件通知统一 |
| 外部响应适配 | 外部 `code/msg/data` 或供应商协议 | 只能在 integration client 内校验并转换 |
| 错误判断 | HTTP status、服务级 `code`、项目 `sub_code`、Job `error` | 调用方机器判断必须稳定 |
| 关联上下文 | `request_id`、`trace_id`、`trigger_request_id`、`caller_id`、`job_id` | 按通道携带，语义不能混用 |
| 异步 Job 壳 | `job_id`、`job_type`、`job_params`、`status`、`result`、`error`、`callback` | 所有 Job 类型统一 |
| 业务扩展 | 同步接口 `data`、Job `job_params`、Job `result`、Callback `data` | 由具体接口或 `job_type` 定义 |

通用顶层字段必须少而稳定。新增业务能力时，优先扩展对应的业务扩展位，不要把业务字段提升为服务顶层字段。HTTP envelope、callback envelope 和外部响应适配各自独立；不要把外部供应商协议或 callback 事件体改造成 HTTP `code/msg/data`。

## HTTP Envelope

所有受保护业务接口必须返回统一 JSON envelope。健康检查、metrics、静态文件、OpenAPI、下载流、流式响应和框架内置页面可以按生态约定返回，不强制套业务 envelope；但它们必须在接口文档中标注为例外。

成功响应：

```json
{
  "code": "OK",
  "msg": "success",
  "data": {
    "id": "usr_123",
    "name": "Alice"
  },
  "request_id": "req-20260620-0001",
  "server_time": 1781753745
}
```

错误响应：

```json
{
  "code": "INVALID_INPUT",
  "msg": "request validation failed",
  "data": {
    "error": {
      "http_status": 422,
      "sub_code": "COMMON.INVALID_FIELD",
      "details": {
        "field": "job_params.assets",
        "reason": "at least one subtitle_srt is required"
      },
      "retryable": false
    }
  },
  "request_id": "req-20260620-0001",
  "server_time": 1781753745
}
```

字段规则：

| 字段 | 必填 | 规则 |
| --- | ---: | --- |
| `code` | 是 | 服务级稳定码。成功固定为 `OK`；失败使用错误码分层中的服务级错误码。 |
| `msg` | 是 | 面向调用方和排障人员的短消息，不作为机器判断依据。 |
| `data` | 是 | 成功时承载业务数据；错误时承载 `error` 对象；无数据时为 `{}` 或 `null`，同一接口必须稳定。 |
| `request_id` | 是 | 本次 HTTP 请求 id。调用方传入可信 id 时可沿用，否则服务生成；后台 Job 不得把 `job_id` 冒充为 `request_id`。 |
| `server_time` | 是 | 服务端 Unix 秒级时间戳，用于调用方排查时钟和日志对齐。 |

HTTP status 必须保留真实语义，不允许业务接口为了“统一返回”全部使用 `200`。调用方应先按 HTTP status 区分传输和权限语义，再按 `code` 和 `sub_code` 做业务判断。

## 操作定义

每个公开操作必须有稳定定义，不论它最终由 HTTP、CLI、callback 还是内部服务调用承载。

操作定义至少包含：

| 字段 | 说明 |
| --- | --- |
| `operation_id` | 稳定操作 id，用于文档、OpenAPI、SDK 和 contract test 对齐。 |
| 调用方 | 谁可以调用，调用方身份如何传递。 |
| 模式 | 同步、异步 Job、callback、只读排障或外部写回。 |
| 输入 | 顶层字段、必填/可选、`null` 与省略、大小限制、枚举和幂等键。 |
| 输出 | 按通道定义成功响应或事件 envelope、业务 `data`、资源引用、大产物交付方式。 |
| 错误 | 服务级错误码、项目子错误码、HTTP status、可重试性。 |
| 可观测 | `request_id`、`trace_id`、`trigger_request_id`、业务 id、`job_id`、日志事件和排障入口。 |

OpenAPI、CLI `--help`、SDK 类型和 README 示例都是契约投影，不是事实源。事实源必须能被这些投影引用或生成。

## 规范化真源

服务契约必须落到可执行或可检查的项目真源中，不能只停留在说明文字。推荐真源优先级：

1. 本文定义的跨项目基线规则、字段语义和正例要求。
2. 项目内 schema、错误码注册表、handler registry 或等价类型定义。
3. Contract tests、OpenAPI/schema 快照和日志字段快照。
4. README、接口示例、SDK 类型和 CLI help 等投影文档。

当投影文档与 schema、错误码注册表或 contract tests 冲突时，应修正投影或实现，而不是在专项文档里临时补另一套定义。


## 输入契约

每个接口必须显式定义输入顶层字段。默认拒绝未声明字段；只有明确声明为透传扩展位的字段可以接收自由对象。

同步接口输入正例：

```json
{
  "title": "Acting for Real",
  "language": "en",
  "options": {
    "include_archived": false
  }
}
```

异步 Job 创建输入正例：

```json
{
  "client_request_id": "caller-a:content-2042:initial:20260620",
  "job_type": "content.tagging.initial",
  "job_params": {
    "content_id": "content-2042",
    "language": "en",
    "assets": [
      {
        "asset_type": "subtitle_srt",
        "episode_no": 1,
        "text": "1\n00:00:01,000 --> 00:00:03,000\nHello."
      }
    ]
  },
  "callback": {
    "url": "https://caller.example.com/ai-jobs/callback",
    "events": ["job.succeeded", "job.failed"]
  },
  "metadata": {
    "caller_service": "caller-a"
  },
  "options": {
    "priority": "normal",
    "timeout_seconds": 1800
  }
}
```

输入规则：

- 顶层字段必须稳定；能力专属字段进入 `job_params` 或接口自己的业务对象。
- `metadata` 只透传调用方排查信息，不承载服务执行所需的关键参数。
- `options` 只放通用执行选项，不放业务字段。
- 幂等键必须由调用方按业务任务生成，不应每次重试随机生成。
- 文档必须说明 `null`、空数组、空字符串和字段省略的差异。
- 校验失败必须 fail-fast，不能静默忽略非法字段、自动降级或用默认值吞错。

## 成功输出正例

同步接口成功：

```json
{
  "code": "OK",
  "msg": "success",
  "data": {
    "items": [
      {
        "id": "tag_001",
        "name": "Comedy"
      }
    ],
    "next_cursor": null
  },
  "request_id": "req-20260620-0002",
  "server_time": 1781753745
}
```

异步 Job 创建成功，HTTP status 使用 `202 Accepted`：

```json
{
  "code": "OK",
  "msg": "accepted",
  "data": {
    "job_id": "7b5c2c62-9a3a-41b7-bd41-f24a5d34a099",
    "client_request_id": "caller-a:content-2042:initial:20260620",
    "job_type": "content.tagging.initial",
    "status": "queued",
    "status_url": "/api/v1/jobs/7b5c2c62-9a3a-41b7-bd41-f24a5d34a099",
    "created_at": "2026-06-20T10:00:00Z"
  },
  "request_id": "req-20260620-0003",
  "server_time": 1781753745
}
```

异步 Job 查询运行中：

```json
{
  "code": "OK",
  "msg": "success",
  "data": {
    "job_id": "7b5c2c62-9a3a-41b7-bd41-f24a5d34a099",
    "client_request_id": "caller-a:content-2042:initial:20260620",
    "job_type": "content.tagging.initial",
    "status": "running",
    "progress": {
      "percent": 35,
      "stage": "fetching_schema",
      "message": "fetching tag schema"
    },
    "result": null,
    "error": null,
    "callback": {
      "status": "pending",
      "attempts": 0,
      "next_retry_at": null,
      "last_error": null
    },
    "metadata": {
      "caller_service": "caller-a"
    },
    "created_at": "2026-06-20T10:00:00Z",
    "started_at": "2026-06-20T10:00:05Z",
    "finished_at": null
  },
  "request_id": "req-20260620-0004",
  "server_time": 1781753745
}
```

异步 Job 查询成功终态：

```json
{
  "code": "OK",
  "msg": "success",
  "data": {
    "job_id": "7b5c2c62-9a3a-41b7-bd41-f24a5d34a099",
    "job_type": "content.tagging.initial",
    "status": "succeeded",
    "progress": {
      "percent": 100,
      "stage": "finished",
      "message": "finished"
    },
    "result": {
      "artifacts": [
        {
          "key": "tags",
          "type": "json",
          "label": "Generated tags",
          "content": {
            "tag_ids": ["tag_001"]
          }
        }
      ],
      "signals": {
        "validation_issue_count": 0
      }
    },
    "error": null,
    "callback": {
      "status": "delivered",
      "attempts": 1,
      "next_retry_at": null,
      "last_error": null
    },
    "metadata": {},
    "created_at": "2026-06-20T10:00:00Z",
    "started_at": "2026-06-20T10:00:05Z",
    "finished_at": "2026-06-20T10:03:00Z"
  },
  "request_id": "req-20260620-0005",
  "server_time": 1781753745
}
```

如果某个 `job_type` 明确声明公开结果为 `null`，成功终态允许 `result=null`，但必须在该 `job_type` 的契约中写明结果通过 callback、第三方写回或其他稳定渠道交付。通用规则不得同时要求所有成功 Job 都有非空 `result`。

大文本、大文件和大 JSON 不应直接作为默认响应体返回。应返回对象存储引用、下载地址、hash、大小、内容类型和过期时间等可验证信息。

## Job 轮询与 Callback 结果关系

Job 轮询和 callback 必须有关联，但不应强制使用同一个顶层结构。轮询接口返回的是 Job 当前权威状态视图；callback 发送的是终态事件通知。二者的 envelope 不同，但必须来自同一个 Job 终态和同一份结果事实源。

`JobView` 和 `CallbackEnvelope` 只是两个不同通道的稳定外壳，不拥有具体业务 result 结构。具体 result 结构由 `job_type` 的 `public_result_schema` 定义和维护。默认情况下，`GET /jobs/{job_id}.data.result` 和 `CallbackEnvelope.data` 引用同一个 `public_result_schema`；因此新增或调整某个 Job 的业务结果时，只维护对应 `job_type` 的 result schema，不修改通用轮询结构或 callback 结构。

关系规则：

| 对象 | 字段 | 事实源 | 规则 |
| --- | --- | --- | --- |
| 轮询状态 | `GET /jobs/{job_id}` 的 `data` | Job 持久化状态 | 权威状态视图，调用方可随时查询。 |
| 轮询结果 | `GET /jobs/{job_id}` 的 `data.result` | `public_result_schema` | 成功终态的公开结果；允许按 `job_type` 明确为 `null`。 |
| Callback 事件 | `CallbackEnvelope` | Job 终态事件 | 只通知 `job.succeeded` 或 `job.failed`，不替代轮询。 |
| Callback 数据 | `CallbackEnvelope.data` | `public_result_schema` 或 `callback_data_schema` | 默认引用 `public_result_schema`；需要更小投影时必须显式声明 `callback_data_schema` 和映射。 |
| 内部结果 | `canonical_result_schema` | Worker / handler 产物 | 轮询结果和 callback 数据都只能从它派生，不能各自重新计算。 |

默认规则：如果 `job_type` 没有声明专门的 `callback_data_schema`，成功 callback 的 `data` 必须引用与 `GET /jobs/{job_id}.data.result` 相同的 `public_result_schema`。这表示两处字段结构、字段含义、枚举、空值语义和兼容性规则完全一致。

默认同 schema 正例：

```json
{
  "polling_result": {
    "artifacts": [
      {
        "key": "tags",
        "type": "json",
        "label": "Generated tags",
        "content": {
          "tag_ids": ["tag_001"]
        }
      }
    ],
    "signals": {
      "validation_issue_count": 0
    }
  },
  "callback_data": {
    "artifacts": [
      {
        "key": "tags",
        "type": "json",
        "label": "Generated tags",
        "content": {
          "tag_ids": ["tag_001"]
        }
      }
    ],
    "signals": {
      "validation_issue_count": 0
    }
  }
}
```

允许投影规则：如果 callback 只需要通知调用方一个更小的业务结果，`job_type` 必须同时声明 `public_result_schema`、`callback_data_schema` 和二者从 `canonical_result_schema` 派生的映射。投影字段不得与轮询结果冲突，不得包含轮询结果中不存在或无法追溯的业务结论。

允许投影正例：

```json
{
  "polling_result": {
    "artifacts": [
      {
        "key": "tags",
        "type": "json",
        "label": "Generated tags",
        "content": {
          "tag_ids": ["tag_001"]
        }
      }
    ],
    "signals": {
      "content_id": "content-2042",
      "accepted": true,
      "validation_issue_count": 0
    }
  },
  "callback_data": {
    "content_id": "content-2042",
    "accepted": true
  }
}
```

失败终态规则：轮询 `data.error` 和 callback `error` 必须使用同一个 Job `error` 对象。Callback 可以在 `data` 中携带用于幂等或业务定位的最小字段，但不得另行定义一套失败原因。

`result=null` 规则：如果轮询成功终态的 `result` 被声明为 `null`，callback 可以作为业务结果的交付投影，但该 `job_type` 必须明确声明：

- 为什么轮询不公开结果。
- callback `data` 的 schema。
- callback `data` 与 `canonical_result_schema` 的映射。
- 调用方在 callback 丢失、延迟或重复时如何通过轮询确认 Job 终态。

禁止行为：

- 轮询 `result` 和 callback `data` 分别由两套逻辑生成。
- Callback 返回了与轮询终态不一致的 `status`、`error`、业务 id 或结果判断。
- Callback `data` 依赖发送时的当前 settings 重新推导历史结果。
- 把 callback 投递状态放进 callback 正文；投递状态应由后续轮询的 `data.callback` 查看。
- 新增 `job_type` 时只写轮询正例，不写 callback 数据和轮询结果的映射关系。


## 错误输出正例

参数错误，HTTP status 使用 `422 Unprocessable Entity`：

```json
{
  "code": "INVALID_INPUT",
  "msg": "job_params does not match job_type schema",
  "data": {
    "error": {
      "http_status": 422,
      "sub_code": "JOB.INVALID_PARAMS",
      "details": {
        "job_type": "content.tagging.initial",
        "field": "job_params.assets"
      },
      "retryable": false
    }
  },
  "request_id": "req-20260620-0006",
  "server_time": 1781753745
}
```

异步 Job 失败终态仍通过查询接口返回 HTTP `200`，因为查询本身成功；失败语义进入 Job `error`：

```json
{
  "code": "OK",
  "msg": "success",
  "data": {
    "job_id": "7b5c2c62-9a3a-41b7-bd41-f24a5d34a099",
    "job_type": "content.tagging.initial",
    "status": "failed",
    "progress": {
      "percent": 100,
      "stage": "failed",
      "message": "failed"
    },
    "result": null,
    "error": {
      "code": "EXTERNAL_SERVICE_FAILED",
      "message": "failed to fetch tag schema",
      "sub_code": "EXTERNAL.TAG_SCHEMA_FETCH_FAILED",
      "details": {
        "service": "tag-schema-service",
        "operation": "fetch_default_schema"
      },
      "retryable": true
    },
    "callback": {
      "status": "pending",
      "attempts": 0,
      "next_retry_at": null,
      "last_error": null
    },
    "metadata": {},
    "created_at": "2026-06-20T10:00:00Z",
    "started_at": "2026-06-20T10:00:05Z",
    "finished_at": "2026-06-20T10:01:30Z"
  },
  "request_id": "req-20260620-0007",
  "server_time": 1781753745
}
```

不要把底层库异常类名、堆栈、token、签名、完整第三方响应或大载荷放进对外错误。必要排障信息进入结构化日志或内部 canonical result。

## 错误码分层

错误码分三层：

| 层级 | 字段 | 用途 |
| --- | --- | --- |
| HTTP status | 响应状态码 | 表达协议、权限、资源和服务可用性语义。 |
| 服务级错误码 | `code` 或 Job `error.code` | 跨项目稳定分类，供调用方通用处理。 |
| 项目子错误码 | `data.error.sub_code` 或 Job `error.sub_code` | 项目、领域或外部依赖的精确失败原因。 |

服务级错误码建议基线：

| HTTP | `code` | 语义 | 默认可重试 |
| ---: | --- | --- | --- |
| 200 / 201 / 202 | `OK` | 成功 | 否 |
| 400 | `BAD_REQUEST` | 请求语义非法，无法按当前接口解释 | 否 |
| 401 | `UNAUTHORIZED` | 未认证或凭证无效 | 否 |
| 403 | `FORBIDDEN` | 已认证但无权限 | 否 |
| 404 | `NOT_FOUND` | 资源不存在或对当前调用方不可见 | 否 |
| 409 | `CONFLICT` | 幂等键冲突、状态冲突或并发写冲突 | 视场景 |
| 422 | `INVALID_INPUT` | 字段、schema 或业务前置校验失败 | 否 |
| 429 | `RATE_LIMITED` | 限流或容量保护 | 是 |
| 500 | `INTERNAL_ERROR` | 未分类内部错误 | 是 |
| 502 | `EXTERNAL_SERVICE_FAILED` | 上游或第三方返回失败 | 是 |
| 503 | `SERVICE_UNAVAILABLE` | 服务不可用、队列满或依赖不可用 | 是 |
| 504 | `TIMEOUT` | 请求、Job 或外部调用超时 | 是 |

项目子错误码使用命名空间：

```text
COMMON.INVALID_FIELD
AUTH.INVALID_CALLER
JOB.INVALID_TYPE
JOB.INVALID_PARAMS
JOB.NOT_FOUND
JOB.CLIENT_REQUEST_CONFLICT
JOB.QUEUE_FULL
JOB.TIMEOUT
MODEL.NOT_AVAILABLE
MODEL.CALL_FAILED
EXTERNAL.TAG_SCHEMA_FETCH_FAILED
EXTERNAL.RESULT_WRITE_FAILED
CALLBACK.URL_INVALID
CALLBACK.DELIVERY_FAILED
INTERNAL.CONTRACT_INVALID
```

新增子错误码必须写清：

- 触发条件。
- 对应 HTTP status 或 Job failed 场景。
- 是否可重试。
- 调用方建议动作。
- `details` 允许暴露的字段。
- 日志中必须记录的排障字段。

## 异常转换

异常处理必须集中，不要在每个接口或 Job 分支里临时拼错误响应。

转换规则：

| 来源 | 处理 |
| --- | --- |
| 请求 schema 校验失败 | 转为 `INVALID_INPUT` + 子错误码 `COMMON.INVALID_FIELD`。 |
| 已知业务异常 | 抛出或返回带 `code`、`sub_code`、`message`、`details`、`retryable` 的应用错误。 |
| 外部依赖异常 | 在 integration adapter 中转换为 `EXTERNAL_SERVICE_FAILED` 或更具体服务级错误。 |
| Job 执行异常 | 写入 Job `error`，进入 `failed` 终态；查询接口本身仍按 envelope 返回。 |
| 未知异常 | 日志记录堆栈和关联字段；对外返回 `INTERNAL_ERROR`，不暴露内部细节。 |

不得为了“稳定”添加 silent catch、空结果兼容、默认值吞错或隐式降级。稳定的含义是错误结构稳定、错误码明确、日志可排查，而不是让错误消失。

## Callback 契约

Callback 是终态通知，不替代轮询。Callback 请求体必须有稳定事件 envelope，业务字段只放在 `data`。

成功 callback 正例：

```json
{
  "schema_version": "v1",
  "event": "job.succeeded",
  "event_id": "8e6a3d4a-1d43-4f4a-a5f5-1efcb75e5a6d",
  "attempt": 1,
  "sent_at": "2026-06-20T10:03:01Z",
  "job_id": "7b5c2c62-9a3a-41b7-bd41-f24a5d34a099",
  "client_request_id": "caller-a:content-2042:initial:20260620",
  "trigger_request_id": "req-20260620-0003",
  "caller_id": "caller-a",
  "job_type": "content.tagging.initial",
  "status": "succeeded",
  "error": null,
  "metadata": {
    "caller_service": "caller-a"
  },
  "data": {
    "content_id": "content-2042",
    "accepted": true
  }
}
```

失败 callback 正例：

```json
{
  "schema_version": "v1",
  "event": "job.failed",
  "event_id": "f4f07a63-4f76-4f38-8ce4-3e509690a3fb",
  "attempt": 1,
  "sent_at": "2026-06-20T10:01:31Z",
  "job_id": "7b5c2c62-9a3a-41b7-bd41-f24a5d34a099",
  "client_request_id": "caller-a:content-2042:initial:20260620",
  "trigger_request_id": "req-20260620-0003",
  "caller_id": "caller-a",
  "job_type": "content.tagging.initial",
  "status": "failed",
  "error": {
    "code": "EXTERNAL_SERVICE_FAILED",
    "message": "failed to fetch tag schema",
    "sub_code": "EXTERNAL.TAG_SCHEMA_FETCH_FAILED",
    "details": {
      "service": "tag-schema-service"
    },
    "retryable": true
  },
  "metadata": {
    "caller_service": "caller-a"
  },
  "data": {
    "content_id": "content-2042"
  }
}
```

Callback 规则：

- 调用方按 `job_id + event` 做业务幂等。
- `event_id` 标识一次投递事件，不替代业务幂等键。
- Callback 载荷只定义调用方可依赖的事件字段和业务 `data`；投递失败判定、重试、恢复和终态副作用边界由 `../integrations/external-service.md` 定义。
- Callback 响应如果也使用 `code/msg/data`，integration client 必须校验 `code=OK` 或项目约定成功码，并转换为服务级错误语义。

## 结构化日志

服务日志必须使用可机器解析的结构化字段。日志格式可以是 JSON，也可以是平台能解析的 key-value，但字段语义必须稳定。

通用字段：

| 字段 | 规则 |
| --- | --- |
| `timestamp` | 事件时间。 |
| `level` | `INFO`、`WARNING`、`ERROR` 等。 |
| `service` | 服务名。 |
| `env` | `local`、`test`、`prod` 等环境名。 |
| `event` | 稳定事件名，例如 `request_completed`、`job_failed`。 |
| `request_id` | HTTP 请求 id；后台 Job 无原始请求时可以为 `null` 或省略，不得填入 `job_id`。 |
| `trace_id` | 跨进程链路 id；可由入口生成，也可由 Job 创建时保存并传递给 Worker。 |
| `trigger_request_id` | 触发 Job 或 callback 的入口请求 id；用于把后台阶段关联回创建请求。 |
| `caller_id` | 调用方或租户摘要。 |
| `job_id` | 有 Job 时必填。 |
| `job_type` | 有 Job 时必填。 |
| `error_code` | 失败时填服务级错误码。 |
| `sub_code` | 失败时填项目子错误码。 |
| `duration_ms` | 请求、外部调用或任务阶段耗时。 |

HTTP 请求完成日志正例：

```json
{
  "timestamp": "2026-06-20T10:00:01Z",
  "level": "INFO",
  "service": "content-ai-service",
  "env": "prod",
  "event": "request_completed",
  "request_id": "req-20260620-0008",
  "caller_id": "caller-a",
  "http_method": "POST",
  "http_path": "/api/v1/jobs",
  "http_status": 202,
  "duration_ms": 42
}
```

Job 失败日志正例：

```json
{
  "timestamp": "2026-06-20T10:01:30Z",
  "level": "ERROR",
  "service": "content-ai-service",
  "env": "prod",
  "event": "job_failed",
  "request_id": null,
  "trace_id": "trace-7b5c2c62",
  "trigger_request_id": "req-20260620-0003",
  "job_id": "7b5c2c62-9a3a-41b7-bd41-f24a5d34a099",
  "job_type": "content.tagging.initial",
  "error_code": "EXTERNAL_SERVICE_FAILED",
  "sub_code": "EXTERNAL.TAG_SCHEMA_FETCH_FAILED",
  "duration_ms": 85000
}
```

外部调用日志正例：

```json
{
  "timestamp": "2026-06-20T10:00:20Z",
  "level": "WARNING",
  "service": "content-ai-service",
  "env": "prod",
  "event": "external_call_failed",
  "request_id": null,
  "trace_id": "trace-7b5c2c62",
  "trigger_request_id": "req-20260620-0003",
  "job_id": "7b5c2c62-9a3a-41b7-bd41-f24a5d34a099",
  "job_type": "content.tagging.initial",
  "external_service": "tag-schema-service",
  "operation": "fetch_default_schema",
  "http_status": 502,
  "error_code": "EXTERNAL_SERVICE_FAILED",
  "sub_code": "EXTERNAL.TAG_SCHEMA_FETCH_FAILED",
  "duration_ms": 3000
}
```

禁止默认记录完整请求体、完整响应体、密钥、token、签名、隐私文本、大文件内容或供应商原始错误全文。

## 兼容性与版本演进

允许的兼容变更：

- 新增可选字段，且默认省略不改变旧调用方语义。
- 新增错误子码，但服务级错误码和 HTTP status 仍落在原有类别中。
- 新增 `job_type`，不改变已有 `job_type` 的 `job_params`、`result` 和 callback 语义。
- 新增日志字段，不删除或改名已有主字段。

破坏性变更必须有版本策略：

- 改名、删除或改变字段类型。
- 改变 `null`、省略、空数组或空字符串含义。
- 改变成功/失败判断条件。
- 改变错误码、HTTP status、幂等键、轮询结果与 callback 数据映射或 callback 幂等语义。
- 将原本公开的 `result` 改为 `null`，改变 `callback_data_schema`，或将原本 callback 交付改为轮询交付。

破坏性变更必须先定义新版本、迁移窗口、调用方灰度和回滚方案。

## 新接口接入清单

新增 HTTP 接口必须确认：

- 请求顶层字段已定义，未知字段默认拒绝。
- 成功响应套统一 envelope。
- 错误响应使用服务级错误码和子错误码。
- HTTP status 与错误语义一致，不全部返回 `200`。
- OpenAPI 或接口文档包含最小合法输入/输出、典型完整输入/输出和至少一个错误正例。
- 日志能通过 `request_id`、`caller_id` 和业务 id 排查。
- 外部依赖错误经过 adapter 转换，不直接泄露底层异常。

## 新 Job Type 接入清单

新增 `job_type` 必须确认：

- `job_type` 稳定、唯一、可暴露。
- `job_params` schema 明确，非法输入在创建阶段 fail-fast。
- 创建响应、查询响应、失败响应都遵守 envelope。
- `queued/running/succeeded/failed` 状态语义来自通用 Job 规则。
- 成功终态的 `result` 是否公开非空已在 handler 契约中明确。
- `public_result_schema`、`callback_data_schema` 及二者映射已明确；未声明专门 callback schema 时，callback `data` 默认等同公开 `result`。
- 失败终态写入统一 Job `error`，包含 `code`、`message`、`sub_code`、`details`、`retryable`。
- Callback `data` 的业务字段有正例，不扩展 callback 顶层，且不与轮询 `result` 或 Job `error` 冲突。
- 结构化日志包含 `job_id`、`job_type`、`event`、`error_code` 和 `sub_code`。
- Contract tests 覆盖创建、查询运行中、成功终态、失败终态、callback、轮询结果与 callback 数据映射和错误码。

## 验收要求

服务契约不是只写文档。项目必须用测试或生成检查守住契约：

- OpenAPI 或 schema 快照不应暴露未声明顶层字段。
- 主要接口至少有成功和失败响应样例。
- 全局异常处理测试覆盖校验错误、业务错误和未知错误。
- Job contract tests 覆盖状态、`result/error` 组合，以及轮询 `result` 与 callback `data` 的一致性或映射关系。
- 日志测试或快照至少覆盖请求完成和失败分类字段。
- 外部 client tests 覆盖 envelope 成功、业务失败、HTTP 失败和超时。

当契约需要破坏性调整时，必须先定义版本策略、迁移窗口和调用方兼容方案。
