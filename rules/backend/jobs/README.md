---
description: 后端异步 Job 通用规则索引与执行器边界
---

# 异步 Job 规则

本目录维护与 Web 框架和队列执行器无关的异步 Job 规则。Job 规则先定义生命周期、状态权威、投递、恢复、运行时快照和 workflow 执行语义；Celery、Taskiq、FastAPI 或 Typer 只能接入这些事实源，不反向定义 Job 语义。对调用方公开的输入输出和错误 envelope 由 `../contracts/service-contract.md` 定义。

## 子树边界

| 文件 | 负责 | 不负责 |
| --- | --- | --- |
| `async-job.md` | Job 生命周期、状态机、状态权威、投递、恢复、超时链路、运行时快照 | Celery / Taskiq API、FastAPI route、Typer 命令实现 |
| `workflow-handler.md` | 多 `job_type`、handler、执行计划、handler 内部结果分层、终态副作用挂点 | 基础 Job 状态机、执行器 API、Web 框架注册方式、服务级 envelope |
| `executors/celery.md` | Celery task、broker、worker、beat、time limit 如何映射通用 Job 规则 | 通用 Job 状态机和业务 handler 契约 |
| `executors/taskiq.md` | Taskiq task、broker、worker、scheduler 如何映射通用 Job 规则 | 通用 Job 状态机和业务 handler 契约 |

## 加载顺序

需要异步任务时，先加载通用规则，再选择执行器和接入框架：

1. `../contracts/service-contract.md`：当 Job 有公开创建、查询或 callback 接口时先读取。
2. `async-job.md`：所有异步 Job 服务必须读取。
3. `workflow-handler.md`：当服务需要多个 `job_type`、可插拔 handler 或分片执行计划时读取。
4. `executors/celery.md` 或 `executors/taskiq.md`：按项目选型读取一个执行器规则。
5. `../fastapi/jobs/async-job.md`：当 API 框架是 FastAPI 时读取。
6. `../typer/ops-cli.md`：当运行时排障或运维命令使用 Typer 时读取。

执行器可以替换，Job 生命周期事实源不能替换。项目从 Celery 切到 Taskiq 时，只替换执行器规则和实现映射，不重写状态机、投递、恢复或运行时快照。
