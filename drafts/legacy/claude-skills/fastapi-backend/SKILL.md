---
name: fastapi-backend
description: 设计、初始化或评审 FastAPI 后端项目时调用；统一 FastAPI + uv 的工程约定、分层方式和常用命令。触发词：FastAPI、uv、Python Web、后端架构、后端初始化、API 服务
---

# FastAPI 后端规范

## §1 适用边界

本规范适用于：

- 新建 FastAPI 后端项目
- 为现有项目补 FastAPI 后端架构约定
- 评审 FastAPI 项目的工程结构与依赖管理方式

本规范不负责：

- 具体业务接口设计
- 具体数据模型字段定义
- 前端页面与交互设计

这些内容仍分别由项目 `CLAUDE.md`、设计文档和模块设计文档负责。

## §2 核心工程约定

### 2.1 包与环境管理

FastAPI 项目统一使用 `uv` 管理：

- 依赖安装
- 虚拟环境
- 运行命令
- 脚本执行

默认做法：

- 用 `pyproject.toml` 作为 Python 项目的依赖与元信息源
- 用 `uv add` 新增依赖
- 用 `uv sync` 同步环境
- 用 `uv run` 运行服务、脚本和测试

默认不采用：

- 直接 `pip install`
- 手工维护 `requirements.txt` 作为主流程
- 脱离 `uv` 的独立虚拟环境管理方式

### 2.2 服务启动

推荐开发启动形式：

```bash
uv run uvicorn app.main:app --reload
```

如果项目已有统一脚本：

- 优先保留项目脚本作为入口
- 但脚本内部仍应围绕 `uv run` 组织

### 2.3 配置与依赖方向

- 应用代码依赖 `pyproject.toml` 定义的环境
- 运行方式以项目根或后端子目录中的 `uv` 工作流为准
- 不在 README、脚本、文档中混用多套包管理命令

## §3 默认后端结构（推荐 4 层）

默认推荐围绕 `app/` 组织 4 层结构：

```text
app/
├── main.py
├── api/            # 路由入口层
├── services/       # 应用层 / 业务编排
├── repositories/   # 数据访问层
├── schemas/        # 请求/响应契约
├── models/         # ORM / 持久化模型
├── core/           # 配置、日志、基础设施接入
└── integrations/   # 外部服务适配
```

对应关系：

- `api/`：只接收请求、校验参数、委托服务层
- `services/`：负责业务流程编排
- `repositories/`：封装数据库访问
- `core/` / `integrations/`：放基础设施与外部依赖

这是本规范的默认起盘方案，适合：

- 独立开发者项目
- 中小型业务
- 业务规则尚未复杂到需要独立领域层

### 3.1 4 层依赖方向

推荐依赖方向：

```text
api -> services -> repositories
api -> services -> integrations
services -> repositories
services -> integrations
repositories -> models
```

约束：

- `api/` 不直接操作数据库
- `api/` 不直接调用 ORM
- `services/` 不感知 FastAPI 请求对象
- `repositories/` 不承载业务流程判断

### 3.2 何时升级为 5 层

当出现以下信号时，建议从默认 4 层升级为 5 层：

- `services/` 明显变胖，业务规则大量堆积
- 状态机、权限、计费、编排规则开始反复复用
- 核心业务规则已经不适合继续混在 service 中

升级方式：

- 单独新增 `domain/` 目录
- 把核心业务规则、实体和值对象抽到领域层
- `services/` 保留流程编排职责
- `repositories/` 继续负责数据访问

升级后的 5 层理解：

1. `api/`：入口层
2. `services/`：应用层
3. `domain/`：领域层
4. `repositories/` + `models/`：持久化层
5. `core/` + `integrations/`：基础设施层

## §4 架构设计时的默认关注点

当任务是“做 FastAPI 后端架构设计”时，至少回答这些问题：

1. API 入口层与业务编排层如何分离
2. 数据访问层如何隔离 ORM 与业务逻辑
3. 配置、日志、认证、中间件放在哪一层
4. 后端目录结构是否能映射到分层约束
5. `uv` 命令如何成为项目统一入口
6. 当前项目是否还适合默认 4 层，还是已经应升级到 5 层

如果是在项目定盘阶段，推荐同时产出：

- 技术选型结论（为什么是 FastAPI）
- 工程约定结论（为什么统一用 `uv`）
- 推荐目录结构
- 当前采用 4 层还是 5 层的判断
- 本地开发启动方式

## §5 常用命令约定

常见表达应优先写成下面这种风格：

```bash
uv sync
uv run uvicorn app.main:app --reload
uv run pytest
uv run python scripts/seed_demo.py
```

约束：

- 文档、脚本、命令示例保持一致
- 不同位置不要混用 `python -m venv`、`pip install`、`poetry run`

## §6 自检清单

- [ ] FastAPI 项目是否明确统一使用 `uv`
- [ ] 依赖管理是否以 `pyproject.toml` 为准
- [ ] 文档、脚本、README 中是否使用统一的 `uv` 命令风格
- [ ] 路由层、服务层、数据访问层是否边界清晰
- [ ] 配置、日志、中间件、外部集成是否放在基础设施相关位置
- [ ] 是否避免在 API 路由层直接写业务逻辑或数据库操作
- [ ] 已明确当前项目采用默认 4 层还是升级到 5 层
