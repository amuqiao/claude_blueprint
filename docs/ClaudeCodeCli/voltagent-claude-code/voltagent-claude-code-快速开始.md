# VoltAgent Claude Code 快速开始

本文是一份可交给其他人复现的安装手册：先确认 Claude Code CLI 可用，再安装 `CLAUDE.md` 工作流规则，最后从 `VoltAgent/awesome-claude-code-subagents` 安装 Claude Code plugins。

如果你想先理解 Claude Code 为什么这样配置，读 [ClaudeCode插件多角色Agent工作机制.md](./ClaudeCode%E6%8F%92%E4%BB%B6%E5%A4%9A%E8%A7%92%E8%89%B2Agent%E5%B7%A5%E4%BD%9C%E6%9C%BA%E5%88%B6.md)。本文只保留安装、验证和排查所需的最少解释。

## 整体流程

```text
确认 Claude Code CLI
  claude --version
    ↓

选择模式配置
  scripts/voltagent-roles-lite/
    CLAUDE.md
    PLUGIN_ALLOWLIST.txt
    ↓

安装工作流规则
  scripts/setup-claude-code-workflow.sh --preset-dir=voltagent-roles-lite
    ↓ 写入 ~/.claude/CLAUDE.md

安装专家插件
  scripts/setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite
    ↓ claude plugin marketplace add/update VoltAgent/awesome-claude-code-subagents
    ↓ claude plugin install/update <plugin>@voltagent-subagents
    ↓ 写入 ~/.claude/plugins/marketplaces 与 ~/.claude/plugins/cache

使用
  重启 Claude Code 或运行 /reload-plugins
    ↓
  主 agent 按 CLAUDE.md 工作流规则派发 voltagent-lang:typescript-pro 等 plugin subagents
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

推荐安装 lite 专家插件模式：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-claude-code/scripts

./setup-claude-code-workflow.sh --preset-dir=voltagent-roles-lite
./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite
```

上面的 `cd` 是本文档所在机器的路径；提供给其他人时，把它替换成对方下载后的 `voltagent-claude-code/scripts` 目录路径。

如果 `~/.claude/CLAUDE.md` 已存在且内容不同，工作流脚本会停止，避免覆盖。确认要更新时使用：

```bash
./setup-claude-code-workflow.sh --preset-dir=voltagent-roles-lite --force
```

安装全量插件模式：

```bash
./setup-claude-code-workflow.sh --preset-dir=voltagent-roles-full
./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-full
```

## 模式目录

```text
scripts/
  setup-claude-code-workflow.sh
    公共工作流规则安装脚本

  setup-claude-code-voltagent-plugins.sh
    公共插件安装脚本

  voltagent-roles-lite/
    CLAUDE.md
    PLUGIN_ALLOWLIST.txt
      8 个常用插件，推荐日常使用

  voltagent-roles/
    CLAUDE.md
    PLUGIN_ALLOWLIST.txt
      10 个上游插件，默认专家模式

  voltagent-roles-full/
    CLAUDE.md
    PLUGIN_ALLOWLIST.txt
      10 个上游插件，可单独维护全量模式规则
```

`CLAUDE.md` 是工作流规则模板；`PLUGIN_ALLOWLIST.txt` 是安装插件清单。Claude Code runtime 不直接读取 `PLUGIN_ALLOWLIST.txt`，它只用于安装脚本确定要安装哪些 plugins。

## 安装工作流规则

进入脚本目录：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-claude-code/scripts
```

先预览：

```bash
./setup-claude-code-workflow.sh --preset-dir=voltagent-roles-lite --dry-run
```

写入全局规则：

```bash
./setup-claude-code-workflow.sh --preset-dir=voltagent-roles-lite
```

默认写入：

```text
~/.claude/CLAUDE.md
```

如果目标文件已存在且内容不同，脚本会停止。确认要覆盖时：

```bash
./setup-claude-code-workflow.sh --preset-dir=voltagent-roles-lite --force
```

覆盖前会生成备份：

```text
~/.claude/CLAUDE.md.bak.YYYYMMDDHHMMSS
```

项目级安装是可选项，适合只想让某个仓库使用这套规则：

```bash
# 在目标项目根目录执行
/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-claude-code/scripts/setup-claude-code-workflow.sh \
  --preset-dir=voltagent-roles-lite \
  --project
```

项目级写入：

```text
目标项目/CLAUDE.md
```

## 安装 Claude Code plugins

先预览：

```bash
./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite --dry-run
```

安装或更新 lite 模式 plugins：

```bash
./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite
```

脚本会做这些事：

```text
读取 voltagent-roles-lite/PLUGIN_ALLOWLIST.txt
  ↓
claude plugin marketplace add/update VoltAgent/awesome-claude-code-subagents
  ↓
安装或更新 allowlist 中的 plugins
  ↓
Claude Code 写入 ~/.claude/plugins/marketplaces 和 ~/.claude/plugins/cache
```

只列出当前模式会安装的 plugins：

```bash
./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite --list
```

安装到项目级 plugin scope：

```bash
./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite --scope=project
```

## 安装后验证

验证工作流规则：

```bash
test -f ~/.claude/CLAUDE.md
```

`test -f` 没有输出就是成功；如果失败，终端会返回非 0 状态。

验证 marketplace 和 plugins：

```bash
claude plugin marketplace list
claude plugin list
```

进入 Claude Code 后刷新：

```text
/reload-plugins
```

然后在 Claude Code 中查看：

```text
/plugin
```

可以用下面的句子测试 plugin subagent 是否可被识别：

```text
Use voltagent-lang:typescript-pro to inspect this TypeScript code.
Use voltagent-qa-sec:code-reviewer to review the current diff.
```

如果使用本目录的 `CLAUDE.md` 工作流规则，代码任务开始时 Claude Code 应该先询问：

```text
选择工作流：

1. plan -> subagent -> review -> verify（完整多 agent 流水线）
2. Just do it（直接执行，最后验证）

请回复 1 或 2。
```

## 常见问题

### 只执行插件脚本够不够

不够完整。只安装 plugin，Claude Code 能看到专家角色，但没有本文定义的“先选工作流、再派发、最后 review/verify”规则。完整复现建议两个脚本都执行：

```bash
./setup-claude-code-workflow.sh --preset-dir=voltagent-roles-lite
./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite
```

### `CLAUDE.md` 里要不要写全部 agent 描述

不建议。完整身份描述已经在 plugin 包里。`CLAUDE.md` 只写工作规则和高频路由，避免重复维护大量描述，也避免和上游更新不同步。

### `PLUGIN_ALLOWLIST.txt` 是运行时配置吗

不是。它只给安装脚本读取，用来决定安装哪些 Claude Code plugins。真正被 Claude Code runtime 加载的是安装后的 plugin，以及 `CLAUDE.md` 工作流规则。
