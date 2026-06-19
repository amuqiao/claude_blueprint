---
description: FastAPI 服务规则索引
---

# FastAPI 规则

本目录维护 FastAPI 服务可复用规则。通用后端分层、入口、集成和部署规则仍从 `rules/backend/` 读取；本目录只维护 FastAPI 特有的配置、安全、日志、接口可观测和任务契约。

## 子树边界

| 文件 | 负责 | 不负责 |
| --- | --- | --- |
| `configuration/settings.md` | FastAPI / Pydantic Settings 的字段语义、派生配置和启动校验 | 部署环境变量来源和 Compose 覆盖顺序 |
| `security/access-boundary.md` | FastAPI 接口暴露面、凭证、授权、浏览器接入 | 外部服务 client 协议和第三方写入副作用 |
| `observability/logging.md` | 请求追踪、日志摘要、异常输出和 FastAPI 排障信号 | 部署平台状态检查和脚本帮助文本 |
| `jobs/async-job.md` | 异步 Job 状态机、投递、恢复、Worker / Beat 拓扑 | 多 `job_type` handler 细节和外部 client 协议 |
| `jobs/workflow-handler.md` | 多 `job_type`、handler、执行计划、结果分层 | 基础 Job 状态权威、队列投递和恢复扫描 |

## 子树加载顺序

进入 FastAPI 子树后，按实际能力加载：

1. `configuration/settings.md`
2. `security/access-boundary.md`
3. `observability/logging.md`
4. `jobs/async-job.md`：只有服务确实需要异步任务时加载。
5. `jobs/workflow-handler.md`：只有服务需要多个 `job_type`、可插拔 workflow 或分片执行计划时加载。

不要把 Job 规则作为所有 FastAPI 服务的默认模板，也不要在 FastAPI 子树内重写通用后端分层、入口、部署和外部集成规则。
