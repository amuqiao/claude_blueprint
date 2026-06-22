---
description: Typer 运行时排障 CLI 命令、输出与只读边界规则
---

# Typer 运行时排障 CLI 规则

Typer CLI 负责把 `../entrypoints/runtime-troubleshooting.md` 定义的运行时排障命令实现为稳定 Python CLI。它只消费服务契约、Job、可观测、部署和集成规则中的事实源，不重新定义业务状态、Job 生命周期、公开响应字段或修复流程。

## 命令边界

Python 项目的 `ops` 命令默认使用 Typer 实现。Shell `scripts/ops.sh` 可以作为门面，但不应在 shell 中复制 Typer 命令正文或业务查询逻辑。

Typer 命令默认只读，提供 `list`、`show`、`timeline`、`inspect`、`health`、`env`、`version` 等查询动作。重试、补偿、callback 重放、DB 修改和真实业务创建必须进入独立修复入口或 runbook。

## Job 命令

异步 Job 命令必须读取通用 Job 事实源：

- Job 状态、终态、投递和恢复语义：`../jobs/async-job.md`。
- `job_type`、执行计划、work item 和结果分层：`../jobs/workflow-handler.md`。
- 执行器旁证字段：按项目选型读取 `../jobs/executors/celery.md` 或 `../jobs/executors/taskiq.md`。

Typer 命令可以展示执行器 task id、broker 状态或 worker 信息，但这些字段只能标记为旁证，不得覆盖 Job 持久化状态。

## 输出与退出码

Typer CLI 应同时支持人读和机读输出，例如 `--format table` 与 `--format json`。JSON 字段必须稳定，便于 CI、AI 分析或运维平台消费；字段语义优先引用 `../contracts/service-contract.md` 和运行时排障规则，不在 Typer 文档里另行定义。

退出码应稳定：

| 场景 | 退出码 |
| --- | --- |
| 查询成功且证据完整 | `0` |
| 输入参数非法 | `2` |
| 查询对象不存在 | `3` |
| 依赖不可达或证据缺失 | `4` |
| 状态权威与旁证冲突 | `5` |

命令失败必须输出明确原因，不得在 DB、日志、trace、broker 或 K8s 信息不可达时静默返回空结果。

## 实现边界

Typer callback、依赖初始化和命令模块可以组织公共参数、配置加载和输出格式化，但业务查询应下沉到明确的 service 或 query 模块。不要让 Typer command 直接拼 SQL、调用外部写入接口或读取敏感配置原文。
