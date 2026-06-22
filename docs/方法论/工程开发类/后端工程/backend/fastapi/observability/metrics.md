---
description: FastAPI、异步 Job 与 AI 能力服务最小 Metrics 规则
---

# Metrics 规则

本规则定义 FastAPI、异步 Job 和 AI 能力服务的最小指标面。日志用于还原事件和排障，metrics 用于观察趋势、容量、错误率和告警。本文不规定具体 Prometheus、OpenTelemetry 或平台采集实现。

## 指标边界

Metrics 必须使用稳定名称、标签和单位。不要把高基数字段放进标签，例如完整 `request_id`、`job_id`、用户输入、Prompt、URL query、文件名或异常消息。

允许作为标签的字段应低基数且稳定，例如：

- `service`
- `env`
- `operation_id`
- `http_method`
- `http_route`
- `http_status`
- `code`
- `sub_code`
- `job_type`
- `job_status`
- `provider`
- `model`
- `callback_status`

`request_id`、`trace_id`、`job_id`、`client_request_id` 应进入日志、trace 或 Typer 输出，不进入 metrics 标签。

## HTTP 指标

FastAPI 服务至少记录：

- 请求总数，按 `operation_id`、route、HTTP status 和服务级 `code` 分类。
- 请求耗时，单位为毫秒或秒，名称必须体现单位。
- 请求校验失败数。
- 未知异常数。
- 外部调用失败导致的响应数。

健康检查、metrics、OpenAPI、静态文件和下载流可以单独标记或排除业务指标，但排除规则必须明确，避免影响错误率判断。

## Job 指标

启用异步 Job 时至少记录：

- 当前 queued / running / terminal Job 数量或可计算视图。
- Job 创建数，按 `job_type` 分类。
- Job 成功、失败、超时、恢复数，按 `job_type` 和错误分类。
- Job 排队时间和执行时间。
- stale running 数量。
- recovery 扫描次数、补偿次数和冲突次数。
- callback pending / retrying / delivered / failed 数量。
- callback 投递耗时和失败分类。

Job 指标必须以持久化状态或生命周期事件为事实源。不得从执行器 result backend、Pod 数量或日志 grep 临时推导业务状态作为权威指标。

## AI 指标

AI 能力服务至少记录：

- provider 调用次数、成功数、失败数、超时数和限流数。
- provider latency。
- 输入 token、输出 token、估算成本；无法获得精确值时记录估算字段并标明来源。
- 模型输出 schema 校验成功 / 失败数。
- bounded repair 尝试数、成功数、失败数；未启用时不记录假成功。
- 超预算、超大小、队列满和生产 opt-in 拒绝次数。

AI 指标不得包含完整 Prompt、完整输入、完整输出、供应商原始响应、密钥、token 或隐私文本。

## Artifact 指标

启用 artifact 存储时至少记录：

- artifact 写入成功 / 失败数。
- artifact 大小分布。
- artifact 读取或下载引用生成次数。
- artifact 过期清理数和失败数。

不要把 artifact key、文件名、用户文本 hash 以外的敏感定位信息放入标签。需要定位具体 artifact 时，通过日志、JobView 引用或 Typer 输出查看。

## 验收要求

Metrics 规则至少通过以下检查落地：

- 指标名称和单位稳定。
- 高基数字段不进入标签。
- HTTP、Job、AI provider、callback 和 artifact 的最小指标存在；未启用能力有明确声明。
- 合成请求或测试 Job 能产生预期指标。
- metrics endpoint 或平台采集不暴露密钥、Prompt、完整输入、完整输出或供应商响应。
