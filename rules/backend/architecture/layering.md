---
description: 后端服务龙骨、分层架构与目录边界规则
---

# 后端分层架构规则

后端服务起盘时，先建立服务龙骨，再按复杂度分层。分层规则负责稳定职责边界和调用方向，不负责具体启动命令、配置注入方式或框架 API。

## 服务龙骨

每个新服务必须先回答以下问题，并在 README、架构说明或项目入口文档中留下最小产物：

| 龙骨项 | 必须回答的问题 | 最小产物 | 后续事实源 |
| --- | --- | --- | --- |
| 服务定位 | 这个服务解决什么，不解决什么 | 定位说明和不做清单 | 本文 |
| 能力边界 | 对外提供哪些能力，调用方是谁 | 能力清单 | 本文 |
| 接口入口 | 调用方如何进入能力 | API、CLI、文件或内部函数入口 | `../contracts/service-contract.md`、框架或 API 文档 |
| 配置入口 | 配置从哪里来，默认值如何覆盖 | 配置来源说明 | `../deployment/service-deployment.md`、框架配置规则 |
| 运行入口 | 本地、容器、依赖服务如何启动 | 命令或脚本 | `../entrypoints/project-entrypoints.md`、部署规则 |
| 验证入口 | 如何证明主路径成立 | 测试、curl、冒烟脚本或验收命令 | 入口规则、部署规则、框架可观测规则 |
| 文档入口 | 后续从哪里理解和维护 | README、API、部署或架构文档 | 项目 README |

服务无法说清定位、入口、配置、运行和验证方式时，不应先讨论数据库、队列或复杂目录结构。

当服务明确需要 FastAPI、异步 Job、Typer、数据库和 AI 集成共同演进时，应读取 [`project-skeleton.md`](project-skeleton.md)，先固定 API、schema、service、repository、job、workflow、integration 和 CLI 的落点，再实现具体能力。

## 分层规则

按复杂度渐进分层：

| 服务形态 | 合适分层 | 判断重点 |
| --- | --- | --- |
| 轻量服务 | 入口、配置、核心逻辑、验证脚本 | 不让逻辑全部堆进单文件，但不强拆过多层 |
| 中型后端 | API、schemas、services、repositories、db、core、tasks | API 不写业务，Service 不感知 HTTP，Repository 封装数据访问 |
| 完整平台 | frontend、backend、pipeline、infrastructure、models、schemas | 前后端、任务、外部服务和共享基础设施边界清楚 |

调用方向必须稳定：

```text
API -> Service -> Repository -> DB / Infrastructure
Tasks -> Service -> Repository -> DB / Infrastructure
Service -> Infrastructure clients
```

禁止反向依赖：

- Repository 不调用 API 层或任务层。
- Service 不直接读取 HTTP request、response、headers。
- API 层不直接写 SQL、不编排复杂业务流程。
- ORM 对象不应泄漏为对外响应契约；对外输入输出骨架由 `../contracts/service-contract.md` 定义。

## Repository 与数据访问

当出现以下任一信号时，应引入 Repository 或等价数据访问边界：

- Service 层开始直接拼 SQL 或散落 ORM 查询。
- 同一数据模型被多个 Service 重复读写。
- 需要事务边界、审计字段、历史记录或复杂查询。
- 测试需要替换数据访问实现。

Repository 只负责数据读写和查询表达，不负责业务判断。事务边界应在 Service 或明确的 Unit of Work 层集中管理。

## 迁移边界

数据库字段会长期演进时，必须引入迁移机制。架构规则只判断是否需要迁移边界；数据库配置、连接生命周期、Repository / Unit of Work、迁移细节、Job 持久化事实源、CAS 状态迁移和索引规则由 `../persistence/database.md` 负责；迁移在部署链路中的执行和验证由部署规则负责。

使用 Alembic 等迁移工具时：

- 代码模型、迁移文件和部署流程必须同步维护。
- 新环境首次部署必须运行迁移，不能假设表已存在。
- 迁移失败必须阻止服务继续发布或启动，不要静默跳过。
- API、Worker、定时任务共享同一数据库模型时，迁移必须先于依赖它的进程启动。

## 反模式

- 轻量服务一开始套完整 DDD、聚合根和领域事件。
- 中型服务继续把所有逻辑堆在 `main.py`。
- API 层直接操作数据库并返回 ORM 对象。
- 在架构说明里复制脚本命令、部署变量或框架教程。
- 为了“以后可能用到”提前加入 DB、队列、缓存、前端和复杂部署。
