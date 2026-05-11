# Claude Blueprint

将《独立全栈开发者_OS_完整方案_v3》拆成可直接作为 `~/.claude/` 使用的仓库结构。

## 3 步上手

### 1. 克隆本仓库到本地

```bash
git clone git@github.com:amuqiao/claude_blueprint.git ~/code/claude_blueprint
cd ~/code/claude_blueprint
```

如果你使用 HTTPS：

```bash
git clone https://github.com/amuqiao/claude_blueprint.git ~/code/claude_blueprint
cd ~/code/claude_blueprint
```

### 2. 先预览，再部署到 `~/.claude`

```bash
bash scripts/deploy-to-claude.sh --dry-run
bash scripts/deploy-to-claude.sh
```

如果本机已经有旧的 `~/.claude`，先备份：

```bash
bash scripts/backup-claude.sh --dry-run
bash scripts/backup-claude.sh
bash scripts/deploy-to-claude.sh --dry-run
bash scripts/deploy-to-claude.sh
```

### 3. 后续更新

```bash
cd ~/code/claude_blueprint
git pull --ff-only origin main
bash scripts/deploy-to-claude.sh --dry-run
bash scripts/deploy-to-claude.sh
```

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

## 推荐使用方式

推荐把这个仓库 clone 到一个单独的本地目录维护，例如：

```bash
git clone git@github.com:amuqiao/claude_blueprint.git ~/code/claude_blueprint
cd ~/code/claude_blueprint
```

或者使用 HTTPS：

```bash
git clone https://github.com/amuqiao/claude_blueprint.git ~/code/claude_blueprint
cd ~/code/claude_blueprint
```

**不要把这个仓库直接 clone 到 `~/.claude`。**

推荐模型是：
- 本项目根目录：**配置源**
- `~/.claude`：**Claude Code 实际读取的目标目录**

也就是说，你平时维护和更新的是这个仓库；真正写入 `~/.claude` 时，使用部署脚本同步过去。

## 新用户操作步骤

先进入本项目根目录：

```bash
cd ~/code/claude_blueprint
```

然后根据你的情况选择下面一种。

### 情况 1：本机还没有 `~/.claude`

先预览将要同步的文件：

```bash
bash scripts/deploy-to-claude.sh --dry-run
```

确认无误后正式部署：

```bash
bash scripts/deploy-to-claude.sh
```

执行结果：
- 会创建 `~/.claude`
- 会把本仓库管理的文件同步进去
- 不会把 `~/.claude` 变成 git 仓库

### 情况 2：本机已经有 `~/.claude`，想先备份再部署

先预览备份动作：

```bash
bash scripts/backup-claude.sh --dry-run
```

确认无误后执行备份：

```bash
bash scripts/backup-claude.sh
```

然后预览部署：

```bash
bash scripts/deploy-to-claude.sh --dry-run
```

最后正式部署：

```bash
bash scripts/deploy-to-claude.sh
```

执行结果：
- 当前 `~/.claude` 会先备份到 `~/.claude.backup.<时间戳>`
- 本仓库管理的文件会覆盖同步到 `~/.claude`
- 运行时目录会继续留在原位

### 情况 3：你已经在用这套仓库，只想获取最新版本

先更新本项目根目录里的仓库：

```bash
cd ~/code/claude_blueprint
git pull --ff-only origin main
```

然后预览这次更新会同步哪些文件到 `~/.claude`：

```bash
bash scripts/deploy-to-claude.sh --dry-run
```

确认无误后正式部署：

```bash
bash scripts/deploy-to-claude.sh
```

这就是后续更新的标准流程：**先更新本仓库，再部署到 `~/.claude`。**

## 脚本说明

### `scripts/backup-claude.sh`

用途：把当前 `~/.claude` 完整备份到带时间戳的新目录。

```bash
bash scripts/backup-claude.sh --dry-run
bash scripts/backup-claude.sh
```

如果目标目录不是默认的 `~/.claude`，可以传路径：

```bash
bash scripts/backup-claude.sh --target /path/to/claude --dry-run
bash scripts/backup-claude.sh --target /path/to/claude
```

### `scripts/deploy-to-claude.sh`

用途：把本仓库管理的文件从当前项目根目录同步到 `~/.claude`。

```bash
bash scripts/deploy-to-claude.sh --dry-run
bash scripts/deploy-to-claude.sh
```

如果目标目录不是默认的 `~/.claude`，可以传参：

```bash
bash scripts/deploy-to-claude.sh --target /path/to/claude --dry-run
bash scripts/deploy-to-claude.sh --target /path/to/claude
```

脚本当前会同步这些路径：

- `CLAUDE.md`
- `settings.json`
- `hooks/`
- `skills/`
- `agents/`
- `commands/`
- `templates/`

这意味着：
- 你维护的是仓库副本
- 你部署的是受控文件集合
- `~/.claude` 里的运行时目录不会被这个脚本初始化成 git 仓库，也不会被脚本删除

部署范围不是靠脚本里硬编码判断，而是由仓库根目录的 [`deploy-manifest.txt`](/Users/admin/Downloads/Code/claude_blueprint/deploy-manifest.txt) 明确控制。
现在只有这些路径会进入 `~/.claude`：

- `CLAUDE.md`
- `settings.json`
- `hooks/`
- `skills/`
- `agents/`
- `commands/`
- `templates/`

这也意味着以下内容属于**仓库维护文件**，默认不会部署到 `~/.claude`：

- `scripts/`
- `drafts/`
- `README.md`
- `WHY.md`
- `.gitignore`

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

另外，`~/.claude.json` 也应视为 Claude Code 自动维护的本地状态文件，不属于本仓库的管理范围。
它通常包含启动次数、提示历史、功能开关缓存等运行时状态；不要把它纳入 blueprint 维护，也不要通过部署脚本覆盖它。
