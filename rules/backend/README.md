---
description: 后端工程规则索引与职责边界
---

# 后端工程规则

本目录维护可复制到新项目的后端工程规则。规则回答“必须怎么做、边界在哪里、如何验收”，不承载完整方法论、教程或项目排障案例。

## 规则分层

后端规则按“通用骨架 -> 工程入口 -> 异步任务 -> 部署形态 -> 集成边界 -> 框架专项”加载。上层规则只定义职责和事实源，不重复维护下层实现细则。规则间引用必须保持单向依赖：引用方向只能沿加载顺序指向下层或指向对应事实源，禁止两个规则互相引用来共同定义同一主题。

| 层级 | 事实源 | 负责 | 不负责 |
| --- | --- | --- | --- |
| 服务结构 | `architecture/layering.md` | 服务定位、分层方向、调用边界、数据访问边界 | 具体启动命令、部署变量、框架 API |
| 操作入口 | `entrypoints/project-entrypoints.md` | 开发者和 Agent 看到的本地开发、启动、停止、验证入口契约 | 脚本目录拓扑和部署平台流程 |
| 脚本拓扑 | `entrypoints/script-topology.md` | 脚本数量增长后的门面脚本、原子脚本、公共函数拆分 | 具体业务验证逻辑和发布平台说明 |
| 运行时排障 | `entrypoints/runtime-troubleshooting.md` | Pod、容器或远端运行环境中的只读诊断脚本契约 | K8s 平台点击手册、Job 状态机、修复 runbook |
| 异步 Job | `jobs/` | Job 生命周期、状态机、投递、恢复、运行时快照和 workflow 契约 | Celery / Taskiq API、FastAPI route、Typer 命令实现 |
| Job 执行器 | `jobs/executors/` | Celery、Taskiq 等执行器如何映射通用 Job 规则 | 通用 Job 状态机、业务 handler、HTTP 或 CLI 接入 |
| Typer CLI | `typer/` | Python CLI 命令结构、运行时排障输出、退出码和只读边界接入 | Job 生命周期、FastAPI route、Shell 脚本拓扑 |
| 部署形态 | `deployment/service-deployment.md` | 配置注入、运行形态、健康检查、部署后验证 | 应用 Settings schema、业务参数派生、平台点击手册 |
| CI 镜像 | `deployment/ci-dockerfile.md` | 固定 GitLab CI 模板下的 Dockerfile / Dockerfile_OS 职责 | 本地开发容器和非该模板的发布链路 |
| 外部集成 | `integrations/external-service.md` | 外部 client、协议适配、写入副作用、环境保护 | 具体供应商 API、框架日志实现、Job 状态机 |
| FastAPI 专项 | `fastapi/` | FastAPI 配置、安全、日志、HTTP 接口和 Job 接入适配 | 通用 Job 生命周期、执行器语义、非 FastAPI 通用规则 |

## 使用方式

新建后端服务时，先读取通用规则，再按技术栈和能力加载专项规则：

1. `architecture/layering.md`：确定服务龙骨、分层和目录边界。
2. `entrypoints/project-entrypoints.md`：确定本地开发、服务生命周期和操作入口。
3. `entrypoints/script-topology.md`：当脚本变多时确定门面脚本、子目录和公共函数边界。
4. `entrypoints/runtime-troubleshooting.md`：当服务需要在 Pod、容器或远端环境中执行稳定只读排障命令时加载。
5. `jobs/async-job.md`：当服务需要异步 Job、Worker、状态查询或恢复机制时加载。
6. `jobs/workflow-handler.md`：当服务需要多个 `job_type`、可插拔 handler 或分片执行计划时加载。
7. `jobs/executors/celery.md` 或 `jobs/executors/taskiq.md`：按执行器选型加载。
8. `typer/ops-cli.md`：当 Python CLI 或运行时排障命令使用 Typer 时加载。
9. `deployment/service-deployment.md`：确定配置注入、部署形态和部署后验证。
10. `deployment/ci-dockerfile.md`：当项目使用固定 GitLab CI 镜像构建模板时加载。
11. `integrations/external-service.md`：当服务调用第三方或上游业务系统时加载。
12. `fastapi/`：当后端服务使用 FastAPI 时加载。

方法论负责判断何时引入规则；规则负责落地时必须遵守的工程契约。案例和扫盲文档不得反向成为规则真源。

## 收敛原则

- 同一主题只能有一个事实源；其他文档只能引用或声明接入点。
- 规则引用必须沿加载顺序从上层指向下层，或指向对应事实源；发现互相引用时，必须把共享边界上移到唯一事实源，或拆清各自负责的主题。
- 通用规则不写框架专属 API，框架规则不重写通用分层、入口和部署边界。
- 部署规则只描述配置如何进入运行环境；配置字段、校验和派生由框架或应用配置规则负责。
- Job 规则只描述状态机、投递和恢复；外部写回协议由集成规则负责。
- 索引页只维护加载顺序和边界，不复制正文规则。
