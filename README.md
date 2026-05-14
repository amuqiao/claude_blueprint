# Claude Blueprint

一套面向独立全栈开发者的 Claude Code 个人开发 OS，基于真实项目经验提炼，包含分层架构约束、规范 skill 库、保护 hook 和部署脚本。

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

## 仓库结构

```text
claude_blueprint/
├── CLAUDE.md              # 全局主控：跨项目通用约束
├── settings.json          # 全局 Claude Code 设置骨架
├── deploy-manifest.txt    # 部署白名单：哪些路径会同步到 ~/.claude
├── PLAYBOOK.md            # 开发范式说明（仓库元文档，不部署）
├── WHY.md                 # 模具设计决策记录（仓库元文档，不部署）
├── MAINTAINING.md         # 维护迭代手册（仓库元文档，不部署）
├── DRAFTS-MAINTAINING.md  # 草稿箱治理手册（仓库元文档，不部署）
├── RUNTIME-MAINTAINING.md # 运行层资产维护手册（仓库元文档，不部署）
├── README.md              # 仓库说明（仓库元文档，不部署）
├── .gitignore             # 仓库忽略规则（仓库元文档，不部署）
│
├── hooks/                 # Hook 脚本：保护配置、提醒变更、阻止 git push
├── rules/                 # 最小启用的可选规则层：当前仅保留 writing 示例
├── skills/                # 按任务类型拆分的规范库
├── agents/                # 子代理定义：arch / rev
├── commands/              # 自定义斜杠命令
├── templates/             # 项目初始化模板
├── prompts/               # 正式可复用 prompt（不部署）
├── docs/                  # 仓库级总览文档（不部署）
│
├── scripts/               # 仓库维护与部署脚本（不部署）
│   ├── backup-claude.sh   # 备份现有 ~/.claude
│   └── deploy-to-claude.sh# 把白名单文件同步到 ~/.claude
│
└── drafts/                # 草稿总入口（不部署）
    ├── docs/              # 文档/方法论草稿
    │   └── wip/           # 重点草稿：接近正式方法/决策，但尚未定稿
    └── prompts/           # prompt 草稿
        ├── wip/           # 正在打磨的 prompt
        └── archived/      # 已废弃或已被 skill 吸收的 prompt
```

## 当前状态

- 已按 v3 文档落地全部明确给出的文件内容。
- 四个补充 skill 已从 `~/.claude/规范/` 同步正文：`python-script`、`python-ops-cli`、`shell-service`、`code-explain`。

## 核心文档分工

- `README.md`：给使用者看，讲安装、部署、更新、验收
- `PLAYBOOK.md`：讲开发范式，回答先做什么、后做什么、每阶段产出什么
- `WHY.md`：讲为什么这样设计
- `MAINTAINING.md`：给维护者看，说明仓库治理、文档治理、发布与检查
- `DRAFTS-MAINTAINING.md`：给维护者看，说明草稿箱如何分阶段、如何分类、何时升格
- `RUNTIME-MAINTAINING.md`：给维护者看，说明 `CLAUDE.md`、`settings.json`、`rules/`、`hooks/`、`skills/`、`agents/`、`commands/`、`templates/` 怎么维护
- `docs/`：给已经理解主结构的人看，补用户心智模型、项目级落地范式、能力区别和工作流参考
- `prompts/`：放已可复用的正式 prompt
- `drafts/docs/wip/`：放重要但尚未正式定稿的文档/方法论草稿
- `drafts/prompts/wip/`：放还在打磨的 prompt 草稿

补充说明：
- `rules/` 当前不是这套 blueprint 的默认主结构层
- 仓库里只保留了一个最小 `writing` 规则，用来验证 rules 机制可用
- 只有当 `CLAUDE.md` 明显继续膨胀时，才考虑按主题进一步拆分

## 人类层 vs Claude 层

这套 blueprint 同时服务两个对象：

- **人类层**：帮助你判断现在处于哪个阶段、该用哪种能力、如何组织开发流程
- **Claude 层**：让 Claude 在运行时按你的规范工作

| 层级 | 主要对象 | 解决什么问题 | 典型文件 |
|------|---------|-------------|---------|
| 人类层 | 你 | 先做什么、后做什么、如何使用这套系统 | `README.md`、`PLAYBOOK.md`、`docs/能力地图.md`、`docs/工作流参考.md` |
| Claude 层 | Claude / Codex | 运行时该遵守什么规则、该如何执行工作流 | `CLAUDE.md`、`commands/`、`skills/`、`agents/`、`hooks/`、`templates/`、`settings.json` |

推荐理解顺序：

1. 先看人类层文档，建立正确心智模型
2. 再在 Claude TUI 中使用 commands / agents / skills
3. 真正执行时，由 Claude 层配置生效

如果你对这两层仍然有混淆，继续看：

- [`docs/用户心智模型.md`](/Users/admin/Downloads/Code/claude_blueprint/docs/用户心智模型.md)

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

## 记忆位置约定

本 blueprint 采用以下 Claude Code 记忆位置约定：

- **项目共享记忆**：项目根 `CLAUDE.md`
- **用户全局记忆**：`~/.claude/CLAUDE.md`
- **项目个人补充**：优先在项目 `CLAUDE.md` 中通过 `@import` 引入个人文件

**重要**: 本 blueprint 不把 `.claude/CLAUDE.md` 作为标准项目记忆位置。

**原因**：根据官方文档，`.claude/CLAUDE.md` 是子目录记忆文件，只在 Claude 读取 `.claude/` 子树文件时才加载，不等价于官方定义的"项目私有 memory"。官方推荐的项目私有记忆方式是 `CLAUDE.local.md` 或通过 `@import` 引入个人文件。

补充说明：
- 如需兼容官方项目个人记忆文件，也可以使用项目根 `CLAUDE.local.md`
- 如果项目里已经存在 `.claude/CLAUDE.md`，应判断其中内容是项目共享说明还是个人私有说明，再迁回合适位置

## 新用户操作步骤

先进入本项目根目录：

```bash
cd ~/code/claude_blueprint
```

然后根据你的情况选择下面一种。

如果这是一个新项目，或者项目里还没有完整的 `CLAUDE.md`、`docs/design/INDEX.md`、`docs/design/架构设计方案.md`、`docs/实施清单.md`，建议先在 Claude Code 中运行：

```text
/init-architecture
```

它会先补齐项目级最小骨架，再进入后续的 `/new-module`、`/update-docs` 等正常开发流程。

注意：
- `/init-architecture` 是**骨架入口**，不是完整的项目起盘方法
- 如果你卡在“先定技术栈、先选首个模块、先补哪侧基础设施、什么时候该做 `mock.html`”，先看 [`docs/项目级落地范式.md`](/Users/admin/Downloads/Code/claude_blueprint/docs/项目级落地范式.md)

标准项目生命周期建议按这条主线执行：

1. 新项目 / 老项目首次纳入规范：`/init-architecture`
2. 新增功能模块：`/new-module`
3. 代码完成并落库后：`/update-docs`
4. 发现新的跨项目通用约束：`/add-rule`

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

## 在 Claude TUI 中如何使用

部署完成后，真正的使用入口主要有 5 类：`commands`、`agents`、`skills`、`hooks`、`templates`。

| 类型 | 作用 | 触发方式 | 适合什么 |
|------|------|---------|---------|
| `commands` | 进入某个明确的工作流阶段 | 手动输入 `/命令名` | 初始化、建模块、同步文档、归档规则 |
| `agents` | 做带角色的分析或审查 | 手动输入 `@agent` | 架构判断、代码审查 |
| `skills` | 规定某类任务怎么做 | 通常由任务语义触发，也可用明确表述引导 | 设计文档、写作、脚本、运维类任务 |
| `hooks` | 做强制拦截或提醒 | 自动触发 | 阻止危险动作、提醒关键文件变更 |
| `templates` | 提供稳定起点 | 通常不手动触发，由 command 使用 | 项目初始化、架构文档、实施清单 |

### commands

直接在 Claude TUI 中输入斜杠命令：

```text
/init-architecture
/new-module 用户认证
/update-docs 用户认证
/distill-draft drafts/docs/某篇草稿.md
/add-rule 新增一条跨项目通用约束
```

适合你已经明确“现在要进入哪个阶段”的情况。

补充：
- `/init-architecture` 负责补最小项目骨架
- “项目到底怎么起盘、先做什么、后做什么” 见 [`PLAYBOOK.md`](/Users/admin/Downloads/Code/claude_blueprint/PLAYBOOK.md) 和 [`docs/项目级落地范式.md`](/Users/admin/Downloads/Code/claude_blueprint/docs/项目级落地范式.md)

### agents

直接在对话中显式调用：

```text
@arch 帮我判断这个模块是否会影响全局架构
@rev 检查 app/services/user_service.py 是否违反分层约束
```

适合需要“架构判断”或“合规审查”，而不是直接开始实现的时候。

### skills

通常不需要手动指定文件名；Claude 会根据任务语义加载对应 skill。你也可以用更明确的表达去引导：

```text
帮我写一份新功能的设计文档
帮我整理一个运维诊断 CLI 脚本
帮我写一篇结构清晰的技术说明
```

适合“这类任务应该按什么规范来做”，而不是“现在进入哪个工作流阶段”。

### hooks

hooks 不需要手动调用。它们会在特定动作时自动触发，例如：

- 让 Claude 修改 `CLAUDE.md` → 会出现二次确认
- 让 Claude 执行 `git push` → 会被拒绝

适合那些必须强制执行、不能靠提示词软约束的行为。

### templates

templates 通常不需要在 TUI 中单独调用，而是被 command 使用：

- `/init-architecture` 会使用项目模板、架构设计方案模板、实施清单模板
- `/new-module` 会创建模块设计文档和页面 mock

适合提供“稳定起点”，不适合单独承担工作流逻辑。

## 验收

部署完成后，建议做一次最小验收。

### 1. 运行 `/smoke-test`

在 Claude Code 里运行：

```text
/smoke-test
```

它会做三件事：
- 检查 `~/.claude` 下关键文件是否存在
- 输出当前结构摘要
- 提示下一步手工验收项

### 2. 用固定样例测试 `arch` 和 `rev`

仓库根目录下提供了两个最小 fixtures：

- [`acceptance/rev-bad-sample.py`](/Users/admin/Downloads/Code/claude_blueprint/acceptance/rev-bad-sample.py)
- [`acceptance/arch-question.md`](/Users/admin/Downloads/Code/claude_blueprint/acceptance/arch-question.md)

建议这样验：

- `@rev` 检查 `acceptance/rev-bad-sample.py`
  预期：指出“入口层直接访问数据库 / 直接 commit”等违规点
- `@arch` 读取 `acceptance/arch-question.md`
  预期：输出“决策表 + 推荐理由 + 风险提示 + 文档影响”

### 3. 手工验证 hooks 和 skill

- 尝试让 Claude 修改 `CLAUDE.md`
  预期：出现二次确认
- 尝试让 Claude 执行 `git push`
  预期：被拒绝
- 输入“帮我写一份新功能的设计文档”
  预期：输出应包含“问题定义 / 目标 / 方案设计 / 数据模型 / 接口规范”

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
- `MAINTAINING.md`
- `.gitignore`

原因是这些文件属于仓库的元文档和维护工具：
- `WHY.md` 和 `drafts/` 主要给维护者阅读，用来记录设计判断和演化过程
- `MAINTAINING.md` 用来说明后续如何维护这个仓库
- `scripts/`、`README.md`、`.gitignore` 也属于仓库管理层，不是 Claude Code 运行时需要加载的工作目录内容

## 部署后验证

部署完成后，建议重启 Claude Code，然后做两步验证：

1. 输入：`我想写一份设计文档`
   观察是否自动加载 `design-doc` skill，并按设计文档规范响应。
2. 在 Claude Code 里运行：`/doctor`
   检查 skill 描述预算是否正常，确认没有加载异常或描述溢出。

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
