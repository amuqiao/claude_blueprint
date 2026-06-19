---
description: 后端工程规则索引与职责边界
---

# 后端工程规则

本目录维护可复制到新项目的后端工程规则。规则回答“必须怎么做、边界在哪里、如何验收”，不承载完整方法论、教程或项目排障案例。

## 规则分层

后端规则按“通用骨架 -> 工程入口 -> 部署形态 -> 集成边界 -> 框架专项”加载。上层规则只定义职责和事实源，不重复维护下层实现细则。

| 层级 | 事实源 | 负责 | 不负责 |
| --- | --- | --- | --- |
| 服务结构 | `architecture/layering.md` | 服务定位、分层方向、调用边界、数据访问边界 | 具体启动命令、部署变量、框架 API |
| 操作入口 | `entrypoints/project-entrypoints.md` | 开发者和 Agent 看到的启动、停止、验证、排障契约 | 脚本目录拓扑和部署平台流程 |
| 脚本拓扑 | `entrypoints/script-topology.md` | 脚本数量增长后的门面脚本、原子脚本、公共函数拆分 | 具体业务验证逻辑和发布平台说明 |
| 部署形态 | `deployment/service-deployment.md` | 配置注入、运行形态、健康检查、部署后验证 | 应用 Settings schema、业务参数派生、平台点击手册 |
| CI 镜像 | `deployment/ci-dockerfile.md` | 固定 GitLab CI 模板下的 Dockerfile / Dockerfile_OS 职责 | 本地开发容器和非该模板的发布链路 |
| 外部集成 | `integrations/external-service.md` | 外部 client、协议适配、写入副作用、环境保护 | 具体供应商 API、框架日志实现、Job 状态机 |
| FastAPI 专项 | `fastapi/` | FastAPI 配置、安全、日志、异步 Job 和 workflow 契约 | 非 FastAPI 框架通用规则 |

## 使用方式

新建后端服务时，先读取通用规则，再按技术栈和能力加载专项规则：

1. `architecture/layering.md`：确定服务龙骨、分层和目录边界。
2. `entrypoints/project-entrypoints.md`：确定本地开发、服务生命周期和操作入口。
3. `entrypoints/script-topology.md`：当脚本变多时确定门面脚本、子目录和公共函数边界。
4. `deployment/service-deployment.md`：确定配置注入、部署形态和部署后验证。
5. `deployment/ci-dockerfile.md`：当项目使用固定 GitLab CI 镜像构建模板时加载。
6. `integrations/external-service.md`：当服务调用第三方或上游业务系统时加载。
7. `fastapi/`：当后端服务使用 FastAPI 时加载。

方法论负责判断何时引入规则；规则负责落地时必须遵守的工程契约。案例和扫盲文档不得反向成为规则真源。

## 收敛原则

- 同一主题只能有一个事实源；其他文档只能引用或声明接入点。
- 通用规则不写框架专属 API，框架规则不重写通用分层、入口和部署边界。
- 部署规则只描述配置如何进入运行环境；配置字段、校验和派生由框架或应用配置规则负责。
- Job 规则只描述状态机、投递和恢复；外部写回协议由集成规则负责。
- 索引页只维护加载顺序和边界，不复制正文规则。
