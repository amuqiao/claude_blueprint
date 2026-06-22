---
description: 后端服务部署形态、.env 配置真源与部署验证规则
---

# 服务部署规则

部署规则负责统一服务在不同运行形态下如何读取 `.env`、如何启动、如何被验证。它不替代平台操作手册、发布流程脚本，也不定义应用内部 Settings schema、配置字段合法性或派生关系。

## 部署形态

每个项目必须明确当前支持的部署形态：

| 形态 | 说明 | 配置入口 |
| --- | --- | --- |
| 本地开发 | 只启动应用或依赖最小外部服务 | 项目 `.env` |
| Dockerfile 独立 | 单服务容器构建与运行 | 从 `.env` 生成的 env file 或显式环境变量 |
| Compose 依赖 | 应用连接本地 DB、Redis 等依赖 | Compose 使用项目 `.env` 和 `env_file` 注入 |
| K8s / 云平台 | 由平台注入配置、托管容器和健康检查 | 由 `.env` 语义生成或同步的 Secret / ConfigMap |

不要让同一套文档同时暗示多种部署形态，却不说明 `.env` 来源、启动入口和验证方式。

## `.env` 真源

`.env` 是项目应用配置的唯一语义真源。系统环境变量、Compose `environment`、K8s Secret / ConfigMap、平台参数和部署脚本参数只是运行时注入或覆盖通道，不是第二套配置语义。

必须遵守：

- `.env.example` 定义应用配置键集合和语义模板。
- 项目 `.env`、测试 env、生产 env 和密钥模板必须沿用同一组应用配置键。
- 系统环境变量可以在进程启动前覆盖 `.env` 中的同名键，但不得引入另一套命名或另一套业务语义。
- Compose、Docker、K8s 或云平台注入的应用配置必须来自同一套 `.env` 语义。
- 部署专用变量可以存在，例如宿主机端口、env file 路径、容器内路径，但必须和应用 Settings 字段分开列入允许清单。

应用配置字段、派生配置、未知键处理、废弃键处理和启动校验由对应框架或应用配置规则负责，例如 FastAPI 服务读取 `../fastapi/configuration/settings.md`。

## 覆盖顺序

部署文档必须把“配置语义真源”和“运行时覆盖顺序”分开说明。`.env` 是真源；更高优先级的环境变量只是在 `.env` 之前生效的覆盖入口。

推荐覆盖顺序：

```text
进程启动时显式传入的环境变量
  > 部署脚本显式选择的 env file
  > 项目 .env
```


## Compose 边界

Compose 部署必须复用 `.env` 语义，不维护第二套业务配置。

Compose 文件解析阶段可以读取项目 `.env` 处理 `${VAR:-default}`、端口映射和 `env_file` 路径：

```text
shell / 部署脚本显式传入的环境变量
  > Compose 项目目录的 .env
  > docker-compose.yml 中的 ${VAR:-default}
```

容器运行时阶段用于把同一套应用配置注入进程：

```text
运行时显式环境变量
  > docker-compose.yml environment 中的部署形态覆盖
  > ENV_FILE 指定的 env 文件
  > 项目 .env
```

`docker-compose.yml environment` 只能维护部署形态覆盖：

- 宿主机暴露端口，例如 `${API_HOST_PORT:-8100}`。
- Compose 网络内服务地址，例如 `postgres:5432`、`redis:6379`。
- 容器内路径，例如 `/app/storage/objects`。
- Compose 专用控制变量，例如 `${ENV_FILE:-.env}`、`${POSTGRES_DB:-app}`。

业务配置、密钥、模型参数、限流参数、租户参数不应硬编码在 `docker-compose.yml environment`。这些值应来自项目 `.env`、被显式选择的 env file，或由同一套 `.env` 语义生成的部署密钥。

当 `docker-compose.yml environment` 与 `env_file` 存在同名变量时，必须把 `docker-compose.yml environment` 视为部署形态覆盖。若这个覆盖只是为了适配容器网络、容器端口或容器路径，应在 Compose 文件中说明；若覆盖的是业务语义，应移回 `.env` 语义，避免本地开发和 compose-full 运行出现两套配置。

## K8s / 云平台边界

K8s Secret、ConfigMap 和云平台环境变量是 `.env` 语义的部署投影，不是新的配置规则来源。

必须满足：

- Secret / ConfigMap 的键名应与 `.env.example` 中的应用配置键保持一致。
- 平台注入值可以覆盖项目 `.env`，但不能改名、拆分或新增另一套业务语义。
- 派生配置不得进入 Secret、ConfigMap 或平台环境变量；派生关系由应用 Settings 计算。
- 部署专用变量必须与应用配置键分开维护。

## 启动与回滚入口

每个部署形态必须给出：

- 启动命令。
- 必需外部依赖。
- 使用哪个 `.env` 或 env file。
- 健康检查地址。
- 日志查看入口。
- 停止或回滚方式。

部署入口不应要求维护者阅读源码才能找到应用端口、健康检查路径、配置文件或回滚方式。本地开发脚本的命令契约由 `../entrypoints/project-entrypoints.md` 负责；部署文档只引用它们，不复制脚本正文。

需要进入 Pod、容器或远端运行环境执行排障命令时，命令契约由 `../entrypoints/runtime-troubleshooting.md` 负责。部署文档只说明如何进入目标环境和需要的权限，不维护排障脚本正文。

## 验证闭环

每次部署或配置变更后，至少确认：

- 服务进程、容器或 Pod 处于健康状态。
- 当前部署形态实际加载的是预期 `.env` 或 env file。
- 技术栈可观测规则定义的健康检查、接口描述和日志信号可访问。
- 需要认证的关键业务接口返回预期状态。
- 依赖服务连接成功。
- 数据库迁移等发布前置动作已经执行。
- 必要的运行时排障入口可用，并能输出健康、版本、关键业务或 Job 查询结果。

如果服务依赖数据库迁移，新环境首次部署必须确认迁移已执行。迁移缺失不能被业务接口超时、worker 重启或 callback 失败掩盖。
