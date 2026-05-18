---
name: add-rule
description: 发现新约束时，引导用户判断应该放在哪一层并完成归档。触发词：新规则、这条约束放哪里、怎么记录这个规则
argument-hint: [用自然语言描述这条新约束]
---

收到 /add-rule $ARGUMENTS，引导完成新约束归档：

**Step 1 · 读取维护规范**
不读取 `personal-os`。直接按下面的最小判断口径处理：

- 稳定、跨项目、你愿意长期维护的方法 -> 进 `skills/personal-os/`
- 属于项目阶段与方法演进 -> 进 `skills/project-methodology/`
- 只是日常好用、仍在试验、主要服务复制使用 -> 留在 `drafts/`
- 属于项目事实、架构决策、业务决策 -> 进 `docs/`

**Step 2 · 分类判断**
根据决策树，向用户提出以下问题（每次只问一个，得到回答后继续）：

Q1：这条约束是"让 AI 改变行为方式"，还是"记录项目的某个决策"？
- 改变 AI 行为 → 继续 Q2
- 记录项目决策 → 继续 Q4

Q2：这条约束在你的下一个技术栈完全不同的项目里也成立吗？
- 是 → 继续 Q3（放全局层）
- 否 → 放项目 `CLAUDE.md` 或对应项目文档

Q3：内容超过 3 行吗？
- 是 → 放 `skills/personal-os/` 或 `skills/project-methodology/` 的对应真源
- 否 → 放项目 `CLAUDE.md`、短规则入口，或先留在 drafts

Q4：这是产品/架构决策，还是过程经验/踩坑？
- 产品/架构决策 → 放 docs/design/ 对应文档
- 过程经验/踩坑 → 放 docs/专题/

**Step 3 · 执行归档**
确认目标位置后：
- 如果放 skill：优先追加到 `skills/personal-os/references/` 的对应主题文档；只有项目方法例外时才进 `skills/project-methodology/`
- 如果放 CLAUDE.md：追加到对应节的末尾
- 如果放设计文档：引导用户定位到项目级架构文档、模块设计文档或专题文档的具体节
- 如果放专题：创建新的专题文档（如果是新话题）或在已有文档追加

**Step 4 · 确认**
输出归档结果：`已将"$ARGUMENTS"归档到 {具体文件路径} 的 {具体节}`
