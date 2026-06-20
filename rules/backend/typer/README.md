---
description: Typer CLI 规则索引
---

# Typer CLI 规则

本目录维护后端 Python CLI 的 Typer 接入规则。Typer 只负责命令组织、参数、输出格式和退出码，不定义 Job 生命周期、运行时排障事实源或部署平台流程。

## 子树边界

| 文件 | 负责 | 不负责 |
| --- | --- | --- |
| `ops-cli.md` | Typer 运行时排障 CLI 的命令结构、只读边界、输出和退出码 | Job 状态机、FastAPI route、部署平台进入方式 |

## 加载顺序

当项目需要 Python 运行时排障 CLI 时，先读取 `../entrypoints/runtime-troubleshooting.md`，再读取 `ops-cli.md`。如果 CLI 展示异步 Job 信息，还必须读取 `../jobs/async-job.md` 和按需读取 `../jobs/workflow-handler.md`。如果 CLI 展示 DB-backed Job、timeline、事件表或审计证据，还必须读取 `../persistence/database.md`。
