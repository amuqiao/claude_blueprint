---
description: 后端 AI 能力服务规则索引
---

# AI 能力服务规则

本目录维护模型供应商、Prompt、结构化输出、AI 结果校验、成本和容量保护规则。AI 规则只定义 AI 能力的稳定边界，不替代服务契约、Job 生命周期、数据库或通用外部集成规则。

## 子树边界

| 文件 | 负责 | 不负责 |
| --- | --- | --- |
| `capability-service.md` | Provider adapter、Prompt 版本、runtime snapshot、结构化输出校验、bounded repair、token/cost/latency 摘要、AI 容量保护 | HTTP envelope、Job 状态机、数据库模型、具体供应商 API 教程 |

## 加载顺序

当服务调用模型供应商或生成结构化 AI 输出时，推荐顺序：

1. `../contracts/service-contract.md`：确定对外 envelope、错误码、时间和日志主字段。
2. `../jobs/async-job.md`：当 AI 能力通过异步 Job 执行时确定状态机、投递、恢复和 runtime snapshot。
3. `../jobs/workflow-handler.md`：当 AI 能力通过异步 `job_type` 暴露时确定 handler、params/result schema 和结果映射。
4. `../persistence/database.md`：当 AI Job 需要持久化状态、CAS 迁移、事件表、timeline 或 artifact 引用时读取。
5. `../integrations/external-service.md`：确定通用外部 client、失败分类和环境保护。
6. `capability-service.md`：确定 AI 专属的 Prompt、模型、结构化输出、成本和容量约束。
