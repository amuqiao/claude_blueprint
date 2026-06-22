---
description: 后端 Artifact 存储、引用、Hash、权限、过期与清理规则
---

# Artifact 存储规则

Artifact 存储规则定义大文本、大 JSON、模型中间产物、可下载文件和审计材料如何脱离默认 API / Job 响应体进行交付。它补充服务契约、AI 能力和外部集成规则，不替代对象存储 SDK 或平台权限文档。

## 适用边界

满足任一条件时，必须引入 artifact 存储或等价受控存储：

- 结果体可能超过普通 API 响应或数据库 JSON 字段的合理大小。
- 结果包含大文本、大 JSON、文件、模型中间产物或可下载内容。
- 需要保存完整 Prompt、完整输入、完整模型输出用于受控审计。
- 需要向调用方交付可下载资源，而不是直接把内容放入 JobView。

如果项目明确不保存大产物，应在 `job_type` 契约中声明输出只包含小型结构化结果，并通过大小限制阻止大结果进入响应。

## Artifact 引用

公开响应和 JobView 中只能返回 artifact 引用，不默认返回完整内容。引用至少包含：

| 字段 | 规则 |
| --- | --- |
| `artifact_id` 或 `key` | 稳定定位符，不暴露本地绝对路径。 |
| `type` | 业务类型，例如 `json`、`text`、`file`、`model_trace`。 |
| `content_type` | MIME type 或等价内容类型。 |
| `size_bytes` | 字节大小。 |
| `sha256` | 内容 hash 或等价完整性校验。 |
| `expires_at` | ISO 8601 UTC 过期时间；永久保留必须显式说明。 |
| `access` | 访问方式摘要，例如 `signed_url`、`internal_only`、`callback_only`。 |

禁止在公开响应中返回本地文件路径、对象存储内部密钥、bucket 真实权限细节、临时凭证原文或未过期签名 URL 的敏感组成部分。需要下载时，应通过受控接口或短期签名 URL 生成。

## 写入边界

Artifact 写入必须在 service、handler 或 integration adapter 中显式建模，不得隐藏在日志逻辑或异常处理里。

写入时至少记录：

- 所属 `job_id`、`job_type`、`caller_id`。
- artifact 类型、content type、大小和 hash。
- 存储目标摘要。
- 创建时间、过期时间和保留策略。
- 写入错误分类和可重试性。

Artifact 写入失败是否导致 Job failed，必须由 `job_type` 契约声明。不要在 artifact 写入失败时返回空引用或伪造成功。

## 权限与敏感内容

Artifact 权限必须与调用方、租户、Job 或内部审计边界绑定。不得因为知道 artifact key 就能跨租户读取。

敏感 artifact 包括：

- 完整用户输入或隐私文本。
- 完整 Prompt。
- 完整模型输出。
- 供应商原始响应。
- 包含密钥、token、签名或内部路径的调试材料。

敏感 artifact 默认不应对调用方公开。确需保存用于审计时，应进入受控存储，并记录 hash、大小、内容类型、访问边界和审计事件。

## 过期与清理

每类 artifact 必须有保留策略：

- 默认过期时间。
- 是否允许延长。
- 终态 Job 清理后 artifact 是否保留。
- 清理失败如何记录和重试。
- 法务、审计或客户交付需要的例外保留。

清理任务必须有界、幂等并可排障。清理不得删除仍被未过期 JobView、callback 或审计记录引用的 artifact。

## 验收要求

Artifact 规则至少通过以下检查：

- 大结果不会直接进入默认 API 响应或 JobView 内容字段。
- Artifact 引用包含 key、content type、size、hash、expires_at 和 access 摘要。
- 跨调用方或跨租户读取被拒绝。
- 写入失败按 `job_type` 契约进入明确错误或终态。
- 清理任务幂等，且不会删除仍被有效 Job 引用的 artifact。
- 日志和 metrics 不包含完整敏感 artifact 内容。
