---
description: FastAPI 异步 Job HTTP 接入、schema、依赖初始化与请求追踪规则
---

# FastAPI Job 接入规则

本规则只说明 FastAPI 服务如何接入通用异步 Job 系统。Job 生命周期、状态权威、投递、恢复、运行时快照和进程边界由 `../../jobs/async-job.md` 定义；HTTP envelope、错误码、异常转换和 Job/Callback 对外骨架由 `../../contracts/service-contract.md` 定义；Celery 或 Taskiq 的执行器细节由 `../../jobs/executors/` 下的专项规则定义。

FastAPI 规则不得重新定义 Job 状态机，也不得把 Celery、Taskiq 或其他执行器设为默认事实源。

## 适用边界

适用场景：

- FastAPI 服务需要通过 HTTP 创建异步 Job。
- 调用方需要查询 Job 状态、结果或 callback 投递状态。
- FastAPI API 进程需要完成请求校验、幂等识别、Job 入库和执行器投递。

不适用场景：

- 纯同步接口。
- 只有 Typer CLI 或内部 worker，没有 HTTP API。
- 执行器 worker 的 task 实现细节。

## HTTP 契约

FastAPI 服务的 Job HTTP 接口应映射通用 Job 契约：

- `POST /jobs` 创建任务，成功返回 `202 Accepted` 和 `job_id`。
- `GET /jobs/{job_id}` 查询状态和结果。
- 可选 callback 只作为补充通知，不替代轮询。
- 可选 `client_request_id` 用于请求级幂等。

HTTP 响应模型只能暴露通用 Job 规则允许的稳定字段。执行器 task id、broker 状态、worker 位置等过程信息默认不进入公开响应；如确实需要展示，应标记为诊断旁证。

FastAPI route 返回 Job 创建或查询结果时，业务响应必须套用服务 envelope。不要让不同 route 分别返回裸 Job 对象、裸错误对象或框架默认 validation error。

## Schema 边界

Pydantic schema 负责 HTTP 入参、公开响应和服务 envelope 的结构校验，是 `../../contracts/service-contract.md` 的 FastAPI 投影，不负责定义 Job 状态语义。

`CreateJobRequest` 顶层字段应保持少量稳定字段，例如 `client_request_id`、`job_type`、`job_params`、`callback`、`metadata`、`options`。具体业务参数由 `../../jobs/workflow-handler.md` 中的 handler 契约定义，FastAPI route 只调用已注册 handler 做校验和规范化。

`JobView` 必须来自 Job 持久化状态，不得直接读取执行器 result backend 作为业务结果事实源。

## 依赖与配置

FastAPI 进程启动时必须完成：

- Settings 初始化和启动校验，规则见 `../configuration/settings.md`。
- Job repository、执行器 publisher、handler registry 的依赖装配。
- 所选执行器规则的必要配置校验，例如 Celery 或 Taskiq broker、worker 和 timeout 映射。

配置错误必须阻止 FastAPI 进程启动。不要让 API 先监听、接单或投递消息，再在业务路径里发现 Job 配置不可用。

## API 进程边界

FastAPI route 只负责：

- 鉴权和请求校验。
- 规范化入参和生成运行时快照。
- 写入 Job 记录。
- 投递执行器消息。
- 返回可查询的 Job 视图。

FastAPI API 进程不得执行长任务正文，不得在请求处理中发送终态 callback 或第三方写回。终态副作用由通用 Job 和外部集成规则约束。

## 可观测性

FastAPI Job 接口必须接入请求追踪和结构化日志，规则见 `../observability/logging.md`。

日志可以记录 `request_id`、`trace_id`、`job_id`、`job_type`、状态迁移事件和错误分类。不要记录密钥、完整请求体、隐私文本、完整供应商响应或大文件内容。

运行时排障脚本可以查询 FastAPI 请求追踪信号，但 Job 状态字段必须读取 `../../jobs/async-job.md`，多 `job_type` 字段必须读取 `../../jobs/workflow-handler.md`。
