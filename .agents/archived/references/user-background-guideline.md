# User Background Guideline

## 文档职责

- 本文档用于承载用户背景、理解偏好与默认技术上下文的真源定义。
- 它回答的是“这个用户是谁、默认擅长什么、哪些问题需要额外适配解释”。

## 适用范围

- 需要根据用户背景调整解释方式时读取。
- 需要决定默认技术栈、默认理解层级或默认类比方式时读取。
- 不处理任务推进、验证要求、Git 提交或文档表达结构。

## 核心规则

- 用户名字是王桥，默认直接称呼“桥”。
- 默认时区是 `Asia/Shanghai`。
- 用户有长期 Python 后端经验，擅长 `FastAPI` 架构设计，不需要解释后端基础概念。
- 用户对 AI 工程链路有一定了解，但不默认等同于对训练机制、数学原理或模型细节已经精通。
- 用户前端方向相对薄弱；解释 `React`、`TypeScript`、`SwiftUI`、iOS 交互等概念时，优先用后端类比帮助建立理解。
- 回答 AI 相关问题时，优先先对齐所处层级：概念理解、工程实现、架构设计、训练细节、数学原理。
- 当用户未额外指定技术方案时，可优先基于 `FastAPI`、`SQLAlchemy`、`Celery`、`Redis`、`React`、`TypeScript`、`Zustand`、`Docker`、`Nginx`、`PostgreSQL` 给出实现建议。

## 与运行时规则的关系

- `rules/user-background.md` 只保留高频、短小、可默认加载的摘要。
- 全局 `AGENTS.md` 只保留跨项目稳定成立的极短入口。
- 需要补充默认背景或类比策略时，优先改本文件，再同步回写摘要。
- 术语纠偏专项规则见 [`terminology-normalization-guideline.md`](./terminology-normalization-guideline.md)。

## 缺失或冲突时怎么处理

- 如果运行时摘要与本文件冲突，以本文件为准，再回写 `rules/` 或 `AGENTS.md`。
- 如果某条内容已经超出“背景与理解偏好”范围，应拆到对应真源，而不是继续堆在本文件。
