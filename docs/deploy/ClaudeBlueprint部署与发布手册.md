# Claude Blueprint 部署与发布手册

> 本文说明如何把本仓库维护的 Claude Code 运行层资产安全同步到 `~/.claude`，并在更新脚本、manifest、运行层目录或 Plugin 计划后完成发布验证。

## 文档职责

本文负责当前仓库的部署与发布操作，不负责解释 Claude Code 基础概念，也不替代 [`README.md`](../../README.md)、[`MAINTAINING.md`](../../MAINTAINING.md) 和 [`RUNTIME-MAINTAINING.md`](../../RUNTIME-MAINTAINING.md)。

适用读者：维护或使用这套 `claude_blueprint` 的开发者。

适用场景：首次部署到 `~/.claude`、更新后重新同步、备份旧配置、调整部署白名单、检查 Plugin 安装命令、排查同步结果。

不适用于：服务器应用部署、Docker Compose 服务发布、数据库迁移、生产运维平台、CI/CD 自动发布。

## 任务入口

| 当前任务 | 进入章节 | 主要命令 |
| --- | --- | --- |
| 第一次部署到 `~/.claude` | [首次部署](#首次部署) | `bash scripts/deploy-to-claude.sh --dry-run` |
| 本机已有旧 `~/.claude` | [备份与恢复边界](#备份与恢复边界) | `bash scripts/backup-claude.sh --dry-run` |
| 更新仓库后重新同步 | [日常发布](#日常发布) | `git pull --ff-only origin main` |
| 检查会同步哪些文件 | [运行方式](#运行方式) | `cat deploy-manifest.txt` |
| 修改运行层目录或 manifest | [变更发布](#变更发布) | `bash scripts/deploy-to-claude.sh --dry-run` |
| 展示 Plugin 安装命令 | [Plugin 安装计划](#plugin-安装计划) | `bash scripts/show-plugin-install-commands.sh` |
| 同步后行为异常 | [故障排查](#故障排查) | `bash scripts/deploy-to-claude.sh --dry-run` |

## 部署模型

本仓库采用源目录和目标目录分离的模型：

```text
claude_blueprint/        # 配置源，受 git 管理
└── deploy-manifest.txt  # 部署白名单

~/.claude/               # Claude Code 实际读取的运行层目录
```

部署脚本只按 [`deploy-manifest.txt`](../../deploy-manifest.txt) 中的白名单同步文件。仓库中的 `docs/`、`drafts/`、`prompts/`、`scripts/`、`README.md`、`MAINTAINING.md` 等默认不部署到 `~/.claude`。

当前白名单路径：

```text
CLAUDE.md
settings.json
commands/
skills/
agents/
rules/
hooks/
templates/
```

这意味着：维护文档、方法论、草稿和脚本只存在于仓库；Claude Code 运行时读取的是同步后的 `~/.claude` 目录。

## 运行方式

### 方式一：部署到默认 `~/.claude`

这是日常主线。

```bash
bash scripts/deploy-to-claude.sh --dry-run
bash scripts/deploy-to-claude.sh
```

`--dry-run` 会展示将要创建、更新或保持不变的路径，不会写入目标目录。正式执行会用 `rsync -a` 把白名单路径同步到 `~/.claude`。

### 方式二：部署到自定义目标目录

适合测试部署结果，或不想直接改动真实 `~/.claude` 时使用。

```bash
bash scripts/deploy-to-claude.sh --target /tmp/claude-blueprint-test --dry-run
bash scripts/deploy-to-claude.sh --target /tmp/claude-blueprint-test
```

自定义目标可以用于比较同步结果，但不代表 Claude Code 会自动读取该目录。

### 方式三：只展示 Plugin 安装命令

Plugin 不由部署脚本直接安装。安装计划记录在 [`plugin-install-plan.md`](../../plugin-install-plan.md)，脚本只输出可复制到 Claude TUI 的 `/plugin ...` 命令。

```bash
bash scripts/show-plugin-install-commands.sh
bash scripts/show-plugin-install-commands.sh --extended
bash scripts/show-plugin-install-commands.sh --experimental
bash scripts/show-plugin-install-commands.sh --prompt
```

默认只输出 `Core` 主线 Plugin；`--extended` 和 `--experimental` 用于追加增强或实验层。

## 配置与边界

### `deploy-manifest.txt`

[`deploy-manifest.txt`](../../deploy-manifest.txt) 是部署白名单。新增会进入 `~/.claude` 的文件或目录时，必须先判断它是否属于运行层资产。

适合进入 manifest 的内容：

```text
CLAUDE.md
settings.json
commands/
skills/
agents/
rules/
hooks/
templates/
```

默认不进入 manifest 的内容：

```text
docs/
drafts/
prompts/
scripts/
README.md
WHY.md
MAINTAINING.md
DRAFTS-MAINTAINING.md
RUNTIME-MAINTAINING.md
plugin-install-plan.md
```

新增 manifest 路径后，至少同步检查：

```text
README.md
MAINTAINING.md
RUNTIME-MAINTAINING.md
docs/能力地图.md
docs/工作流参考.md
```

是否需要全部修改，取决于变更是否影响用户入口、运行层边界或能力说明。

### 目标目录

默认目标目录是：

```text
~/.claude
```

脚本会创建目标目录，但不会把它变成 git 仓库。

### 依赖命令

部署和备份脚本依赖：

```text
bash
rsync
```

Plugin 展示脚本只解析本仓库的 `plugin-install-plan.md`，不会联网，也不会安装 Plugin。

## 首次部署

### 1. 克隆仓库

```bash
git clone git@github.com:amuqiao/claude_blueprint.git ~/code/claude_blueprint
cd ~/code/claude_blueprint
```

如果使用 HTTPS：

```bash
git clone https://github.com/amuqiao/claude_blueprint.git ~/code/claude_blueprint
cd ~/code/claude_blueprint
```

### 2. 预览同步计划

```bash
bash scripts/deploy-to-claude.sh --dry-run
```

重点检查：

```text
Source repo 是否是当前仓库
Target dir 是否是预期目录
Managed paths 是否符合 deploy-manifest.txt
Sync plan 中是否有异常 UPDATE
```

### 3. 正式同步

```bash
bash scripts/deploy-to-claude.sh
```

完成后脚本会输出：

```text
Deploy finished.
Target: ~/.claude
```

### 4. 展示 Plugin 安装命令

```bash
bash scripts/show-plugin-install-commands.sh
```

把输出的 `/plugin ...` 命令复制到 Claude TUI 中执行。脚本不会自动安装 Plugin。

## 已有 `~/.claude` 时的部署

如果本机已经有旧的 `~/.claude`，先备份，再部署。

```bash
bash scripts/backup-claude.sh --dry-run
bash scripts/backup-claude.sh
bash scripts/deploy-to-claude.sh --dry-run
bash scripts/deploy-to-claude.sh
```

备份目录格式：

```text
~/.claude.backup.YYYYMMDD_HHMMSS
```

备份脚本要求目标目录已经存在。如果 `~/.claude` 不存在，不需要执行备份，直接部署即可。

## 日常发布

日常发布指仓库已有更新，需要把最新运行层资产同步到 `~/.claude`。

```bash
cd ~/code/claude_blueprint
git pull --ff-only origin main
bash scripts/deploy-to-claude.sh --dry-run
bash scripts/deploy-to-claude.sh
bash scripts/show-plugin-install-commands.sh
```

如果 `--dry-run` 中出现大量非预期 `UPDATE`，先确认是否切错分支、目标目录是否正确、manifest 是否变更，再正式同步。

## 变更发布

按改动类型选择发布路径。

| 改动类型 | 是否需要部署 | 发布动作 |
| --- | --- | --- |
| 修改 `CLAUDE.md` | 是 | `deploy-to-claude.sh --dry-run` 后正式同步 |
| 修改 `settings.json` | 是 | 同步后在 Claude Code 中检查配置是否生效 |
| 修改 `commands/` | 是 | 同步后在 Claude TUI 中触发对应命令 |
| 修改 `skills/` | 是 | 同步后在对应任务中触发 skill |
| 修改 `agents/` | 是 | 同步后验证对应 agent 可被调用 |
| 修改 `rules/` | 是 | 同步后检查对应任务是否能读到规则 |
| 修改 `hooks/` | 是 | 同步后手工触发对应 hook 场景 |
| 修改 `templates/` | 是 | 同步后用临时目录验证模板可用 |
| 修改 `deploy-manifest.txt` | 是 | 先 dry-run，确认新增或删除路径符合预期 |
| 修改 `plugin-install-plan.md` | 不由部署脚本安装 | 运行 `show-plugin-install-commands.sh` 检查输出 |
| 修改 `docs/`、`drafts/`、`prompts/` | 否 | 只提交仓库，不同步到 `~/.claude` |
| 修改 `scripts/` | 否，但影响部署工具 | 本地运行对应脚本 dry-run 验证 |

如果一次变更同时修改运行层和维护文档，应先确认运行层行为，再同步更新说明文档。

## 常用操作

### 查看部署白名单

```bash
cat deploy-manifest.txt
```

### 预览部署

```bash
bash scripts/deploy-to-claude.sh --dry-run
```

### 正式部署

```bash
bash scripts/deploy-to-claude.sh
```

### 部署到临时目录验证

```bash
bash scripts/deploy-to-claude.sh --target /tmp/claude-blueprint-test --dry-run
bash scripts/deploy-to-claude.sh --target /tmp/claude-blueprint-test
```

### 备份当前 `~/.claude`

```bash
bash scripts/backup-claude.sh --dry-run
bash scripts/backup-claude.sh
```

### 展示 Plugin 安装命令

```bash
bash scripts/show-plugin-install-commands.sh
bash scripts/show-plugin-install-commands.sh --extended
bash scripts/show-plugin-install-commands.sh --prompt
```

## 备份与恢复边界

备份脚本只做目录复制：

```text
~/.claude -> ~/.claude.backup.YYYYMMDD_HHMMSS
```

它不会判断配置是否有效，也不会自动恢复。

恢复时不要直接覆盖，先比较差异：

```bash
diff -ru ~/.claude ~/.claude.backup.YYYYMMDD_HHMMSS | less
```

确认需要恢复后，再手工复制目标文件或目录。

危险操作边界：

```text
不要直接删除 ~/.claude
不要在不备份的情况下覆盖 settings.json
不要把整个仓库复制到 ~/.claude
不要把 docs/、drafts/、prompts/ 当成运行层部署内容
```

本项目没有数据库、Docker volume、上传文件或服务端持久化数据。数据安全重点是保护用户已有 `~/.claude` 配置和避免误同步运行层范围。

## 故障排查

| 现象 | 检查命令 | 判断与处理 |
| --- | --- | --- |
| 提示 `Required command not found: rsync` | `command -v rsync` | 安装 `rsync` 后重试 |
| `deploy-manifest.txt` 找不到 | `ls deploy-manifest.txt` | 确认在仓库根目录运行脚本 |
| dry-run 目标目录不对 | 查看脚本输出 `Target dir` | 使用 `--target <dir>` 或切回正确用户 |
| 同步后 Claude 行为没变化 | `ls -la ~/.claude` | 确认部署目标就是 Claude Code 实际读取目录 |
| 新增目录没有同步 | `cat deploy-manifest.txt` | 新目录必须加入 manifest 才会部署 |
| Plugin 没安装 | 运行 `show-plugin-install-commands.sh` | 脚本只展示命令，需要在 Claude TUI 手工执行 |
| 已有配置被覆盖 | 查看备份目录 | 从 `~/.claude.backup.*` 手工恢复对应文件 |
| hook 没触发 | 检查 `settings.json` 和 `hooks/` | 确认 hook 已部署且配置字段仍合法 |

## 维护规则

以下变更必须同步检查本文档：

```text
修改 deploy-manifest.txt
修改 deploy-to-claude.sh 或 backup-claude.sh
修改 show-plugin-install-commands.sh 的参数或输出语义
新增或删除会部署到 ~/.claude 的目录
改变 Plugin 安装计划的分层或入口
改变“仓库是配置源，~/.claude 是部署目标”的部署模型
```

以下变更通常不需要修改本文档，除非影响部署行为：

```text
新增普通 docs 文档
整理 drafts
新增不部署的 prompt
修改方法论文档
修改仓库维护说明但不改变部署入口
```

维护部署文档时，应优先同步以下文件之间的事实：

```text
README.md
MAINTAINING.md
RUNTIME-MAINTAINING.md
deploy-manifest.txt
scripts/deploy-to-claude.sh
scripts/backup-claude.sh
scripts/show-plugin-install-commands.sh
```

如果这些文件对部署边界的描述不一致，以脚本和 `deploy-manifest.txt` 的实际行为为准，再回写文档。
