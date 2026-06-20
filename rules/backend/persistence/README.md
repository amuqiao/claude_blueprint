---
description: 后端持久化规则索引
---

# 后端持久化规则

本目录维护数据库、Repository、迁移和持久化事实源规则。持久化规则负责“数据事实在哪里、如何安全读写、如何演进和验证”，不负责对外响应 envelope、Job 公开状态机或具体 ORM 教程。

## 子树边界

| 文件 | 负责 | 不负责 |
| --- | --- | --- |
| `database.md` | 数据库配置、连接生命周期、Repository、Unit of Work、迁移、Job 持久化事实源、CAS 状态迁移、索引和持久化验收 | HTTP envelope、Job 状态机、AI 输出 schema、部署平台操作手册 |

## 加载顺序

当服务需要数据库或持久化 Job 状态时，推荐顺序：

1. `../architecture/layering.md`：判断是否需要 Repository、事务和迁移边界。
2. `database.md`：确定数据库事实源、连接、迁移和持久化状态迁移规则。
3. `../jobs/async-job.md`：当持久化对象是异步 Job 时确定状态机、投递和恢复语义。
4. `../typer/ops-cli.md`：当 CLI 展示数据库证据、Job timeline 或审计信息时加载。
