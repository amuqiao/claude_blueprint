# VoltAgent Roles for Claude Code

本目录提供 Claude Code 版 VoltAgent roles 的公共文档、公共安装脚本和多个模式配置。主目录负责文档说明；`scripts/` 负责安装入口和具体模式配置。

Claude Code 的接入方式和 Codex、DeepSeek Harness 不同：这里使用 Claude Code 原生 plugin marketplace 安装专家插件，用 `CLAUDE.md` 写工作流规则。

## 先读哪篇

```text
第一次安装 / 给别人复现：
  读 voltagent-claude-code-快速开始.md

想理解 Claude Code 为什么这样实现：
  读 ClaudeCode插件多角色Agent工作机制.md

只想看脚本用途：
  看本文的“目录职责”
```

## 目录职责

| 路径 | 职责 | 用户是否直接执行 |
|---|---|---|
| [voltagent-claude-code-快速开始.md](./voltagent-claude-code-快速开始.md) | 完整安装、验证、使用、排查流程 | 阅读 |
| [ClaudeCode插件多角色Agent工作机制.md](./ClaudeCode%E6%8F%92%E4%BB%B6%E5%A4%9A%E8%A7%92%E8%89%B2Agent%E5%B7%A5%E4%BD%9C%E6%9C%BA%E5%88%B6.md) | Claude Code plugin 多角色机制、目录关系、常见误解 | 阅读 |
| [scripts/setup-claude-code-workflow.sh](./scripts/setup-claude-code-workflow.sh) | 公共工作流规则安装入口，通过 `--preset-dir` 选择模式配置目录 | 是 |
| [scripts/setup-claude-code-voltagent-plugins.sh](./scripts/setup-claude-code-voltagent-plugins.sh) | 公共专家插件安装入口，通过 `--preset-dir` 选择模式配置目录 | 是 |
| [scripts/voltagent-roles-lite/](./scripts/voltagent-roles-lite/) | 推荐日常使用的 lite 专家插件配置，包含 `CLAUDE.md` 和 `PLUGIN_ALLOWLIST.txt` | 否 |
| [scripts/voltagent-roles/](./scripts/voltagent-roles/) | 默认专家插件配置，包含 `CLAUDE.md` 和全量 plugin allowlist | 否 |
| [scripts/voltagent-roles-full/](./scripts/voltagent-roles-full/) | 全量专家插件配置，可单独维护全量模式规则 | 否 |

三个模式目录都通过 `PLUGIN_ALLOWLIST.txt` 明确声明要安装哪些 Claude Code plugins。`voltagent-roles-lite` 当前安装 8 个常用插件；`voltagent-roles` 和 `voltagent-roles-full` 当前安装 10 个上游插件。

## 最短复现路径

先确认本机已有 Claude Code CLI 和 git：

```bash
claude --version
git --version
```

安装推荐的 lite 专家插件模式：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-claude-code/scripts

./setup-claude-code-workflow.sh --preset-dir=voltagent-roles-lite
./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite
```

脚本按内容保证幂等：重复执行同样输入时，`CLAUDE.md` 内容一致会 no-op；内容不同的 `CLAUDE.md` 需要显式加 `--force` 才会覆盖并生成备份。插件脚本会按 allowlist 安装或更新对应 Claude Code plugins。

最后重启 Claude Code，或在 Claude Code 中运行：

```text
/reload-plugins
```

## 本方案新增配置

Claude Code 自身读取 `CLAUDE.md` 作为工作规则，通过 plugin marketplace 安装和加载 subagents。本文脚本只负责额外写入下面几类内容：

```text
~/.claude/CLAUDE.md
  由 ./scripts/setup-claude-code-workflow.sh --preset-dir=<mode> 写入
  作用：Claude Code 工作流规则

~/.claude/plugins/marketplaces/voltagent-subagents/
  由 claude plugin marketplace add/update 写入
  作用：缓存 https://github.com/VoltAgent/awesome-claude-code-subagents

~/.claude/plugins/cache/voltagent-subagents/
  由 claude plugin install/update 写入
  作用：Claude Code plugin 包和 subagent 文件缓存
```

运行时关系：

```text
CLAUDE.md
  告诉主 agent 什么时候问工作流、什么时候派发 subagent、怎么 review/verify

Claude Code plugins
  告诉 Claude Code runtime 有哪些 namespaced subagents
  示例：voltagent-lang:typescript-pro、voltagent-qa-sec:code-reviewer
```
