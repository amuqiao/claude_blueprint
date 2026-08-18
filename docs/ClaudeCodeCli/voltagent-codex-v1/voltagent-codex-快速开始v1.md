# VoltAgent Codex Subagents 快速开始 v1

本文是一份可交给其他人复现的安装手册：先确认 Codex CLI 可用，再从 `VoltAgent/awesome-codex-subagents` 安装 Codex 原生 custom agents，最后复制 `AGENTS.md` 工作流规则，让 Codex 可以按“先选工作流、再派发专家、最后 review/verify”的方式协作。

如果你想先理解 Codex 为什么这样配置，读 [Codex多角色Agent工作机制.md](./Codex%E5%A4%9A%E8%A7%92%E8%89%B2Agent%E5%B7%A5%E4%BD%9C%E6%9C%BA%E5%88%B6.md)。本文只保留安装、验证和排查所需的最少解释。

## 整体流程

先看完整链路，后面的步骤就是按这张图落地：

```text
确认 Codex CLI
  codex --version
    ↓

安装工作流规则
  setup-codex-workflow.sh
    ↓ 写入 ~/.codex/AGENTS.md

安装专家角色
  setup-codex-subagents-v1.sh
    ↓ clone/update VoltAgent/awesome-codex-subagents
    ↓ 读取 categories/**/*.toml
    ↓ 复制到 ~/.codex/agents/*.toml

使用
  重启或刷新 Codex 会话
    ↓
  主 agent 按 AGENTS.md 工作流规则派发 typescript-pro / api-designer / code-reviewer 等 subagent
```

这套方案使用 Codex 原生机制：

```text
~/.codex/AGENTS.md
  负责规则：什么时候问工作流、什么时候派发 subagent、怎么 review/verify

~/.codex/agents/*.toml
  负责身份：定义每个 custom agent 的 name、description、instructions
```

## 前置要求

需要本机已有：

```bash
codex --version
git --version
```

如果 `codex --version` 不存在，先完成 Codex CLI 安装和登录。本文不负责 Codex CLI 安装，只负责安装工作流规则和 custom agents。

## 一次性完整命令

如果你只是想按默认路径完整安装，可以直接复制下面这组命令：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex-v1

./setup-codex-workflow.sh
./setup-codex-subagents-v1.sh
```

上面的 `cd` 是本文档所在机器的路径；提供给其他人时，把它替换成对方下载后的 `voltagent-codex-v1` 目录路径。

如果目标文件已存在，脚本会停止，避免覆盖。确认要更新时使用：

```bash
./setup-codex-workflow.sh --force
./setup-codex-subagents-v1.sh --force
```

后面的章节会解释这些命令分别创建了什么文件、如何验证、以及出问题时怎么排查。

## `~/.codex` 目录结构

`~/.codex` 是 Codex 的全局配置目录。需要区分两件事：哪些是 Codex 自己已有的，哪些是本文脚本后续写入的。

### 安装本文脚本前

一台已经能运行 Codex 的机器上，`~/.codex` 可能已经有用户设置、登录状态、已有 agents 或其他 Codex 配置。具体内容取决于你的本机历史配置。

本文不要求清空 `~/.codex`，也不建议删除整个目录。

### 执行本文脚本后

执行本文两个脚本后，会新增或更新这些内容：

```text
~/.codex/
  AGENTS.md
    由 setup-codex-workflow.sh 写入
    作用：Codex 工作流规则

  _awesome-codex-subagents/
    由 setup-codex-subagents-v1.sh clone/update
    作用：缓存 https://github.com/VoltAgent/awesome-codex-subagents.git

  agents/
    api-designer.toml
    code-reviewer.toml
    typescript-pro.toml
    ...
      由 setup-codex-subagents-v1.sh 从上游 categories/**/*.toml 复制

    .voltagent-codex-subagents-v1.txt
      由 setup-codex-subagents-v1.sh 写入
      作用：记录本脚本安装过哪些 agents
```

最重要的是这两类文件：

```text
~/.codex/AGENTS.md
~/.codex/agents/*.toml
```

前者告诉主 agent 怎么工作，后者告诉 Codex runtime 有哪些专家角色可以被派发。

对应关系：

| 路径 | 创建者 | 是否 Codex 默认自带 |
|---|---|---|
| `~/.codex/` | Codex / 用户历史配置 | 是 |
| `~/.codex/AGENTS.md` | `setup-codex-workflow.sh` | 否 |
| `~/.codex/_awesome-codex-subagents/` | `setup-codex-subagents-v1.sh` | 否 |
| `~/.codex/agents/*.toml` | `setup-codex-subagents-v1.sh` | 否 |

## 本目录文件职责

```text
voltagent-codex-v1/
  README.md
    目录入口和文件职责索引

  voltagent-codex-快速开始v1.md
    面向用户的完整复现步骤，也就是本文

  Codex多角色Agent工作机制.md
    详细机制说明、心智模型、目录关系

  AGENTS.md
    要安装到 ~/.codex/AGENTS.md 或项目 AGENTS.md 的工作流规则模板

  setup-codex-workflow.sh
    安装工作流规则

  setup-codex-subagents-v1.sh
    从 GitHub 上游安装 Codex custom agents

  AGENTS_80.md / AGENTS_51.md
    历史模板参考，不是默认入口
```

脚本关系：

```text
setup-codex-workflow.sh
  直接给用户执行
  输入：本目录 AGENTS.md
  输出：~/.codex/AGENTS.md

setup-codex-subagents-v1.sh
  直接给用户执行
  输入：VoltAgent/awesome-codex-subagents
  输出：~/.codex/agents/*.toml
```

## 安装工作流规则

进入本目录：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex-v1
```

先预览：

```bash
./setup-codex-workflow.sh --dry-run
```

写入全局规则：

```bash
./setup-codex-workflow.sh
```

默认写入：

```text
~/.codex/AGENTS.md
```

如果目标文件已存在，脚本会停止。确认要覆盖时：

```bash
./setup-codex-workflow.sh --force
```

覆盖前会生成备份：

```text
~/.codex/AGENTS.md.bak.YYYYMMDDHHMMSS
```

项目级安装是可选项，适合只想让某个仓库使用这套规则：

```bash
# 在目标项目根目录执行
/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex-v1/setup-codex-workflow.sh --project
```

项目级写入：

```text
目标项目/AGENTS.md
```

## 安装 Codex custom agents

先预览：

```bash
./setup-codex-subagents-v1.sh --dry-run
```

全局安装：

```bash
./setup-codex-subagents-v1.sh
```

脚本会做这些事：

```text
clone/update https://github.com/VoltAgent/awesome-codex-subagents.git
  ↓
读取 categories/**/*.toml
  ↓
检查每个 agent 至少包含 name、description、instructions
  ↓
复制到 ~/.codex/agents/
  ↓
写入 ~/.codex/agents/.voltagent-codex-subagents-v1.txt
```

项目级安装是可选项：

```bash
# 在目标项目根目录执行
/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex-v1/setup-codex-subagents-v1.sh --project
```

项目级写入：

```text
目标项目/.codex/agents/*.toml
目标项目/.codex/agents/.voltagent-codex-subagents-v1.txt
```

只安装指定 agents：

```bash
./setup-codex-subagents-v1.sh --agents=typescript-pro,code-reviewer,security-auditor
```

只列出上游可安装 agents：

```bash
./setup-codex-subagents-v1.sh --list
```

如果目标目录已有同名 `.toml`，且该文件不在脚本生成的安装清单里，脚本会停止，避免覆盖你自己的 custom agent。确认要覆盖时显式加：

```bash
./setup-codex-subagents-v1.sh --force
```

## 安装后验证

验证工作流规则：

```bash
test -f ~/.codex/AGENTS.md
```

`test -f` 没有输出就是成功；如果失败，终端会返回非 0 状态。

验证 agents 文件：

```bash
test -f ~/.codex/agents/api-designer.toml
test -f ~/.codex/agents/code-reviewer.toml
test -f ~/.codex/agents/.voltagent-codex-subagents-v1.txt
find ~/.codex/agents -maxdepth 1 -name '*.toml' | wc -l
```

如果安装的是当前上游全部 agents，最后一条会输出当前可安装的 `.toml` 数量。数量以后续上游更新为准。

然后重启或刷新 Codex 会话。

在 Codex 中可以这样使用：

```text
用 typescript-pro 检查这个 TypeScript 类型问题。
用 api-designer 设计这个接口合同。
用 code-reviewer review 当前 diff。
用 security-auditor 检查认证流程。
```

如果使用本目录的 `AGENTS.md` 工作流规则，代码任务开始时 Codex 应该先询问：

```text
选择工作流：

1. plan -> subagent -> review -> verify（完整多 agent 流水线）
2. Just do it（直接执行，最后验证）

请回复 1 或 2。
```

## 更新

预览更新：

```bash
./setup-codex-subagents-v1.sh --dry-run
```

执行更新：

```bash
./setup-codex-subagents-v1.sh
```

脚本会对缓存仓库执行 `git pull --ff-only`，然后重新复制当前上游 `.toml` agents。安装子集时，脚本会清理上一轮 manifest 中记录、但本轮不再选择的 agents。

更新工作流规则：

```bash
./setup-codex-workflow.sh --force
```

## 回滚

工作流规则回滚：

```text
~/.codex/AGENTS.md.bak.YYYYMMDDHHMMSS
```

脚本覆盖前会生成备份，可以用备份内容恢复。

custom agents 回滚：

```text
~/.codex/agents/.voltagent-codex-subagents-v1.txt
```

这份清单记录了本脚本安装的 `.toml` 文件。清理时只删除清单内文件，不要直接删除整个 `~/.codex/agents/`，除非确认里面没有自己的 custom agents。

## 常见问题

### 是否需要从旧版 `~/.codex/agents` 迁移

不需要。v1 流程直接从 `VoltAgent/awesome-codex-subagents` 上游安装，适合交给其他人复现。

### 只执行 `setup-codex-subagents-v1.sh` 够不够

只安装 agents 可以让 Codex 看到专家角色，但不会自动建立“先选工作流、再派发、最后 review/verify”的规则。完整复现建议两个脚本都执行：

```bash
./setup-codex-workflow.sh
./setup-codex-subagents-v1.sh
```

### `AGENTS.md` 里要不要写全部 agent 描述

不建议。完整身份描述已经在 `~/.codex/agents/*.toml` 里。`AGENTS.md` 只写工作规则和高频路由，避免重复加载大量描述，也避免和上游更新不同步。

### `.voltagent-codex-subagents-v1.txt` 是否是 Codex 必需文件

不是。它是安装脚本的 manifest，帮助脚本区分“本脚本安装的 agent”和“用户自己写的 agent”。
