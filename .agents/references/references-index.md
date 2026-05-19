# References Index

本文件用于给 `Claude`、`Codex`、公共 agent 以及项目目录下的 `AGENTS.md` 提供统一入口索引。

它回答的不是“某条 `rule` 对应哪份真源”，而是：

- 当前问题属于哪个主题
- 应优先读取哪份真源
- 哪些文档是专项真源，哪些只是目录说明或维护映射

## 使用方式

1. 先判断当前问题属于哪个主题。
2. 只读取最相关的一份真源；不要默认加载全部。
3. 如果需要维护 `rule` 与真源的对应关系，再查看 [`rules-source-map.md`](./rules-source-map.md)。

## 主题索引

### 用户背景与默认解释方式

- 读取 [`user-background-guideline.md`](./user-background-guideline.md)
- 适用：用户背景、理解偏好、默认技术栈、默认解释层级

### 术语纠偏与专业表达重述

- 读取 [`terminology-normalization-guideline.md`](./terminology-normalization-guideline.md)
- 适用：`SwiftUI`、前端、iOS 交互、原型、页面结构、设计实现相关术语纠偏

### 任务推进与协作判断

- 读取 [`workflow-guideline.md`](./workflow-guideline.md)
- 适用：需求澄清、边界判断、推荐方案、是否扩展范围

### 测试、验证与完成声明

- 读取 [`testing-guideline.md`](./testing-guideline.md)
- 适用：最小验证、完成口径、测试输出、mock 边界

### 安全边界与敏感信息处理

- 读取 [`security-guideline.md`](./security-guideline.md)
- 适用：敏感目录、凭据处理、输入安全、日志与示例脱敏

### 文件命名与重命名约束

- 读取 [`file-naming-guideline.md`](./file-naming-guideline.md)
- 适用：文件命名、后缀约定、重命名边界

### Git 提交边界与提交信息

- 读取 [`git-commit-guideline.md`](./git-commit-guideline.md)
- 适用：提交边界、commit message、提交前最小检查

### 执行清单维护

- 读取 [`execution-checklist-guideline.md`](./execution-checklist-guideline.md)
- 适用：执行清单创建、阶段切换、归档与维护方式

### 正式文档表达

- 读取 [`../../skills/document-writing/references/writing-rules.md`](../../skills/document-writing/references/writing-rules.md)
- 适用：README、索引页、说明文档、方法论文档的结构与表达

## 边界说明

- 本文件是使用索引，不是目录治理说明；目录维护规则见 [`README.md`](./README.md)。
- 本文件不是 `rule` 与真源映射表；映射关系见 [`rules-source-map.md`](./rules-source-map.md)。
- 项目目录下的 `AGENTS.md` 如果需要引用本目录，优先引用本文件，而不是直接引用映射表。
