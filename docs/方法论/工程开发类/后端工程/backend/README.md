---
description: 后端工程规则索引与职责边界
---

# 后端工程规则

本目录维护可复制到新项目的后端工程规则。规则回答“必须怎么做、边界在哪里、如何验收”，不承载完整方法论、教程或项目排障案例。

## 规则分层

后端规则按“通用骨架 -> 服务契约 -> 工程入口 -> 持久化 -> 异步任务 -> 部署形态 -> 集成边界 -> AI 能力 -> 框架专项”加载。上层规则只定义职责和事实源，不重复维护下层实现细则。规则间引用必须保持单向依赖：引用方向只能沿加载顺序指向下层或指向对应事实源，禁止两个规则互相引用来共同定义同一主题。

| 层级 | 事实源 | 负责 | 不负责 |
| --- | --- | --- | --- |
| 服务结构 | `architecture/layering.md` | 服务定位、分层方向、调用边界、数据访问边界 | 具体启动命令、部署变量、框架 API |
| 项目骨架 | `architecture/project-skeleton.md` | FastAPI、Job、Typer、数据库和 AI 服务的目录落点与接入边界 | 具体业务实现、框架 API、部署变量 |
| AI MVP 基线 | `architecture/ai-service-mvp-baseline.md` | FastAPI + Job + Typer + AI 能力服务的最小模块、真源、接口、进程和验证清单 | 具体业务实现、框架 API、执行器 API |
| 服务契约 | `contracts/service-contract.md` | HTTP envelope、输入输出骨架、错误码分层、异常转换、Job/Callback 对外契约、结构化日志主字段和时间格式 | 具体框架 API、执行器 API、业务字段和供应商协议 |
| Schema 复用 | `contracts/schema-composition.md` | envelope、ErrorDetail、JobView、CallbackEnvelope 与业务 schema 的组合复用 | 具体业务字段、具体 Pydantic 写法细节 |
| 注册表真源 | `contracts/registry-source.md` | 错误码、operation、schema version 和 `job_type` registry 的可检查事实源 | 业务字段含义、执行器 API、OpenAPI 样式 |
| 接口模板 | `contracts/api-operation-template.md` | 新接口文档字段表、必选/可选、类型、约束、示例、错误码和验收 | 具体业务字段定义 |
| 操作入口 | `entrypoints/project-entrypoints.md` | 开发者和 Agent 看到的本地开发、启动、停止、验证入口契约 | 脚本目录拓扑和部署平台流程 |
| 脚本拓扑 | `entrypoints/script-topology.md` | 脚本数量增长后的门面脚本、原子脚本、公共函数拆分 | 具体业务验证逻辑和发布平台说明 |
| 脚本输出 | `entrypoints/script-output.md` | 脚本面向人的可视化输出、状态词、中英文边界、失败提示、工具输出透传和脱敏规则 | 具体脚本业务逻辑、应用结构化日志和机器输出协议 |
| 运行时排障 | `entrypoints/runtime-troubleshooting.md` | Pod、容器或远端运行环境中的只读诊断脚本契约 | K8s 平台点击手册、Job 状态机、修复 runbook |
| 持久化 | `persistence/database.md` | 数据库配置、Repository、Unit of Work、迁移、Job 持久化事实源和 CAS 状态迁移 | HTTP envelope、Job 公开状态机、具体 ORM 教程 |
| 异步 Job | `jobs/` | Job 生命周期、状态机、投递、恢复、运行时快照和 workflow 执行语义 | Celery / Taskiq API、FastAPI route、Typer 命令实现、服务级 envelope |
| 复杂 Job | `jobs/complex-workflow.md` | 复杂 Job 内部执行计划、work item、finalize、Celery Canvas / Taskiq 编排映射边界 | 公开 Job 状态机、执行器 API 教程、业务 handler 实现 |
| Job 执行器 | `jobs/executors/` | Celery、Taskiq 等执行器如何映射通用 Job 规则 | 通用 Job 状态机、业务 handler、HTTP 或 CLI 接入 |
| Typer CLI | `typer/` | Python CLI 命令结构、运行时排障输出、退出码、只读排障和受控管理入口 | Job 生命周期、FastAPI route、Shell 脚本拓扑 |
| 部署形态 | `deployment/service-deployment.md` | 配置注入、运行形态、健康检查、部署后验证 | 应用 Settings schema、业务参数派生、平台点击手册 |
| CI 镜像 | `deployment/ci-dockerfile.md` | 固定 GitLab CI 模板下的 Dockerfile / Dockerfile_OS 职责 | 本地开发容器和非该模板的发布链路 |
| 外部集成 | `integrations/external-service.md` | 外部 client、协议适配、写入副作用、环境保护 | 具体供应商 API、框架日志实现、Job 状态机 |
| Artifact 存储 | `integrations/artifact-storage.md` | 大文本、大 JSON、模型中间产物和可下载文件的引用、hash、权限、过期和清理 | 对象存储 SDK、平台权限点击手册 |
| AI 能力 | `ai/capability-service.md` | Provider adapter、Prompt、结构化输出、结果校验、成本和容量保护 | HTTP envelope、通用 Job 状态机、具体供应商教程 |
| FastAPI 专项 | `fastapi/` | FastAPI 配置、安全、日志、metrics、HTTP 接口和 Job 接入适配 | 通用 Job 生命周期、执行器语义、非 FastAPI 通用规则 |

## 使用方式

新建后端服务时，先读取通用规则，再按技术栈和能力加载专项规则：

1. `architecture/layering.md`：确定服务龙骨、分层和目录边界。
2. `architecture/project-skeleton.md`：当服务同时包含 FastAPI、异步 Job、Typer、数据库和 AI 能力时确定稳定目录落点。
3. `architecture/ai-service-mvp-baseline.md`：当服务目标是 FastAPI + Job + Typer + AI 能力服务时确定 MVP 最小交付清单。
4. `contracts/service-contract.md`：确定 HTTP 输入输出、错误码、异常转换、Job/Callback 契约、日志主字段和时间格式。
5. `contracts/schema-composition.md`：确定 envelope、错误、JobView、CallbackEnvelope 和业务 schema 的复用方式。
6. `contracts/registry-source.md`：确定错误码、operation、schema version 和 `job_type` registry 的可检查真源。
7. `contracts/api-operation-template.md`：新增接口时确定字段说明、必选/可选、类型、约束、示例、错误码和验收。
8. `entrypoints/project-entrypoints.md`：确定本地开发、服务生命周期和操作入口。
9. `entrypoints/script-topology.md`：当脚本变多时确定门面脚本、子目录和公共函数边界。
10. `entrypoints/script-output.md`：当脚本需要对人输出检查、启动、状态、部署或排障结果时加载。
11. `entrypoints/runtime-troubleshooting.md`：当服务需要在 Pod、容器或远端环境中执行稳定只读排障命令时加载。
12. `persistence/database.md`：当服务需要数据库、Repository、迁移、Job 持久化事实源或 CAS 状态迁移时加载。
13. `jobs/async-job.md`：当服务需要异步 Job、Worker、状态查询或恢复机制时加载。
14. `jobs/workflow-handler.md`：当服务需要多个 `job_type`、可插拔 handler 或分片执行计划时加载。
15. `jobs/complex-workflow.md`：当单个 Job 内部需要分片、并行、merge、finalize 或执行器编排时加载。
16. `jobs/executors/celery.md` 或 `jobs/executors/taskiq.md`：按执行器选型加载。
17. `typer/ops-cli.md`：当 Python CLI 或运行时排障命令使用 Typer 时加载。
18. `typer/admin-cli.md`：当 Typer 需要创建 Job、重试、补偿、callback 重放或 canary 等写入动作时加载。
19. `deployment/service-deployment.md`：确定配置注入、部署形态和部署后验证。
20. `deployment/ci-dockerfile.md`：当项目使用固定 GitLab CI 镜像构建模板时加载。
21. `integrations/external-service.md`：当服务调用第三方或上游业务系统时加载。
22. `integrations/artifact-storage.md`：当服务交付大文本、大 JSON、模型中间产物或可下载文件时加载。
23. `ai/capability-service.md`：当服务调用模型供应商、Prompt 或结构化 AI 输出时加载。
24. `fastapi/`：当后端服务使用 FastAPI 时加载。

方法论负责判断何时引入规则；规则负责落地时必须遵守的工程契约。案例和扫盲文档不得反向成为规则真源。

## 收敛原则

- 同一主题只能有一个事实源；其他文档只能引用或声明接入点。
- 规则引用必须沿加载顺序从上层指向下层，或指向对应事实源；发现互相引用时，必须把共享边界上移到唯一事实源，或拆清各自负责的主题。
- FastAPI + Job + Typer + AI 能力服务的 MVP 最小模块、真源、接口、进程和验证清单以 `architecture/ai-service-mvp-baseline.md` 为收敛入口。
- HTTP envelope、错误码、异常转换、Job/Callback 对外骨架、时间格式和结构化日志主字段以 `contracts/service-contract.md` 为唯一事实源。
- envelope、ErrorDetail、JobView、CallbackEnvelope 和业务 schema 的组合复用以 `contracts/schema-composition.md` 为接入规则。
- 错误码、公开操作、schema version 和 `job_type` registry 以 `contracts/registry-source.md` 为可检查事实源。
- 新接口文档字段表和接入验收以 `contracts/api-operation-template.md` 为模板。
- 通用规则不写框架专属 API，框架规则不重写通用分层、入口和部署边界。
- 部署规则只描述配置如何进入运行环境；配置字段、校验和派生由框架或应用配置规则负责。
- 数据库状态权威、Repository、迁移和 CAS 持久化边界由 `persistence/database.md` 负责。
- Job 规则只描述状态机、投递、恢复和生命周期事件；外部写回协议由集成规则负责。
- 复杂 Job 仍以单个公开 Job 为基本处理单元；内部分片、并行、merge、finalize 和 Celery Canvas / Taskiq 编排映射由 `jobs/complex-workflow.md` 负责。
- AI 规则只描述模型供应商、Prompt、结构化输出和成本容量保护；服务级响应和 Job 状态仍引用契约与 Job 规则。
- 大产物和模型中间产物的公开引用、hash、权限、过期和清理由 `integrations/artifact-storage.md` 负责。
- 索引页只维护加载顺序和边界，不复制正文规则。
