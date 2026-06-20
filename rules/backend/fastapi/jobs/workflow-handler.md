---
description: FastAPI Workflow Handler 注册、HTTP schema 接入与进程一致性规则
---

# FastAPI Workflow Handler 接入规则

本规则只说明 FastAPI 服务如何接入 `../../jobs/workflow-handler.md` 定义的通用 handler 契约。通用 `job_type`、执行计划、运行时字段、结果分层和副作用钩子不在 FastAPI 子树内重新定义。

## 适用边界

适用场景：

- FastAPI 的 `POST /jobs` 需要根据 `job_type` 选择不同 handler。
- 不同 `job_type` 有不同 Pydantic 入参、公开结果或 callback 策略。
- API 进程和 Worker 进程都需要读取同一份 handler registry。

不适用场景：

- 只有一个稳定同步接口。
- 只有一个简单后台任务，且没有扩展 `job_type` 的需求。
- 执行器专项能力，例如 Celery Canvas 或 Taskiq middleware。

## 注册边界

handler 注册必须有统一入口，例如 `register_all_workflows()` 或等价模块。FastAPI 进程启动时必须完成注册，并在处理请求前校验：

- `job_type` 唯一。
- 入参 schema 可序列化、可校验。
- `runtime_job_fields` 可 hash，且不包含密钥或大载荷。
- 公开结果 schema 和 callback 策略明确。

Worker 进程必须读取同一份 registry。FastAPI 不能维护一套只服务 HTTP 的 handler 列表，Worker 也不能维护另一套执行专用列表。

## HTTP 接入

FastAPI route 只做 handler 分发和 schema 适配：

```text
POST /jobs
  -> CreateJobRequest
  -> job_type
  -> handler registry
  -> params_schema validate
  -> runtime_job_fields
  -> generic Job create flow
```

具体业务入参位于 `job_params`，不要把所有 `job_type` 的字段摊平到顶层 HTTP schema。顶层字段只保留通用 Job envelope。

## OpenAPI 边界

如果需要向调用方展示多个 `job_type` 的入参，应明确生成方式：

- 简单项目可以在文档中列出每个 `job_type` 的 `job_params` schema。
- 复杂项目可以由 handler registry 生成 OpenAPI 补充说明或文档片段。

OpenAPI 展示不应成为 handler 契约事实源。handler 契约仍由通用 workflow 规则和项目 registry 定义。

## 排障与结果

FastAPI 可以在 JobView 中展示 `job_type`、执行计划摘要、结果引用和 callback 状态，但字段语义必须来自 `../../jobs/workflow-handler.md`。

运行时排障脚本可以读取 FastAPI route、request_id 和 trace_id；Job handler 字段仍由通用 Job 规则定义，Typer 或 shell 命令不得在排障层重新解释业务 handler。
