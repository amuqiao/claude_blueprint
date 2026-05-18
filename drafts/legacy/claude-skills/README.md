# Claude Skills Legacy Archive

> **文档职责**：说明本目录的来源、当前状态和后续处理方式。
> **适用场景**：需要确认这些旧 `~/.claude/skills` 是何时迁入仓库、为何迁入、后续应如何维护或删除时。
> **目标读者**：本仓库维护者。
> **维护规范**：如果本目录继续保留，只维护事实信息；不要在这里继续演化新的 agent 规范。

## 当前状态

本目录是从原路径 `~/.claude/skills` 迁出的**旧 skills 存档**。

迁移时间：
- 2026-05-18

迁移前路径：
- `/Users/admin/.claude/skills`

迁移后路径：
- `drafts/legacy/claude-skills/`

当前处理口径：
- 这些内容**不再作为活动中的全局 skills 使用**
- 保留在仓库内，方便你手动维护、继续拆分或后续直接删除
- 大多数旧 skill 的当前主线以 `drafts/prompts/` 中已提取出的 prompt 文档为准
- `project-methodology` 例外：当前唯一真源在 [skills/project-methodology/](/Users/admin/Downloads/Code/claude_blueprint/skills/project-methodology)，不要把本目录中的历史副本继续当维护入口

## 为什么迁出

这批内容虽然以 `SKILL.md` 形式存在，但大多数更接近：

- prompt 模板
- 规范文档
- 写作/设计工作流
- 审查清单

也就是说，它们更像“被 skill 外壳包起来的 prompt 资产”，而不是需要长期保持激活的能力型 skill。

## 如何使用本目录

- 如果只是需要溯源：优先看 [MIGRATION_MAP.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/legacy/claude-skills/MIGRATION_MAP.md:1)
- 如果需要保留其中某份历史规则：直接打开对应子目录下的 `SKILL.md`
- 如果确定某份内容已完全由 prompt 接管：可以后续手动删除对应子目录
- 如果是 `project-methodology`：优先去仓库内 [skills/project-methodology/](/Users/admin/Downloads/Code/claude_blueprint/skills/project-methodology) 查看和维护
- 如果发现某份内容其实仍有独立价值：优先迁成项目内普通文档或方法论真源，不建议再放回 `~/.claude/skills`

## 不建议再做的事

- 不要把本目录重新当成活动中的全局 skill 仓库
- 不要一边维护这里，一边维护 `drafts/prompts/` 中的等价内容
- 不要继续增加新的 `SKILL.md` 到本目录
