# Claude Blueprint

将《独立全栈开发者_OS_完整方案_v3》拆成可直接作为 `~/.claude/` 使用的仓库结构。

## 目录

- `CLAUDE.md`：全局主控
- `settings.json`：全局设置骨架
- `hooks/`：强制执行的保护与提醒脚本
- `skills/`：按任务类型拆分的规范
- `agents/`：`arch` / `rev` 两个子代理定义
- `commands/`：`/new-module`、`/update-docs`、`/add-rule`
- `templates/`：项目初始化模板
- `drafts/`：模具层的思考草稿箱，先记录，后提炼
- `WHY.md`：模具层设计决策记录

## 当前状态

- 已按 v3 文档落地全部明确给出的文件内容。
- 四个补充 skill 已从 `~/.claude/规范/` 同步正文：`python-script`、`python-ops-cli`、`shell-service`、`code-explain`。

## 用法

```bash
git clone <your-private-repo> ~/.claude
```
