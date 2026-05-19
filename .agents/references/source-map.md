# Source Map

本文件用于记录 `rules/` 当前对应的真源关系。

当前仓库是先有 `rules/`，后补 `.agents/references/` 真源。
因此本文件的职责是修复“已有运行时规则，但缺少统一真源”的历史缺口，而不是把 `rules/` 本身继续视为真源。

## 当前映射

### `rules/git.md`

- 当前真源：[`git-commit-guideline.md`](./git-commit-guideline.md)
- 说明：`rules/git.md` 只保留运行时短约束；提交边界、提交类型与提交前检查以该文为准。

### `rules/writing.md`

- 当前真源：[`../../skills/document-writing/references/writing-rules.md`](../../skills/document-writing/references/writing-rules.md)
- 说明：文档表达规则已经由 `document-writing` skill 的 `references/` 承载，本目录不重复复制正文。

### `rules/user-background.md`

- 当前真源：[`user-background-guideline.md`](./user-background-guideline.md)
- 说明：`rules/user-background.md` 只保留运行时摘要，背景事实、理解偏好与默认技术上下文以该文为准。
- 相关专题真源：[`terminology-normalization-guideline.md`](./terminology-normalization-guideline.md)
- 专题说明：术语纠偏原先散落在全局 `AGENTS.md`，现已抽成独立真源，由 `rules/user-background.md` 保留最小摘要入口。

### `rules/workflow.md`

- 当前真源：[`workflow-guideline.md`](./workflow-guideline.md)
- 说明：任务推进、协作判断与表达边界以该文为准，`rules/workflow.md` 仅保留高频摘要。

### `rules/testing.md`

- 当前真源：[`testing-guideline.md`](./testing-guideline.md)
- 说明：验证依据、测试说明与完成声明口径以该文为准，`rules/testing.md` 仅保留运行时摘要。

### `rules/security.md`

- 当前真源：[`security-guideline.md`](./security-guideline.md)
- 说明：安全边界、敏感目录与凭据处理要求以该文为准，`rules/security.md` 仅保留硬约束摘要。

### `rules/file-naming.md`

- 当前真源：[`file-naming-guideline.md`](./file-naming-guideline.md)
- 说明：命名原则、后缀约束与重命名边界以该文为准，`rules/file-naming.md` 仅保留运行时摘要。

## 使用规则

1. 优先读取与当前问题最相关的一条真源，不要默认加载全部。
2. 如果某条 `rule` 仍没有对应真源，应在本文件中明确标记缺失，并尽快补齐。
3. 真源补齐后，后续正文修改先改真源，再回写运行时摘要。
4. 如果某主题已经在 `skills/*/references/` 有稳定真源，优先复用，不在本目录复制。
