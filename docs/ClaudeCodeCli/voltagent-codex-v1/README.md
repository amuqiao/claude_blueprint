# VoltAgent Codex Subagents v1

本目录提供一套可复现流程：直接从 `VoltAgent/awesome-codex-subagents` 上游仓库安装 Codex 原生 custom agents，并复制一份多 agent 工作流规则到 Codex 的 `AGENTS.md`。

## 先读哪篇

```text
第一次安装 / 给别人复现：
  读 voltagent-codex-快速开始v1.md

想理解为什么这样实现：
  读 Codex多角色Agent工作机制.md

只想看脚本用途：
  看本文的“文件职责”
```

## 文件职责

| 文件 | 职责 | 用户是否直接执行 |
|---|---|---|
| [voltagent-codex-快速开始v1.md](./voltagent-codex-快速开始v1.md) | 完整安装、验证、使用、排查流程 | 阅读 |
| [Codex多角色Agent工作机制.md](./Codex%E5%A4%9A%E8%A7%92%E8%89%B2Agent%E5%B7%A5%E4%BD%9C%E6%9C%BA%E5%88%B6.md) | 详细机制说明、心智模型、目录关系 | 阅读 |
| [AGENTS.md](./AGENTS.md) | Codex 多 agent 工作流规则模板 | 不直接执行，由脚本复制 |
| [setup-codex-workflow.sh](./setup-codex-workflow.sh) | 安装 `~/.codex/AGENTS.md` 或项目 `AGENTS.md` | 是 |
| [setup-codex-subagents-v1.sh](./setup-codex-subagents-v1.sh) | 从 GitHub 上游安装 `~/.codex/agents/*.toml` 或项目 `.codex/agents/*.toml` | 是 |
| [AGENTS_80.md](./AGENTS_80.md) | 旧整理过程中的 80 路由模板参考 | 否 |
| [AGENTS_51.md](./AGENTS_51.md) | 旧整理过程中的 51 路由模板参考 | 否 |

## 最短复现路径

先确认本机已有 Codex CLI 和 git：

```bash
codex --version
git --version
```

然后执行本目录脚本：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex-v1

./setup-codex-workflow.sh
./setup-codex-subagents-v1.sh
```

上面的 `cd` 是本文档所在机器的路径；提供给其他人时，把它替换成对方下载后的 `voltagent-codex-v1` 目录路径。

最后重启或刷新 Codex 会话。

## 本方案新增配置

Codex 自身读取 `AGENTS.md` 作为工作规则，读取 agents 目录中的 `.toml` 作为 custom agent 定义。本文脚本只负责额外写入下面几类内容：

```text
~/.codex/AGENTS.md
  由 setup-codex-workflow.sh 写入
  作用：工作流规则

~/.codex/_awesome-codex-subagents/
  由 setup-codex-subagents-v1.sh clone/update
  作用：GitHub 上游仓库缓存

~/.codex/agents/*.toml
  由 setup-codex-subagents-v1.sh 从上游 categories/**/*.toml 复制
  作用：Codex custom agent 身份定义
```

运行时关系：

```text
AGENTS.md
  告诉主 agent 什么时候问工作流、什么时候派发 subagent、怎么 review/verify

~/.codex/agents/*.toml
  告诉 Codex 有哪些 custom agents，以及每个 agent 的 name、description、instructions
```
