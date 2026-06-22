---
description: 后端外部服务调用、协议适配、写入副作用与环境保护规则
---

# 外部服务集成规则

外部服务集成规则负责约束后端服务如何调用第三方或上游业务系统。它不规定具体供应商 API，也不替代业务接口文档、框架日志规则、服务契约规则或 Job 状态机规则。对外暴露的响应 envelope、错误码分层和日志主字段见 `../contracts/service-contract.md`。当外部服务是模型供应商时，通用 client、失败分类和环境保护仍读取本文；Prompt、结构化输出、token/cost 和 bounded repair 读取 `../ai/capability-service.md`。

## 集成边界

当服务需要访问模型供应商、对象存储、业务后端、Webhook、支付、通知或其他外部系统时，必须建立独立集成边界：

```text
Service / Workflow
  -> integration client / adapter
  -> external service
```

不要在 API route、Repository 或散落的业务函数中直接拼接 HTTP 请求。外部协议变化应优先限制在 integration client 或 workflow 专用 adapter 内。

## Client 契约

外部 client 必须明确：

- base URL 或 endpoint 的配置来源。
- timeout、重试和失败分类。
- 请求 header、认证方式和调用方标识。
- 响应 envelope 校验。
- 成功条件和业务拒绝条件。
- 日志摘要字段。

响应不是 HTTP 2xx 就天然成功。若外部系统有 `code/msg/data` 或类似 envelope，必须校验 envelope 和关键字段。

外部系统 envelope 只能在 integration client 内适配。服务自己的对外 HTTP 响应和 Job `error` 必须转换为 `../contracts/service-contract.md` 定义的服务级错误码和项目子错误码，不能把上游 `code/msg/data` 原样穿透给调用方。

## 运行时字段接入

外部集成规则只定义哪些外部目标字段会影响执行语义，不定义异步 Job 的快照结构、校验和读取方式。

执行异步 Job 时，以下外部目标字段应交给运行时快照保存，而不是在 Worker 执行时重新读取会改变历史语义的 settings：

- 外部服务 base URL。
- 外部服务 timeout。
- 目标模型或供应商路由。
- 输出目标或回写目标。

密钥可以由平台环境注入，但不得写入日志、产物、runtime snapshot 或公开响应。

## 写入副作用

对外写操作必须显式建模，不要隐藏在普通查询、callback 或日志逻辑里。写入类副作用必须满足：

- 有明确触发时机，例如 Job 终态后。
- 有幂等键或重复写入保护。
- 记录请求摘要、目标 URL、响应摘要、错误分类和时间。
- 失败结果能进入 canonical result、审计日志或恢复队列。
- 生产写操作必须有显式 opt-in 或发布保护。

如果第三方写回是业务必须交付的一部分，应把写回结果纳入 Job 终态后的可观测信息；如果只是通知，应保证调用方仍可通过轮询查询终态。

## 环境保护

验证和发布脚本必须区分不同风险级别：

| 类型 | 默认行为 |
| --- | --- |
| health / contract | 可作为 test/prod 默认低副作用检查 |
| smoke / canary | 真实创建任务或调用模型，生产必须显式 opt-in |
| write check | 会写第三方系统或对象存储，生产必须显式 opt-in |
| insecure TLS | 只允许 local/test 显式启用，不允许 prod |

远端目标不要从普通应用 `.env` 中隐式推导。测试环境和生产环境的 base URL 应有明确来源，并在脚本中做环境名称或域名保护。

## 可观测与安全

外部调用日志记录摘要，不记录完整敏感载荷：

- 可以记录 method、url 主体、调用方、业务 id、状态码、耗时、错误码。
- 不记录 API key、token、签名、完整请求体、隐私文本和大文件内容。
- 供应商响应原文只在必要时截断记录，并避免返回给外部调用方。

外部错误应转换为稳定服务级错误码和项目子错误码。不要把底层库异常、供应商内部错误或网络栈细节直接暴露给 API 响应。
