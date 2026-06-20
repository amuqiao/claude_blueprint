# 后端工程方法论

> 本目录存放后端服务起盘、FastAPI 服务架构、项目入口、部署发布和运行治理相关的方法论。可复用的落地规则统一维护在 [`../../../../rules/backend/`](../../../../rules/backend/)。

## 方法论与规则边界

后端工程知识分三层维护：

| 层级 | 职责 | 维护位置 |
| --- | --- | --- |
| 方法论 | 判断何时引入某类能力，以及能力之间如何装配 | 本目录 |
| 规则 | 约束新项目实际怎么分层、配置、部署、鉴权、记录日志和实现任务 | [`../../../../rules/backend/`](../../../../rules/backend/) |
| 案例 / 手册 | 记录具体项目排障过程、平台操作说明和扫盲材料 | 本目录下对应文档，后续可迁入案例目录 |

方法论不要重复维护规则正文。规则一旦提取，方法论文档只保留判断模型、适用边界和到规则真源的链接。

## 文档分类

### 服务起盘

- [`新服务架构龙骨与能力装配方法论.md`](新服务架构龙骨与能力装配方法论.md)
  用于从 0-1 构建新服务时，先建立服务龙骨，再按需求触发接口、任务、数据、缓存、存储、前端、安全、部署等能力积木，并判断它们的架构权重和装配顺序。规则真源见 [`rules/backend/architecture/layering.md`](../../../../rules/backend/architecture/layering.md)。

### FastAPI 服务

- [`FastAPI独立服务接口与任务架构方法论.md`](FastAPI独立服务接口与任务架构方法论.md)
  用于指导小型 FastAPI 独立服务在同步请求、同步 batch、异步任务、任务队列和工作流升级之间建立稳定架构判断。异步 Job 通用规则真源见 [`rules/backend/jobs/async-job.md`](../../../../rules/backend/jobs/async-job.md)，FastAPI HTTP 接入规则见 [`rules/backend/fastapi/jobs/async-job.md`](../../../../rules/backend/fastapi/jobs/async-job.md)。

- [`FastAPI服务鉴权与接入边界方法论.md`](FastAPI服务鉴权与接入边界方法论.md)
  用于指导轻量 FastAPI 服务判断接口暴露面、服务角色与状态属性、调用主体、有无用户系统、凭证模式、密钥与会话生命周期、授权限流、CORS/CSRF、HTTPS、身份透传、长连接、文件产物、审计日志、失败可观测和阶段演进边界。规则真源见 [`rules/backend/fastapi/security/access-boundary.md`](../../../../rules/backend/fastapi/security/access-boundary.md)。

- [`FastAPI服务运行日志与排障可观测性方法论.md`](FastAPI服务运行日志与排障可观测性方法论.md)
  用于指导 FastAPI 服务建立轻量统一日志模块、请求追踪、业务摘要和敏感信息边界，让容器或 K8s 部署后能直接采集和排查。规则真源见 [`rules/backend/fastapi/observability/logging.md`](../../../../rules/backend/fastapi/observability/logging.md) 和 [`rules/backend/fastapi/configuration/settings.md`](../../../../rules/backend/fastapi/configuration/settings.md)。

### 项目入口与部署

- [`项目开发入口设计方法论.md`](项目开发入口设计方法论.md)
  用于判断一个项目是否需要统一开发入口，以及入口应采用文档、脚本、包管理命令、任务运行器还是服务管理脚本。规则真源见 [`rules/backend/entrypoints/project-entrypoints.md`](../../../../rules/backend/entrypoints/project-entrypoints.md)。

- [`项目部署入口与配置加载方法论.md`](项目部署入口与配置加载方法论.md)
  用于统一项目的本地开发、Dockerfile 独立、docker compose 全量和 docker compose 依赖部署，并切清服务边界、配置加载和验证入口。规则真源见 [`rules/backend/deployment/service-deployment.md`](../../../../rules/backend/deployment/service-deployment.md)。

- [`项目部署文档与发布手册方法论.md`](项目部署文档与发布手册方法论.md)
  用于把已经稳定的部署路径沉淀为可查、可复制、可维护的项目级部署文档和发布手册。部署规则真源见 [`rules/backend/deployment/service-deployment.md`](../../../../rules/backend/deployment/service-deployment.md)。

- [`环境发布脚本构建方法论.md`](环境发布脚本构建方法论.md)
  用于把高风险、可重复的环境发布流程沉淀为安全、可检查、可回退、可复制到其他项目的脚本入口。入口规则真源见 [`rules/backend/entrypoints/project-entrypoints.md`](../../../../rules/backend/entrypoints/project-entrypoints.md)。

### 规范与案例

- [`FastAPI/async-job-spec.md`](FastAPI/async-job-spec.md)
  保留为 FastAPI + Celery AI 异步 Job 系统长版规范和参考实现说明；通用短规则真源维护在 [`rules/backend/jobs/async-job.md`](../../../../rules/backend/jobs/async-job.md)，Celery 映射规则维护在 [`rules/backend/jobs/executors/celery.md`](../../../../rules/backend/jobs/executors/celery.md)。

- [`FastAPI/deploy/ci-dockerfile-config-standard.md`](FastAPI/deploy/ci-dockerfile-config-standard.md)
  保留为 CI 与 Dockerfile 长版规范；test/master 发布链路的短规则真源维护在 [`rules/backend/deployment/ci-dockerfile.md`](../../../../rules/backend/deployment/ci-dockerfile.md)，不约束本地 dev Dockerfile。

- [`FastAPI/deploy/k8s-deployment-beginner-guide.md`](FastAPI/deploy/k8s-deployment-beginner-guide.md)
  保留为 K8s 使用与维护扫盲手册，不作为规则真源。

- [`FastAPI/deploy/postgresql-k8s-first-deploy-issues.md`](FastAPI/deploy/postgresql-k8s-first-deploy-issues.md)
  保留为 PostgreSQL 首次部署排障案例；其中“新环境必须运行迁移”和“数据库 SSL 配置必须显式表达”已归入部署和配置规则。

## 新服务方法论挂载关系

本表只维护 [`新服务架构龙骨与能力装配方法论.md`](新服务架构龙骨与能力装配方法论.md) 和其他后端工程方法论之间的挂载关系。

状态说明：

```text
内置：由新服务架构龙骨与能力装配方法论直接处理，不需要单独方法论
已有：已有正式方法论，可以在对应场景中引用
占位：值得沉淀，但暂未形成正式方法论文档
```

| 主干节点 / 能力积木 | 状态 | 推荐方法论 | 说明 |
| --- | --- | --- | --- |
| 服务龙骨 | 内置 | [`新服务架构龙骨与能力装配方法论.md`](新服务架构龙骨与能力装配方法论.md) | 服务定位、能力边界、接口入口、配置入口、运行入口、验证入口和文档入口由主文档处理 |
| 触发条件 | 内置 | [`新服务架构龙骨与能力装配方法论.md`](新服务架构龙骨与能力装配方法论.md) | 判断哪些需求信号触发能力积木 |
| 架构权重 | 内置 | [`新服务架构龙骨与能力装配方法论.md`](新服务架构龙骨与能力装配方法论.md) | 判断能力是骨架级、结构级还是增强级 |
| 装配顺序 | 内置 | [`新服务架构龙骨与能力装配方法论.md`](新服务架构龙骨与能力装配方法论.md) | 判断能力积木接入服务龙骨的先后关系 |
| 接口任务 | 已有 | [`FastAPI独立服务接口与任务架构方法论.md`](FastAPI独立服务接口与任务架构方法论.md) | 处理 sync、batch、job、job_id、状态查询、结果查询和队列升级边界 |
| 运行日志与排障 | 已有 | [`FastAPI服务运行日志与排障可观测性方法论.md`](FastAPI服务运行日志与排障可观测性方法论.md) | 处理 stdout/stderr、统一 logging、request_id、中间件请求日志、业务摘要和敏感信息边界 |
| 技术栈开发手册 | 已有 | [`../技术栈开发手册成型方法论.md`](../技术栈开发手册成型方法论.md) | 处理认知模型、架构模型、技术选型、工程规范和 AI 实现协议 |
| 开发入口 | 已有 | [`项目开发入口设计方法论.md`](项目开发入口设计方法论.md) | 处理启动、验证、生成、清理、构建和命令契约 |
| 部署配置 | 已有 | [`项目部署入口与配置加载方法论.md`](项目部署入口与配置加载方法论.md) | 处理本地开发、Dockerfile、docker compose、env 加载和验证入口 |
| 发布手册 | 已有 | [`项目部署文档与发布手册方法论.md`](项目部署文档与发布手册方法论.md) | 部署路径稳定后，用于沉淀发布、维护、排障和速查入口 |
| 发布脚本 | 已有 | [`环境发布脚本构建方法论.md`](环境发布脚本构建方法论.md) | 处理测试或预发环境的发布脚本入口、工作区隔离、风险文件保护、状态判断和失败恢复 |
| 后端分层与数据访问 | 占位 | 后端分层与数据访问方法论 | 适合沉淀 API、Service、Repository、DB、ORM 边界和 Alembic 迁移 |
| 前后端接口契约 | 占位 | 前后端接口契约方法论 | 适合沉淀 API 路径、请求响应、错误结构、状态同步和类型边界 |
| 任务队列与工作流 | 占位 | 任务队列与工作流方法论 | 适合沉淀通用 Job / workflow 契约、步骤状态、进度感知、重试和执行器映射 |
| 文件存储与产物生命周期 | 占位 | 文件存储与产物生命周期方法论 | 适合沉淀上传、输出文件、路径、下载、清理和部署挂载 |
| API 认证鉴权与限流 | 已有 | [`FastAPI服务鉴权与接入边界方法论.md`](FastAPI服务鉴权与接入边界方法论.md) | 适合沉淀 X-API-Key、JWT、限流、防滥用、CORS、HTTPS 和对外接入边界 |
| 项目文档骨架治理 | 占位 | 项目文档骨架治理方法论 | 适合沉淀 README、架构、接口、部署、实施清单和复盘之间的职责边界 |

## 维护边界

后端工程方法论负责服务起盘、接口与任务架构、运行日志与排障、项目入口、部署配置、发布手册和发布脚本等后端工程问题。

本层 README 维护后端工程目录内部索引、规则真源挂载关系和新服务能力挂载关系。新增、迁移或归档后端工程文档时，应同步更新本 README；上级 `工程开发类/README.md` 只保留到本目录的入口。

规则维护原则：

- 可直接复制到新项目执行的约束，放入 `rules/backend/`。
- 解释“为什么这样判断”的内容，留在方法论文档。
- 具体项目排障、截图说明、平台操作扫盲，保留为案例或手册，不进入规则真源。
- 同一条规则只维护一次；方法论和案例只能链接规则，不重复改写规则正文。

Flutter 项目开发主干方法论属于客户端工程方法论，不作为新服务架构龙骨的挂载范式；当项目对象是 Flutter 客户端应用或 Flutter 子工程时，应使用 [`../客户端工程/README.md`](../客户端工程/README.md)。
