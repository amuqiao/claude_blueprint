---
description: FastAPI 日志、请求追踪、业务摘要与排障信号规则
---

# FastAPI 可观测规则

FastAPI 服务必须从第一天建立最小可观测性，让本地、容器和 K8s 环境都能直接排查问题。可观测规则定义 FastAPI 如何接入可观测信号；服务级结构化日志主字段、错误码字段和输入输出 envelope 由 `../../contracts/service-contract.md` 负责。部署后是否通过验收由 `../../deployment/service-deployment.md` 负责。

## 日志出口

服务日志必须输出到 stdout/stderr，供容器运行时、K8s 或平台采集。不要只写本地文件，也不要依赖 Uvicorn 默认日志表达业务状态。

日志至少区分：

- 应用启动和配置加载。
- 请求进入和响应完成。
- 业务关键阶段。
- 外部依赖调用。
- 异常和失败分类。

## 请求追踪

每个请求应有 `request_id`。如果上游已传入可信 request id，可沿用；否则服务生成。

日志中应能通过 `request_id` 串起：

- 请求方法和路径。
- 响应状态码。
- 耗时。
- 调用方摘要。
- 业务任务 id 或 job id。

结构化日志字段必须与 `../../contracts/service-contract.md` 保持一致。FastAPI middleware 或 exception handler 只负责写入这些字段，不另行定义字段含义。

## 业务摘要

业务日志记录“发生了什么”，不要记录完整敏感输入。推荐记录：

- 输入规模、类型、条数。
- 外部服务名称和耗时。
- 任务状态变化。
- 失败分类和可排查原因。

禁止默认记录完整请求体、完整响应体、密钥、token、身份证明、隐私文本或大文件内容。

## 异常处理

异常必须同时满足：

- 对调用方返回稳定错误结构。
- 日志中保留 request_id 和失败分类。
- 不吞掉异常。
- 不把内部堆栈、密钥、供应商响应原文暴露给外部调用方。

稳定错误结构指 `../../contracts/service-contract.md` 定义的 `code/msg/data/request_id/server_time` envelope 和错误码分层。FastAPI 的全局 exception handler 应集中完成异常转换。

## 排障信号

每个 FastAPI 服务至少应暴露以下排障信号：

- `/health` 或等价健康检查。
- `/docs` 或 `/openapi.json`，其接口描述应是服务契约的框架投影。
- 应用日志。
- 容器或 Pod 状态可关联到服务名。
- 关键业务接口的冒烟请求。

入口脚本可以展示这些信号的地址，部署文档可以把这些信号纳入验收，但不要在多处复制 FastAPI 可观测规则正文。

Pod、容器或远端运行环境中的排障脚本只消费这些信号，不定义日志规则本身。运行时诊断命令、输出字段和只读边界见 `../../entrypoints/runtime-troubleshooting.md`。
