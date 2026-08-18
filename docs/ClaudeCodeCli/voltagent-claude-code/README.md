# VoltAgent Claude Code Subagents

本目录提供一套可复现流程：通过 Claude Code 原生 plugin marketplace，从 `VoltAgent/awesome-claude-code-subagents` 安装 VoltAgent subagents，并复制一份多 agent 工作流规则到 Claude Code 的 `CLAUDE.md`。

## 先读哪篇

```text
第一次安装 / 给别人复现：
  读 voltagent-claude-code-快速开始.md

想理解为什么这样实现：
  读 ClaudeCode插件多角色Agent工作机制.md

只想看脚本用途：
  看本文的“文件职责”
```

## 文件职责

| 文件 | 职责 | 用户是否直接执行 |
|---|---|---|
| [voltagent-claude-code-快速开始.md](./voltagent-claude-code-快速开始.md) | 完整安装、验证、使用、排查流程 | 阅读 |
| [ClaudeCode插件多角色Agent工作机制.md](./ClaudeCode%E6%8F%92%E4%BB%B6%E5%A4%9A%E8%A7%92%E8%89%B2Agent%E5%B7%A5%E4%BD%9C%E6%9C%BA%E5%88%B6.md) | 详细机制说明、心智模型、目录关系 | 阅读 |
| [CLAUDE.md](./CLAUDE.md) | Claude Code 多 agent 工作流规则模板 | 不直接执行，由脚本复制 |
| [setup-claude-code-workflow.sh](./setup-claude-code-workflow.sh) | 安装 `~/.claude/CLAUDE.md` 或项目 `CLAUDE.md` | 是 |
| [setup-claude-code-subagents.sh](./setup-claude-code-subagents.sh) | 从 GitHub marketplace 安装或更新 Claude Code plugins | 是 |

## 最短复现路径

先确认本机已有 Claude Code CLI 和 git：

```bash
claude --version
git --version
```

然后执行本目录脚本：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-claude-code

./setup-claude-code-workflow.sh
./setup-claude-code-subagents.sh
```

上面的 `cd` 是本文档所在机器的路径；提供给其他人时，把它替换成对方下载后的 `voltagent-claude-code` 目录路径。

最后重启 Claude Code，或在 Claude Code 中运行：

```text
/reload-plugins
```

## 本方案新增配置

Claude Code 自身读取 `CLAUDE.md` 作为工作规则，通过 plugin marketplace 安装和加载 subagents。本文脚本只负责额外写入下面几类内容：

```text
~/.claude/CLAUDE.md
  由 setup-claude-code-workflow.sh 写入
  作用：工作流规则

~/.claude/plugins/marketplaces/voltagent-subagents/
  由 claude plugin marketplace add 写入或更新
  作用：GitHub 上游 marketplace 缓存

~/.claude/plugins/cache/voltagent-subagents/<plugin>/<version>/
  由 claude plugin install 写入
  作用：Claude Code plugin 包和 subagent 文件缓存
```

运行时关系：

```text
CLAUDE.md
  告诉 Claude 主 agent 什么时候问工作流、什么时候派发 subagent、怎么 review/verify

Claude Code plugins
  提供 voltagent-lang:typescript-pro、voltagent-qa-sec:code-reviewer 等带命名空间的 subagents
```
