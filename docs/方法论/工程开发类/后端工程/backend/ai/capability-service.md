---
description: AI 能力服务 Provider、Prompt、结构化输出、结果校验与成本可观测规则
---

# AI 能力服务规则

本规则定义 AI 能力服务如何接入模型供应商、Prompt、结构化输出、结果校验和成本可观测。它适用于以 FastAPI 暴露能力、以异步 Job 执行长任务，并通过 Typer 排障的后端服务。

本文只规定 AI 能力边界和输出稳定性，不定义 HTTP envelope、通用 Job 状态机、数据库模型或部署平台。服务契约读取 `../contracts/service-contract.md`，Job handler 读取 `../jobs/workflow-handler.md`，外部 client 边界读取 `../integrations/external-service.md`。

## 能力边界

AI 能力服务应把“业务能力”和“模型供应商协议”分开：

```text
WorkflowHandler
  -> AI capability service
  -> provider adapter
  -> model provider
```

WorkflowHandler 负责 `job_type`、入参 schema、执行计划和结果映射。AI capability service 负责组织模型调用、Prompt 版本、输出约束和结果校验。provider adapter 负责供应商 API、认证、timeout、重试和供应商响应适配。

不要在 FastAPI route、Repository、Typer command 或散落工具函数中直接调用模型供应商。

## Provider Adapter

模型供应商仍属于外部服务，通用 client 边界、base URL、认证、timeout、重试、失败分类、环境保护和供应商响应适配读取 `../integrations/external-service.md`。本文只补充 AI 专属的 provider adapter 增量。

AI provider adapter 必须额外明确：

- provider 名称、模型标识和供应商能力限制。
- Prompt、工具调用、结构化输出或 JSON schema 能力如何映射到供应商请求。
- token 输入/输出数量、估算成本、finish reason、模型延迟和速率限制摘要。
- 模型拒答、截断、内容过滤、输出格式错误和 schema 校验失败如何分类。
- 哪些字段允许进入 runtime snapshot，哪些字段只能作为敏感配置从环境注入。

供应商响应不得原样穿透到公开 API 或 Job `error.details`。供应商错误必须转换为服务级错误码和项目子错误码。

## Runtime Snapshot

会影响历史执行语义的 AI 字段必须进入 Job runtime snapshot 或等价结构：

- provider 与模型标识。
- Prompt 模板标识、版本和渲染所需的非敏感变量摘要。
- 输出 schema 名称和版本。
- 模型调用主 timeout、重试策略和重要采样参数。
- 输出目标、对象存储目标或第三方写回目标。

密钥、token、完整敏感输入、完整 Prompt 和大文本不应进入 runtime snapshot。确需保存完整 Prompt 或输入用于审计时，应进入受控 artifact 存储，并记录 hash、大小、内容类型和访问边界。

## 结构化输出

AI 输出必须先经过结构化校验，再进入 canonical result。不得把模型自然语言输出直接当作稳定业务结果。

每个 AI `job_type` 至少声明：

- `params_schema`：调用方输入。
- `prompt_contract`：Prompt 模板、变量、版本和禁止泄漏字段。
- `model_contract`：provider、模型、超时、成本或 token 预算。
- `canonical_result_schema`：内部完整结果。
- `public_result_schema`：轮询公开结果。
- `callback_data_schema`：callback 数据；未声明时默认等同公开结果。

模型输出校验失败时必须 fail-fast，写入明确错误分类。不要静默丢弃字段、自动补默认值、吞掉非法枚举或把半结构化文本包装成成功结果。

## Bounded Repair

默认不启用输出修复。若项目允许对模型输出做 bounded repair，必须在 handler 契约中显式声明：

- 哪些校验错误允许修复。
- 最大修复次数。
- 修复使用的模型、Prompt 和 timeout。
- 修复前后结果的 hash 和摘要。
- 修复失败后的错误码和 `retryable` 语义。
- 日志事件和成本统计方式。

bounded repair 不能改变业务事实，不能补造调用方输入中不存在的信息，也不能让原始非法输出绕过 `canonical_result_schema`。

## Prompt 与输入安全

Prompt 组装必须在 AI capability service 或 handler 内集中完成。Prompt 模板、变量和输出约束应有稳定版本，不在 route 或 adapter 中拼接。

禁止默认记录：

- 完整用户输入、隐私文本、密钥、token。
- 完整 Prompt。
- 完整模型输出。
- 供应商原始响应全文。

可记录摘要：

- 输入规模、语言、文件数量、hash。
- prompt template id 和 version。
- provider、model、finish reason。
- token 输入/输出数量、估算成本、耗时。
- 输出 schema 版本和校验结果。

## 成本与容量保护

AI 能力服务必须从 MVP 阶段建立成本和容量边界：

- 输入大小限制和文件数量限制。
- 单 Job token 或成本预算。
- provider timeout 和重试上限。
- worker 并发、队列积压和队列满拒绝策略。
- 生产环境真实调用或 canary 必须显式 opt-in。

超预算、超大小、超时和速率限制应转换为稳定错误码。不要通过降级模型、截断输入或返回空结果来伪装成功，除非该行为已在接口契约中明确声明。

## 结果交付

AI 结果分为 canonical result、public result 和 callback data。轮询和 callback 的关系读取服务契约；本规则只约束 AI 结果进入这些结构前必须完成校验和映射。

大文本、大 JSON、模型中间产物和可下载文件应写入对象存储或 artifact 存储。公开响应只返回引用、hash、大小、内容类型、过期时间和必要摘要。

## 验收要求

AI 能力服务至少覆盖以下测试或检查：

- provider adapter 成功、业务失败、HTTP 失败、超时和限流分类。
- Prompt 版本和 runtime snapshot 生成。
- 模型输出合法时通过 schema 校验并生成 canonical result。
- 模型输出缺字段、非法枚举、额外字段和非 JSON 时失败。
- public result 与 callback data 从同一 canonical result 派生。
- 日志不包含密钥、完整 Prompt、完整隐私输入或供应商响应全文。
- token、成本、模型、provider 和 duration 摘要可排查。
