# VoltAgent Claude Code Subagents 快速开始

本文是一份可交给其他人复现的安装手册：先确认 Claude Code CLI 可用，再从 `VoltAgent/awesome-claude-code-subagents` 安装 Claude Code plugins，最后复制 `CLAUDE.md` 工作流规则，让 Claude Code 可以按“先选工作流、再派发专家、最后 review/verify”的方式协作。

如果你想先理解 Claude Code 为什么这样配置，读 [ClaudeCode插件多角色Agent工作机制.md](./ClaudeCode%E6%8F%92%E4%BB%B6%E5%A4%9A%E8%A7%92%E8%89%B2Agent%E5%B7%A5%E4%BD%9C%E6%9C%BA%E5%88%B6.md)。本文只保留安装、验证和排查所需的最少解释。

## 整体流程

先看完整链路，后面的步骤就是按这张图落地：

```text
确认 Claude Code CLI
  claude --version
    ↓

安装工作流规则
  setup-claude-code-workflow.sh
    ↓ 写入 ~/.claude/CLAUDE.md

安装专家插件
  setup-claude-code-subagents.sh
    ↓ claude plugin marketplace add VoltAgent/awesome-claude-code-subagents
    ↓ claude plugin install/update voltagent-xxx@voltagent-subagents
    ↓ 写入 ~/.claude/plugins/marketplaces 与 ~/.claude/plugins/cache

使用
  重启 Claude Code 或运行 /reload-plugins
    ↓
  主 agent 按 CLAUDE.md 工作流规则派发 voltagent-lang:typescript-pro / voltagent-qa-sec:code-reviewer 等 subagent
```

这套方案使用 Claude Code 原生机制：

```text
~/.claude/CLAUDE.md
  负责规则：什么时候问工作流、什么时候派发 subagent、怎么 review/verify

Claude Code plugins
  负责身份：定义 plugin namespace 和每个 subagent 的能力
```

## 前置要求

需要本机已有：

```bash
claude --version
git --version
```

如果 `claude --version` 不存在，先完成 Claude Code CLI 安装和登录。本文不负责 Claude Code CLI 安装，只负责安装工作流规则和 VoltAgent plugins。

## 一次性完整命令

如果你只是想按默认路径完整安装，可以直接复制下面这组命令：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-claude-code

./setup-claude-code-workflow.sh
./setup-claude-code-subagents.sh
```

上面的 `cd` 是本文档所在机器的路径；提供给其他人时，把它替换成对方下载后的 `voltagent-claude-code` 目录路径。

如果 `~/.claude/CLAUDE.md` 已存在，工作流脚本会停止，避免覆盖。确认要更新时使用：

```bash
./setup-claude-code-workflow.sh --force
```

插件安装脚本默认安装 marketplace 中的 10 个 VoltAgent plugins。只想安装旧版常用三件套时：

```bash
./setup-claude-code-subagents.sh --plugins=voltagent-core-dev,voltagent-lang,voltagent-qa-sec
```

后面的章节会解释这些命令分别创建了什么文件、如何验证、以及出问题时怎么排查。

## `~/.claude` 目录结构

`~/.claude` 是 Claude Code 的全局配置目录。需要区分两件事：哪些是 Claude Code 自己已有的，哪些是本文脚本后续写入的。

### 安装本文脚本前

一台已经能运行 Claude Code 的机器上，`~/.claude` 可能已经有用户设置、登录状态、插件缓存、会话、已有 skills 或其他配置。具体内容取决于你的本机历史配置。

本文不要求清空 `~/.claude`，也不建议删除整个目录。

### 执行本文脚本后

执行本文两个脚本后，会新增或更新这些内容：

```text
~/.claude/
  CLAUDE.md
    由 setup-claude-code-workflow.sh 写入
    作用：Claude Code 工作流规则

  plugins/
    marketplaces/
      voltagent-subagents/
        由 claude plugin marketplace add 写入或更新
        作用：缓存 https://github.com/VoltAgent/awesome-claude-code-subagents

    cache/
      voltagent-subagents/
        voltagent-core-dev/<version>/
        voltagent-lang/<version>/
        voltagent-qa-sec/<version>/
        ...
          由 claude plugin install 写入
          作用：Claude Code plugin 包和 subagent 文件缓存
```

最重要的是这两类内容：

```text
~/.claude/CLAUDE.md
~/.claude/plugins/cache/voltagent-subagents/
```

前者告诉主 agent 怎么工作，后者告诉 Claude Code runtime 有哪些 plugin subagents 可以被派发。

对应关系：

| 路径 | 创建者 | 是否 Claude Code 默认自带 |
|---|---|---|
| `~/.claude/` | Claude Code / 用户历史配置 | 是 |
| `~/.claude/CLAUDE.md` | `setup-claude-code-workflow.sh` | 否 |
| `~/.claude/plugins/marketplaces/voltagent-subagents/` | `claude plugin marketplace add` | 否 |
| `~/.claude/plugins/cache/voltagent-subagents/` | `claude plugin install` | 否 |

## 本目录文件职责

```text
voltagent-claude-code/
  README.md
    目录入口和文件职责索引

  voltagent-claude-code-快速开始.md
    面向用户的完整复现步骤，也就是本文

  ClaudeCode插件多角色Agent工作机制.md
    详细机制说明、心智模型、目录关系

  CLAUDE.md
    要安装到 ~/.claude/CLAUDE.md 或项目 CLAUDE.md 的工作流规则模板

  setup-claude-code-workflow.sh
    安装工作流规则

  setup-claude-code-subagents.sh
    从 GitHub marketplace 安装或更新 Claude Code plugins
```

脚本关系：

```text
setup-claude-code-workflow.sh
  直接给用户执行
  输入：本目录 CLAUDE.md
  输出：~/.claude/CLAUDE.md

setup-claude-code-subagents.sh
  直接给用户执行
  输入：VoltAgent/awesome-claude-code-subagents marketplace
  输出：~/.claude/plugins/marketplaces 和 ~/.claude/plugins/cache
```

## 安装工作流规则

进入本目录：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-claude-code
```

先预览：

```bash
./setup-claude-code-workflow.sh --dry-run
```

写入全局规则：

```bash
./setup-claude-code-workflow.sh
```

默认写入：

```text
~/.claude/CLAUDE.md
```

如果目标文件已存在，脚本会停止。确认要覆盖时：

```bash
./setup-claude-code-workflow.sh --force
```

覆盖前会生成备份：

```text
~/.claude/CLAUDE.md.bak.YYYYMMDDHHMMSS
```

项目级安装是可选项，适合只想让某个仓库使用这套规则：

```bash
# 在目标项目根目录执行
/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-claude-code/setup-claude-code-workflow.sh --project
```

项目级写入：

```text
目标项目/CLAUDE.md
```

## 安装 Claude Code plugins

先预览：

```bash
./setup-claude-code-subagents.sh --dry-run
```

安装或更新全部 VoltAgent plugins：

```bash
./setup-claude-code-subagents.sh
```

脚本会做这些事：

```text
claude plugin marketplace add VoltAgent/awesome-claude-code-subagents
  ↓
安装或更新 10 个 VoltAgent Claude Code plugins
  ↓
Claude Code 写入 ~/.claude/plugins/marketplaces 和 ~/.claude/plugins/cache
```

只列出默认安装的 plugins：

```bash
./setup-claude-code-subagents.sh --list
```

只安装指定 plugins：

```bash
./setup-claude-code-subagents.sh --plugins=voltagent-core-dev,voltagent-lang,voltagent-qa-sec
```

## 安装后验证

验证工作流规则：

```bash
test -f ~/.claude/CLAUDE.md
```

`test -f` 没有输出就是成功；如果失败，终端会返回非 0 状态。

验证插件缓存：

```bash
test -d ~/.claude/plugins/marketplaces/voltagent-subagents
test -d ~/.claude/plugins/cache/voltagent-subagents
```

在 Claude Code 中打开：

```text
/plugin
```

确认需要的 VoltAgent plugins 已安装并启用。然后重启 Claude Code，或运行：

```text
/reload-plugins
```

在 Claude Code 中可以这样使用：

```text
Use voltagent-lang:typescript-pro to inspect this TypeScript issue.
Use voltagent-core-dev:api-designer to design this API contract.
Use voltagent-qa-sec:code-reviewer to review the current diff.
Use voltagent-qa-sec:security-auditor to review the auth flow.
```

如果使用本目录的 `CLAUDE.md` 工作流规则，代码任务开始时 Claude Code 应该先询问：

```text
选择工作流：

1. plan -> subagent -> review -> verify（完整多 agent 流水线）
2. Just do it（直接执行，最后验证）

请回复 1 或 2。
```

## 更新

更新 plugins：

```bash
./setup-claude-code-subagents.sh
```

或在 Claude Code 中：

```text
/plugin
```

进入插件管理界面后更新 marketplace 或对应 plugin。

更新工作流规则：

```bash
./setup-claude-code-workflow.sh --force
```

## 回滚

工作流规则回滚：

```text
~/.claude/CLAUDE.md.bak.YYYYMMDDHHMMSS
```

脚本覆盖前会生成备份，可以用备份内容恢复。

plugin 卸载可以在 Claude Code 的 `/plugin` 界面操作，也可以使用 Claude Code CLI 的 plugin uninstall 命令。卸载前先确认插件名称和 marketplace 名称：

```text
/plugin
```

不要直接删除整个 `~/.claude/`，也不要把 `~/.claude` 整体提交到 git。

## 常见问题

### 是否需要从旧版 `setup-claude-multiagent.sh` 迁移

不需要。新版目录直接从 `VoltAgent/awesome-claude-code-subagents` marketplace 安装，适合交给其他人复现。

### 只执行 `setup-claude-code-subagents.sh` 够不够

只安装 plugins 可以让 Claude Code 看到专家角色，但不会自动建立“先选工作流、再派发、最后 review/verify”的规则。完整复现建议两个脚本都执行：

```bash
./setup-claude-code-workflow.sh
./setup-claude-code-subagents.sh
```

### `CLAUDE.md` 里要不要写全部 agent 描述

不建议。完整身份描述已经在 plugin 包里。`CLAUDE.md` 只写工作规则和高频路由，避免重复加载大量描述，也避免和上游更新不同步。

### plugin 方式和手动复制 `.md` agents 有什么区别

plugin 方式是 Claude Code 原生插件机制，agent 名称带命名空间，例如 `voltagent-lang:typescript-pro`。手动复制 `.md` agents 通常放到 `~/.claude/agents/` 或项目 `.claude/agents/`，agent 名称不带 plugin namespace。

本目录主路径使用 plugin 方式。
