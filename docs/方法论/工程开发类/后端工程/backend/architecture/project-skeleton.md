---
description: FastAPI、异步 Job、Typer 与 AI 能力服务项目骨架规则
---

# 后端项目骨架规则

本规则定义中型 Python 后端服务的稳定目录骨架，适用于需要同时提供 FastAPI HTTP 接口、异步 Job、Typer 运维 CLI、数据库持久化和 AI 能力接入的项目。骨架规则只规定职责归属和接入点，不替代服务契约、数据库、Job、AI 集成或部署专项规则。

## 适用边界

适用场景：

- 服务需要暴露多个 HTTP 接口或异步 `job_type`。
- API、Worker、Typer CLI 需要共享 Settings、Repository、schema 和 handler registry。
- 服务会长期演进，需要稳定新增接口、新增 Job 类型和新增外部集成。

不适用场景：

- 一次性脚本或只有单个同步函数的轻量工具。
- 没有持久化、没有后台任务、没有公开契约的小型实验。
- 已有成熟框架骨架且职责边界等价清晰的项目。

## 推荐目录

推荐骨架：

```text
app/
  main.py
  api/
    routes/
    dependencies.py
    exception_handlers.py
  schemas/
    envelope.py
    errors.py
    jobs.py
    common.py
  core/
    settings.py
    logging.py
    metrics.py
    time.py
  db/
    models/
    migrations/
    session.py
  repositories/
  services/
  jobs/
    registry.py
    lifecycle.py
    publisher.py
    recovery.py
  workflows/
    handlers/
    schemas/
  integrations/
    ai/
    storage/
    callback/
    artifact/
  cli/
    ops.py
  tests/
    contracts/
    integration/
    unit/
```

具体项目可以调整命名，但必须保留等价职责边界。不要让 `main.py`、route、Typer command、worker task 或 repository 承担多个层级职责。

## 职责边界

| 目录 | 负责 | 不负责 |
| --- | --- | --- |
| `api/` | HTTP route、依赖注入、异常 handler、OpenAPI 投影 | 业务执行、SQL、外部服务协议 |
| `schemas/` | envelope、错误、Job 壳、公共 schema 组合 | 业务流程、数据库模型 |
| `core/` | Settings、日志、metrics、时间工具、进程内基础设施 | 具体业务接口和 Job handler |
| `db/` | ORM 模型、session、迁移入口 | 对外响应 schema、业务判断 |
| `repositories/` | 数据读写、查询表达、CAS 更新 | HTTP、Typer 输出、外部 API 调用 |
| `services/` | 用例编排、事务边界、业务判断 | 直接读取 HTTP request 或直接拼 SQL |
| `jobs/` | Job 生命周期、publisher、恢复扫描、handler registry 接入 | 具体 AI 能力逻辑、执行器事实源 |
| `workflows/` | `job_type` handler、params/result schema、执行计划 | 通用 Job 状态机和 HTTP envelope |
| `integrations/` | AI、artifact/对象存储、callback、第三方协议 adapter | 对外错误结构和 Job 状态机 |
| `cli/` | Typer 命令、格式化、只读排障入口 | 直接修 DB、重定义业务状态 |
| `tests/contracts/` | envelope、OpenAPI/schema、Job/callback、日志字段契约测试 | 大而全的端到端回归替代品 |

## 新接口落点

新增 HTTP 接口时，应只新增或修改以下位置：

1. `api/routes/`：route 声明、鉴权和 dependency 注入。
2. `schemas/`：接口自己的 Request 与业务 Data schema；不得复制 envelope。
3. `services/`：业务用例和事务边界。
4. `repositories/`：确实需要新增数据查询时才修改。
5. `tests/contracts/`：成功、失败、OpenAPI/schema 和日志字段契约。

接口字段说明、必选/可选、类型、约束、`null` 与省略语义、错误码和示例由 `../contracts/api-operation-template.md` 统一约束。

## 新 Job Type 落点

新增 `job_type` 时，应只新增或修改以下位置：

1. `workflows/schemas/`：`ParamsSchema`、`CanonicalResultSchema`、`PublicResultSchema`、`CallbackDataSchema`。
2. `workflows/handlers/`：handler、执行计划、runtime fields 和结果映射。
3. `jobs/registry.py` 或等价注册入口：注册唯一 `job_type`。
4. `integrations/`：确实需要新增外部服务 adapter 时才修改。
5. `tests/contracts/`：创建、查询、终态、callback、错误码和 schema 映射测试。

不得为新增 `job_type` 复制一套 Job route、Job 表、callback envelope 或执行器状态机。

## 验证入口

稳定骨架至少提供以下验证：

- Settings 初始化和配置机器检查。
- 错误码、operation、schema version 和 `job_type` registry 检查。
- OpenAPI/schema 快照。
- 全局异常转换测试。
- Job 生命周期、复杂执行计划和 CAS 状态迁移测试。
- 新 `job_type` 的 params/result/callback schema contract tests。
- Typer 只读排障命令的 JSON 输出和退出码测试。
- Metrics 最小指标和高基数标签检查。
- Artifact 引用、hash、权限和过期策略检查；未启用时声明不启用。

如果项目暂时不启用某一能力，应在 README 或架构说明中标注未启用，而不是保留空实现、默认 fallback 或无法验证的半成品入口。
