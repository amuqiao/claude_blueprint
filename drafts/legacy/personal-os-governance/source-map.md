# Personal OS Source Map

## 目的

这份地图只回答一件事：

**当前这个问题，应该去哪个真源维护。**

## 路由表

| 问题类型 | 去哪里 | 用途 |
|---|---|---|
| 项目阶段判断、项目起盘、模块接入、版本收敛、基础设施演进 | [`../project-methodology/`](../project-methodology) | 项目方法真源 |
| 正式文档结构、表达、可读性、骨架组织 | [`document-writing.md`](document-writing.md) | 文档表达真源 |
| 架构文档、模块设计文档、设计方案质检、接口规范与数据模型设计表达 | [`design-doc.md`](design-doc.md) | 设计文档真源 |
| FastAPI 后端起盘、工程分层、`uv` 工作流、测试补齐、改动验证、Request Body 示例 | [`fastapi-backend.md`](fastapi-backend.md) | 后端工程真源 |
| 批量 API 调用脚本、任务展开、并发、重试、文件产物、报告写出 | [`python-script.md`](python-script.md) | 批量脚本真源 |
| `dev.sh` / `service.sh`、多服务生命周期管理、PID、端口冲突、日志输出 | [`shell-service.md`](shell-service.md) | 服务管理真源 |
| 运维诊断 CLI、子命令、dry-run、`--apply`、多数据源排障 | [`python-ops-cli.md`](python-ops-cli.md) | 运维 CLI 真源 |
| 代码讲解、算法解释、关键逻辑说明、代码讲解文档结构 | [`code-explain.md`](code-explain.md) | 代码讲解真源 |
| 蓝图维护、规则归属、哪层该放什么、skill 是否应新建 | [`blueprint-governance.md`](blueprint-governance.md) | 个人工作流治理真源 |
| prompt 保留/合并/归档、prompt 与 skill 的分工 | [`prompt-layer-policy.md`](prompt-layer-policy.md) | prompt 使用层治理真源 |

## 默认顺序

1. 先判断问题是“项目方法 / 文档表达 / 设计文档 / FastAPI 后端 / 批量脚本 / 服务管理脚本 / 运维 CLI / 代码讲解 / 蓝图维护 / prompt 清理”中的哪类
2. 默认只进入一个真源
3. 只有在边界重叠时才读第二份

## 当前口径

- `project-methodology` 是项目方法唯一真源
- `personal-os` 是除项目方法外的主真源入口
- 文档表达、设计文档、FastAPI 后端、脚本模式、代码讲解等真源统一收编在 `personal-os/references/`
- `drafts/prompts/` 是日常使用层，不是默认真源
