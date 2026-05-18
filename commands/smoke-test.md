---
name: smoke-test
description: 验证 ~/.claude 部署是否完整，输出结构摘要和下一步手工验收提示。
---

收到 `/smoke-test` 后，执行以下流程：

说明：

- 当前主维护入口默认是仓库内 `skills/personal-os/`
- 项目方法例外真源是 `skills/project-methodology/`
- 以下检查项仍保留 `~/.claude` 路径，是为了兼容旧部署验收口径

**Step 1 · 确认关键文件存在**

依次检查以下路径是否存在，并输出 `路径 → 存在 ✅` 或 `路径 → 缺失 ❌`：

- `~/.claude/CLAUDE.md`
- `~/.claude/settings.json`
- `~/.claude/hooks/protect-config.sh`
- `~/.claude/hooks/block-git-push.sh`
- `~/.claude/hooks/notify-file-changed.sh`
- `~/.claude/agents/arch.md`
- `~/.claude/agents/rev.md`
- `~/.claude/commands/add-rule.md`
- `~/.claude/commands/distill-draft.md`
- `~/.claude/commands/init-architecture.md`
- `~/.claude/commands/new-module.md`
- `~/.claude/commands/update-docs.md`
- `~/.claude/skills/personal-os/SKILL.md`
- `~/.claude/skills/project-methodology/SKILL.md`
- `~/.claude/templates/docs-INDEX.md`
- `~/.claude/templates/project-CLAUDE.md`
- `~/.claude/templates/架构设计方案.md`
- `~/.claude/templates/实施清单.md`

**Step 2 · 输出结构摘要**

输出 `~/.claude/` 下的一级目录和文件数量摘要。

建议格式：

- 一级目录：`hooks/`、`skills/`、`agents/`、`commands/`、`templates/`
- 文件总数：`N`

**Step 3 · 输出手工验收提示**

输出以下手工验收清单，提醒用户继续验证：

hooks 验收：
- 尝试让 Claude 修改 `CLAUDE.md` → 应出现二次确认
- 尝试让 Claude 执行 `git push` → 应被拒绝

skill 验收：
- 输入“帮我写一份新功能的设计文档” → 输出应包含“问题定义 / 目标 / 方案设计 / 数据模型 / 接口规范”
- 输入“帮我判断这条规范该进 skill 还是 prompt” → 输出应优先路由到 `personal-os`

agent 验收：
- `@arch` 描述一个架构问题 → 输出应包含“决策表 + 推荐理由 + 风险提示”
- `@rev` 检查一个文件 → 输出应是“文件路径:行号 → 问题 → 建议”格式
