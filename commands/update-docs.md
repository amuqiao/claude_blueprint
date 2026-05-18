---
name: update-docs
description: 代码落库后同步文档状态。在完成一个功能模块的代码提交后运行。
argument-hint: [模块名称]
---

代码已落库，同步 $ARGUMENTS 模块的文档状态：

**Step 1 · 对照检查**（调用 rev subagent）
- 检查代码实现与设计文档（`docs/design/模块/$ARGUMENTS/设计_v1.md`）中的接口规范和数据模型是否一致
- 列出差异项（实现与设计不符的地方）

**Step 2 · 更新设计文档**（主对话 + personal-os 设计文档真源）
- 读取 `skills/personal-os/references/design-doc.md` 获取格式规范
- 若 Step 1 发现差异，按实际实现更新设计文档对应章节
- 将 §8 待定事项中已决策的问题标注决策结果

**Step 3 · 更新 INDEX**
- 将 `docs/design/INDEX.md` 中该模块状态改为 ✅ 已同步
- 更新最后更新日期

**Step 4 · 模具升级提示**
- 检查本次实现中是否有新的通用约束（在其他项目里也成立的规则）
- 如有，提示用户运行 `/add-rule` 将其归档到正确位置
