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

## 安装

### 全新安装

适用于本机还没有 `~/.claude` 的情况：

```bash
git clone https://github.com/amuqiao/claude_blueprint.git ~/.claude
```

### 备份后重建

适用于你想把旧的 `~/.claude` 整体留档，然后用这个仓库重新创建一个干净目录的情况。

不要直接执行 `git clone ... ~/.claude`，因为目标目录已存在且非空时会失败。

先备份当前目录：

```bash
mv ~/.claude ~/.claude.backup.$(date +%Y%m%d_%H%M%S)
```

然后再克隆：

```bash
git clone https://github.com/amuqiao/claude_blueprint.git ~/.claude
```

这种方式最干净。完成后，后续更新直接 `git pull` 即可。

### 就地接管现有 `~/.claude`

适用于 `~/.claude` 已经存在，你希望：

- 先完整备份
- 保留现有运行时目录和个人文件
- 直接把当前目录接管成这个仓库
- 后续仍然可以继续 `git pull`

执行仓库内脚本：

```bash
bash scripts/adopt-existing-claude.sh
```

如果你要接管的不是默认目录，也可以显式传参：

```bash
bash scripts/adopt-existing-claude.sh ~/.claude https://github.com/amuqiao/claude_blueprint.git
```

脚本会做 4 件事：

1. 先把当前 `~/.claude` 完整备份到 `~/.claude.backup.<时间戳>/`
2. 临时 clone 最新仓库
3. 用仓库内容覆盖 `~/.claude` 中应受版本控制的文件
4. 把 `~/.claude` 变成这个仓库的 git 工作目录

这样现有运行时目录和个人文件会保留在原位；仓库里的 `.gitignore` 会让这些运行时内容继续保持未跟踪/忽略状态。

### 后续更新远端内容

完成 clone 或“就地接管”之后，`~/.claude` 就是一个正常的 git 仓库。后续同步远端最新内容：

```bash
cd ~/.claude
git pull --ff-only origin main
```

如果你想先确认本地状态，再更新：

```bash
cd ~/.claude
git status
git pull --ff-only origin main
```

## 运行时目录

仓库已经在 `.gitignore` 中排除了 Claude Code 运行时数据，例如：

- `backups/`
- `cache/`
- `downloads/`
- `file-history/`
- `history.jsonl`
- `ide/`
- `paste-cache/`
- `plans/`
- `projects/`
- `session-env/`
- `sessions/`
- `tasks/`
- `telemetry/`

这样把仓库直接作为 `~/.claude` 使用时，不会把运行时噪音提交进 git。
