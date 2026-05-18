# FastAPI Backend Rules

## 核心工程口径

FastAPI 项目默认统一使用 `uv` 管理：

- 依赖安装
- 虚拟环境
- 运行命令
- 测试和脚本执行

默认做法：

- 用 `pyproject.toml` 作为依赖与元信息源
- 用 `uv add` 增加依赖
- 用 `uv sync` 同步环境
- 用 `uv run` 运行服务、脚本与测试

默认不采用：

- 直接把 `pip install` 当主流程
- 手工维护 `requirements.txt` 作为主入口
- README、脚本、文档里混用多套包管理方式

## 默认目录与分层

默认推荐围绕 `app/` 组织：

```text
app/
├── main.py
├── api/
├── services/
├── repositories/
├── schemas/
├── models/
├── core/
└── integrations/
```

职责边界：

- `api/`：接收请求、做参数校验、调用服务层
- `services/`：业务流程编排
- `repositories/`：数据库访问与查询封装
- `schemas/`：请求与响应契约
- `models/`：ORM / 持久化模型
- `core/`：配置、日志、中间件、基础设施接入
- `integrations/`：外部服务适配

约束：

- `api/` 不直接写数据库操作
- `api/` 不直接承载业务流程
- `services/` 不依赖 FastAPI 请求对象
- `repositories/` 不承载复杂业务判断

## 什么时候从 4 层升级为 5 层

当出现以下信号时，考虑新增 `domain/`：

- `services/` 明显变胖
- 权限、状态机、计费、编排规则开始反复复用
- 核心业务规则已不适合继续混在 service 中

升级后的理解：

1. `api/`：入口层
2. `services/`：应用层
3. `domain/`：领域层
4. `repositories/` + `models/`：持久化层
5. `core/` + `integrations/`：基础设施层

## 起盘与评审时至少回答的问题

1. 为什么用 FastAPI
2. 为什么统一用 `uv`
3. 当前采用 4 层还是 5 层
4. 目录结构如何映射分层约束
5. 配置、日志、认证、中间件放在哪
6. 数据访问和业务逻辑如何隔离

## 单元测试补齐规则

补单元测试时，默认先做三步：

1. 检查项目是否已有 `tests/`、`pytest` 配置、fixture、mock 样例
2. 判断这次改动里哪些逻辑适合做单元测试
3. 只补最关键、最稳定的测试点

优先覆盖：

- 纯业务逻辑
- service 层行为
- repository 封装逻辑
- util / helper

避免：

- 直接依赖真实数据库、Redis、外部 API
- 把接口联调写成单元测试
- 一上来铺整套测试体系

## 改动后验证规则

FastAPI 改动后，默认按下面顺序判断验证方式：

1. 是否已有可复用测试
2. 是否已有联调脚本、健康检查或 smoke test
3. 是否应补最小测试
4. 是否应使用脚本或 `curl`
5. 是否只能做手工验证

输出时优先说明：

- 当前可用验证资产
- 受影响接口
- 推荐验证步骤
- 未覆盖项
- 风险与后续建议

## Request Body 示例规则

为 OpenAPI / `/docs` 补请求体示例时：

- 先根据实际 `Pydantic` / schema 模型判断字段组合
- 优先补一个最常见、最能解释接口用途的默认示例
- 如果接口确实有多种合法输入，再补多个示例
- 只补文档示例，不改业务逻辑

## 当前判断

- `drafts/prompts/` 中与 FastAPI 后端相关的 prompt 继续保留为使用层入口
- 后端工程规则、分层方式、测试与验证口径不再由派生 prompt 反向定义
- 详细接口字段与数据模型设计，仍应回到 `design-doc`
