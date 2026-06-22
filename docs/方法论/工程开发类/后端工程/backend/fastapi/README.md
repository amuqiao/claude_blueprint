---
description: FastAPI 服务规则索引
---

# FastAPI 规则

本目录维护 FastAPI 服务可复用规则。通用后端分层、服务契约、入口、异步 Job、集成和部署规则仍从 `rules/backend/` 读取；本目录只维护 FastAPI 特有的配置、安全、日志、接口可观测和 HTTP 接入适配。

当 FastAPI 服务需要异步 Job 时，先读取 `../contracts/service-contract.md`、`../jobs/async-job.md` 和所选执行器规则，再读取本目录的 Job 接入规则。当服务需要在 Pod、容器或远端运行环境中提供排障脚本时，先读取 `../entrypoints/runtime-troubleshooting.md`，再按需读取本目录的可观测规则。

## 子树边界

| 文件 | 负责 | 不负责 |
| --- | --- | --- |
| `configuration/settings.md` | FastAPI / Pydantic Settings 的字段语义、派生配置和启动校验 | 部署环境变量来源和 Compose 覆盖顺序 |
| `security/access-boundary.md` | FastAPI 接口暴露面、凭证、授权、浏览器接入 | 外部服务 client 协议和第三方写入副作用 |
| `observability/logging.md` | FastAPI 请求追踪接入、日志出口、异常处理和排障信号 | 服务级 envelope、错误码分层和结构化日志主字段 |
| `observability/metrics.md` | FastAPI、异步 Job、AI provider、callback 和 artifact 的最小 metrics 面 | 具体采集平台、trace 实现、日志事件正文 |
| `jobs/async-job.md` | FastAPI Job HTTP 接口投影、Pydantic schema 接入、依赖初始化和请求追踪接入 | 通用 Job 状态机、服务级 envelope、投递、恢复、执行器语义 |
| `jobs/workflow-handler.md` | FastAPI handler registry、HTTP schema 投影和进程一致性 | 通用 `job_type`、执行计划、结果分层、服务级契约和执行器专项能力 |

## 子树加载顺序

进入 FastAPI 子树后，按实际能力加载：

1. `configuration/settings.md`
2. `security/access-boundary.md`
3. `observability/logging.md`
4. `observability/metrics.md`：当服务需要指标、告警、容量观察或 AI 成本观测时加载。
5. `jobs/async-job.md`：只有服务确实需要通过 FastAPI 暴露异步 Job HTTP 接口时加载。
6. `jobs/workflow-handler.md`：只有 FastAPI HTTP 接口需要接入多个 `job_type`、可插拔 workflow 或分片执行计划时加载。

不要把 Job 接入规则作为所有 FastAPI 服务的默认模板，也不要在 FastAPI 子树内重写通用后端分层、入口、异步 Job、部署和外部集成规则。
