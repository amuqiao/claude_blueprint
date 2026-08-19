# VoltAgent Roles for Codex

本目录提供 Codex 版 VoltAgent roles 的公共文档、公共安装脚本和多个模式配置。主目录负责文档说明；`scripts/` 负责安装入口和具体模式配置。

## 先读哪篇

```text
第一次安装 / 给别人复现：
  读 voltagent-codex-快速开始.md

想理解 Codex 为什么这样实现：
  读 Codex多角色Agent工作机制.md

只想看脚本用途：
  看本文的“目录职责”
```

## 目录职责

| 路径 | 职责 | 用户是否直接执行 |
|---|---|---|
| [voltagent-codex-快速开始.md](./voltagent-codex-快速开始.md) | 完整安装、验证、使用、排查流程 | 阅读 |
| [Codex多角色Agent工作机制.md](./Codex%E5%A4%9A%E8%A7%92%E8%89%B2Agent%E5%B7%A5%E4%BD%9C%E6%9C%BA%E5%88%B6.md) | Codex 多角色机制、目录关系、常见误解 | 阅读 |
| [scripts/setup-codex-workflow.sh](./scripts/setup-codex-workflow.sh) | 公共工作流规则安装入口，通过 `--preset-dir` 选择模式配置目录 | 是 |
| [scripts/setup-codex-voltagent-roles.sh](./scripts/setup-codex-voltagent-roles.sh) | 公共专家角色安装入口，通过 `--preset-dir` 选择模式配置目录 | 是 |
| [scripts/voltagent-roles-lite/](./scripts/voltagent-roles-lite/) | 推荐日常使用的 lite 专家角色配置，按 `ROLE_ALLOWLIST.txt` 安装较少但覆盖常用领域的 `.toml` agents | 否 |
| [scripts/voltagent-roles/](./scripts/voltagent-roles/) | 默认专家角色配置，`ROLE_ALLOWLIST.txt` 固定全量角色集，`AGENTS.md` 保持精简路由规则 | 否 |
| [scripts/voltagent-roles-full/](./scripts/voltagent-roles-full/) | 全量专家角色配置，`ROLE_ALLOWLIST.txt` 固定全量角色集，`AGENTS.md` 可单独维护全量模式规则 | 否 |

三个模式目录都从 `VoltAgent/awesome-codex-subagents` 读取角色源，并通过各自的 `ROLE_ALLOWLIST.txt` 明确声明要安装哪些 Codex custom agents。`voltagent-roles-lite` 当前是 67 个常用专家；`voltagent-roles` 和 `voltagent-roles-full` 当前是 172 个全量专家。

## 最短复现路径

先确认本机已有 Codex CLI 和 git：

```bash
codex --version
git --version
```

安装推荐的 lite 专家角色模式：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex/scripts

./setup-codex-workflow.sh --preset-dir=voltagent-roles-lite
./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles-lite
```

离线安装时，把第二条命令改为指定本地源码目录：

```bash
./setup-codex-voltagent-roles.sh \
  --preset-dir=voltagent-roles-lite \
  --local-source=/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/awesome-codex-subagents
```

脚本按内容保证幂等：重复执行同样输入时，`AGENTS.md` 内容一致会 no-op；roles 安装会根据 manifest 管理本脚本安装过的 `.toml`。覆盖同名未登记 agent 或内容不同的 `AGENTS.md` 时，需要显式加 `--force`。

最后重启或刷新 Codex 会话。

## 本方案新增配置

Codex 自身读取 `AGENTS.md` 作为工作规则，读取 agents 目录中的 `.toml` 作为 custom agent 定义。本文脚本只负责额外写入下面几类内容：

```text
~/.codex/AGENTS.md
  由 ./scripts/setup-codex-workflow.sh --preset-dir=<mode> 写入
  作用：Codex 工作流规则

~/.codex/_awesome-codex-subagents/
  由 ./scripts/setup-codex-voltagent-roles.sh clone/update
  作用：缓存 https://github.com/VoltAgent/awesome-codex-subagents.git
  仅在线安装模式使用；离线安装时由 --local-source 指定源码目录

~/.codex/agents/*.toml
  由 ./scripts/setup-codex-voltagent-roles.sh 从上游 categories/**/*.toml 复制
  作用：Codex custom agent 身份定义

~/.codex/agents/.voltagent-codex-subagents-v1.txt
  由 ./scripts/setup-codex-voltagent-roles.sh 写入
  作用：记录本脚本安装过哪些 agents，避免误删或误覆盖用户自定义 agents
```

运行时关系：

```text
AGENTS.md
  告诉主 agent 什么时候问工作流、什么时候派发 subagent、怎么 review/verify

~/.codex/agents/*.toml
  告诉 Codex runtime 有哪些 custom agents，以及每个 agent 的 name、description、instructions
```
