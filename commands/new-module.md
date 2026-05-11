---
name: new-module
description: 开发新功能模块的完整启动流程：需求理解 → 架构评估 → 设计文档 → UI 原型 → 更新 INDEX
argument-hint: [模块名称]
---

收到 /new-module $ARGUMENTS，执行以下流程：

**Step 0 · 检查前置条件**

先检查以下文件是否存在：
- 项目根 `CLAUDE.md`
- `docs/design/INDEX.md`
- `docs/design/架构设计方案.md`
- `docs/实施清单.md`

如果任一缺失：
- 停止当前流程
- 输出缺失文件列表
- 明确提示用户先运行 `/init-architecture`

**Step 1 · 读取输入**
- 读 `docs/需求/` 下最新的需求文档，找到与 $ARGUMENTS 相关的内容
- 读 `docs/design/INDEX.md` 了解当前文档全貌，确认 $ARGUMENTS 是否已存在

**Step 2 · 架构评估**（调用 arch subagent）
- 评估新模块如何融入现有架构（读架构设计方案后给出判断）
- 确认：涉及哪些层、新增哪些文件、是否影响骨架
- 输出：影响范围表 + 推荐的实现路径

**Step 3 · 设计文档**（主对话 + design-doc skill）
- 读取 `~/.claude/skills/design-doc/SKILL.md` 获取格式规范
- 在 `docs/design/模块/$ARGUMENTS/` 下创建 `设计_v1.md`
- 至少覆盖：§1 问题定义、§2 目标与非目标、§3 方案设计、§4 数据模型、§5 接口规范
- §6 前端集成和 §8 待定事项可根据已知情况决定是否填写

**Step 4 · UI 原型**（如有前端页面）
- 先输出极简 ASCII 布局草图（用于快速对齐结构认知）
- 再在 `docs/design/模块/$ARGUMENTS/` 下创建 `页面布局_mock.html`

**Step 5 · 更新 INDEX**
- 在 `docs/design/INDEX.md` 功能模块表格中新增该模块条目
- 同步状态标记为 🆕 新建中

**Step 6 · 实施清单**
- 在 `docs/实施清单.md` 追加该模块的开发任务列表
- 任务按依赖顺序排列（后端数据模型 → 数据访问层 → 应用层 → 入口层 → 前端）
