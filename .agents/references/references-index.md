# References Index

本文件用于给 `Claude`、`Codex`、公共 agent 以及项目目录下的 `AGENTS.md` 提供共享真源路由入口。

本文件承担的是：

- 共享真源的主题 description
- 对应真源的绝对路径

当项目级 `AGENTS.md` 指向本文件时，涉及共享规则的问题应先按本文件完成路由，再读取对应真源。

## 强制读取条件

- 当任务涉及共享用户背景、术语纠偏、任务推进、测试验证、安全边界、文件命名、Git 提交或执行清单规则时，必须先读取本文件。
- 不属于共享规则的问题，不必读取本文件。

## 使用方式

1. 先判断当前问题属于哪个主题。
2. 只读取最相关的一份真源；不要默认加载全部。
3. 只有在边界明显交叉时，才补读第二份真源。

## 主题索引

### 用户背景与默认解释方式

- description：用户背景、理解偏好、默认技术栈、默认解释层级
- 路径：`/Users/admin/Downloads/Code/claude_blueprint/.agents/references/user-background-guideline.md`

### 术语纠偏与专业表达重述

- description：`SwiftUI`、前端、iOS 交互、原型、页面结构、设计实现相关术语纠偏
- 路径：`/Users/admin/Downloads/Code/claude_blueprint/.agents/references/terminology-normalization-guideline.md`

### 任务推进与协作判断

- description：需求澄清、边界判断、推荐方案、是否扩展范围
- 路径：`/Users/admin/Downloads/Code/claude_blueprint/.agents/references/workflow-guideline.md`

### 测试、验证与完成声明

- description：最小验证、完成口径、测试输出、mock 边界
- 路径：`/Users/admin/Downloads/Code/claude_blueprint/.agents/references/testing-guideline.md`

### 安全边界与敏感信息处理

- description：敏感目录、凭据处理、输入安全、日志与示例脱敏
- 路径：`/Users/admin/Downloads/Code/claude_blueprint/.agents/references/security-guideline.md`

### 文件命名与重命名约束

- description：文件命名、后缀约定、重命名边界
- 路径：`/Users/admin/Downloads/Code/claude_blueprint/.agents/references/file-naming-guideline.md`

### Git 提交边界与提交信息

- description：提交边界、commit message、提交前最小检查
- 路径：`/Users/admin/Downloads/Code/claude_blueprint/.agents/references/git-commit-guideline.md`

### 执行清单维护

- description：执行清单创建、阶段切换、归档与维护方式
- 路径：`/Users/admin/Downloads/Code/claude_blueprint/.agents/references/execution-checklist-guideline.md`
