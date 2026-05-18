---
name: fastapi-backend
description: "FastAPI 后端工程模式真源 skill。适用于设计、初始化、评审 FastAPI 后端项目，或统一 uv、分层方式、测试补齐、改动验证和请求体示例等后端工作流时使用。"
---

# FastAPI Backend Skill

这是一个**FastAPI 后端工程模式真源 skill**。  
它不在正文里重复展开全部工程细节。

它主要负责：

- 统一 FastAPI + `uv` 的工程口径
- 判断当前项目适合 4 层还是 5 层
- 约束 API、service、repository、model 等层次边界
- 为测试补齐、改动验证、请求体示例等专项 prompt 提供上游真源

## Canonical Source

这个 skill 的后端工程真源在：

- [`references/fastapi-backend-rules.md`](references/fastapi-backend-rules.md)

默认只读取这一份 reference。  
如果 reference 缺失：

- 明确说明当前缺少 FastAPI 后端真源
- 仅保守遵守“统一 `uv`、分层清楚、最小补测试、最小验证”的原则

## 标准使用方式

这个 skill 的默认动作顺序是：

1. 先判断当前问题是“后端起盘 / 工程评审 / 测试补齐 / 改动验证 / OpenAPI 示例”中的哪一种
2. 读取 `references/fastapi-backend-rules.md`
3. 先输出建议结构或验证策略
4. 再进入实现、补齐或评审细节
5. 始终优先最小充分，不把专项任务做成重型治理工程

## 什么时候使用

当问题主要是**FastAPI 后端工程模式、分层方式、验证方式或测试补齐**时，使用这个 skill。

### 必须使用

- 新建或初始化 FastAPI 后端项目
- 评审 FastAPI 工程结构和依赖管理方式
- 判断后端该如何分层
- 为 FastAPI 改动补单元测试或验证方案
- 为接口请求体示例补 OpenAPI 文档默认值

### 推荐使用

- 想统一 `uv` 命令风格
- 不确定是继续 4 层还是升级到 5 层
- 不确定改动后该用测试、脚本、`curl` 还是手工验证

### 不适合使用

- 纯业务规则讨论
- 详细接口字段设计本体
- 项目阶段规划和版本演进判断

## 输出契约

默认先输出：

```text
当前后端任务类型：
当前工程现状：
建议最小动作：
建议验证方式：
建议最小产物：
```

只有在这一步明确后，才继续展开细节。

## 最小判断规则

- 如果问题是“FastAPI 项目怎么起盘” -> 先统一 `uv` 与目录结构
- 如果问题是“分层是否合理” -> 先检查 `api / services / repositories / models / core`
- 如果问题是“测试怎么补” -> 先找最小必要测试点，不先铺大而全测试体系
- 如果问题是“改动后怎么验证” -> 先复用已有测试资产，再决定是否补脚本或手工验证
- 如果问题是“Request Body 示例怎么补” -> 只改文档示例，不改业务逻辑

## 重要边界

- 这是后端工程模式真源，不取代 `design-doc`
- 接口字段契约和数据模型设计，仍优先回到设计文档真源
- 项目阶段、模块演进、版本收敛仍交给 `project-methodology`
- 永远优先最小可用、边界清楚、命令一致
