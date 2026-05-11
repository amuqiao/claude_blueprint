---
name: distill-draft
description: 提炼一篇草稿的核心判断，判断成熟度，并推荐它应留在 drafts、进入 incubating，还是升格为正式文档。
argument-hint: [草稿路径]
---

收到 `/distill-draft $ARGUMENTS`，按以下流程执行：

**Step 1 · 读取草稿与维护规则**

读取：
- `$ARGUMENTS`
- `MAINTAINING.md` 中“草稿何时升格”相关规则

如果路径不存在，直接提示用户提供正确草稿路径。

**Step 2 · 提炼草稿主题**

先用 1 到 2 句话说明：
- 这篇草稿真正讨论的是什么
- 它想解决的核心问题是什么

**Step 3 · 提炼核心判断**

从草稿中抽出 3 到 5 条真正值得保留的判断。

要求：
- 只保留会影响后续设计、方法或维护的内容
- 不复述零散过程性描述

**Step 4 · 判断成熟度**

从以下三类中选择一个最合适的当前状态：

- 保持普通草稿
- 升为重点草稿（`drafts/incubating/`）
- 可以提炼为正式文档

判断时明确说明理由。

**Step 5 · 推荐唯一主归宿**

只能给出一个主推荐去向：

- `drafts/`
- `drafts/incubating/`
- `PLAYBOOK.md`
- `WHY.md`
- `MAINTAINING.md`
- `README.md`

如果建议升格为正式文档，说明为什么最适合进入该文件，而不是别的文件。

**Step 6 · 给出下一步动作**

输出一个最小下一步建议，例如：
- 暂不升格，继续观察
- 移入 `drafts/incubating/`
- 提炼成 `PLAYBOOK.md` 的一个新小节
- 提炼成 `WHY.md` 的一个新决策节

**输出格式**（固定）：

1. 草稿主题
2. 核心判断
3. 当前成熟度
4. 推荐归宿
5. 下一步动作
