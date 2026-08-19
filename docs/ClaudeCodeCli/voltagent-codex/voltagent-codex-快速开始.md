# VoltAgent Codex 快速开始

本文是一份可交给其他人复现的安装手册：先确认 Codex CLI 可用，再从 `VoltAgent/awesome-codex-subagents` 安装 Codex 原生 custom agents，最后复制 `AGENTS.md` 工作流规则，让 Codex 按“先选工作流、按需派发专家、最后 review/verify”的方式协作。

如果你想先理解 Codex 为什么这样配置，读 [Codex多角色Agent工作机制.md](./Codex%E5%A4%9A%E8%A7%92%E8%89%B2Agent%E5%B7%A5%E4%BD%9C%E6%9C%BA%E5%88%B6.md)。本文只保留安装、验证和排查所需的最少解释。

## 整体流程

```text
确认 Codex CLI
  codex --version
    ↓

选择 scripts/ 下的模式目录
  scripts/voltagent-roles-lite/
    推荐日常使用，AGENTS.md 路由 67 个常用专家

  scripts/voltagent-roles/
    默认专家模式，AGENTS.md 路由 80 个高频专家

  scripts/voltagent-roles-full/
    全量专家模式，AGENTS.md 可单独维护 172 个全量路由

安装工作流规则
  scripts/setup-codex-workflow.sh
    ↓ 通过 --preset-dir 读取对应模式目录
    ↓ 写入 ~/.codex/AGENTS.md

安装专家角色
  scripts/setup-codex-voltagent-roles.sh
    ↓ 通过 --preset-dir 读取对应模式目录
    ↓ 在线：clone/update VoltAgent/awesome-codex-subagents
    ↓ 离线：读取 --local-source 指定的本地源码目录
    ↓ 全量复制 .toml 到 ~/.codex/agents/

使用
  重启或刷新 Codex 会话
    ↓
  Codex runtime 读取 AGENTS.md 和 ~/.codex/agents/*.toml
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

## 目录结构

```text
voltagent-codex/
  README.md
    目录入口和文件职责索引

  voltagent-codex-快速开始.md
    面向用户的完整复现步骤，也就是本文

  Codex多角色Agent工作机制.md
    详细机制说明、心智模型、目录关系

  scripts/
    setup-codex-workflow.sh
      公共工作流规则安装入口，通过 --preset-dir 选择模式配置目录

    setup-codex-voltagent-roles.sh
      公共专家角色安装入口，通过 --preset-dir 选择模式配置目录

    voltagent-roles-lite/
      ROUTE_ALLOWLIST.txt
        lite 模式路由参考清单，当前 67 个

      AGENTS.md
        要安装到 ~/.codex/AGENTS.md 的 lite 工作流规则模板

    voltagent-roles/
      ROUTE_ALLOWLIST.txt
        默认模式路由参考清单，当前 80 个

      AGENTS.md
        要安装到 ~/.codex/AGENTS.md 的工作流规则模板

    voltagent-roles-full/
      ROUTE_ALLOWLIST.txt
        全量模式路由参考清单，当前 172 个

      AGENTS.md
        全量模式独立工作流规则模板
```

## 安装推荐 lite 专家角色模式

lite 模式会安装：

```text
~/.codex/AGENTS.md
~/.codex/agents/*.toml
```

它会从 `VoltAgent/awesome-codex-subagents` 全量安装 Codex custom agents；`voltagent-roles-lite/ROUTE_ALLOWLIST.txt` 只记录 `AGENTS.md` 中建议优先路由的 67 个常用专家。这个模式适合日常使用：专家池完整，但工作流规则保持轻量。

执行前可以先查看脚本内置示例：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex/scripts

./setup-codex-workflow.sh -h
./setup-codex-voltagent-roles.sh -h
```

执行：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex/scripts

./setup-codex-workflow.sh --preset-dir=voltagent-roles-lite
./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles-lite
```

脚本可以重复执行：如果 `AGENTS.md` 内容已经一致，会直接提示已是最新。只有目标内容不同或存在同名未登记 agent 时，才需要显式加 `--force`：

```bash
./setup-codex-workflow.sh --preset-dir=voltagent-roles-lite --force
./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles-lite --force
```

## 安装默认专家角色模式

默认模式同样全量安装上游 `.toml`，但 `voltagent-roles/AGENTS.md` 保持 80 个高频专家路由。`voltagent-roles/ROUTE_ALLOWLIST.txt` 是这 80 个路由角色的参考真源。

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex/scripts

./setup-codex-workflow.sh --preset-dir=voltagent-roles
./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles
```

确认覆盖时：

```bash
./setup-codex-workflow.sh --preset-dir=voltagent-roles --force
./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles --force
```

## 安装全量专家角色模式

全量模式同样全量安装上游 `.toml`。它和默认模式的区别在规则层：你可以单独维护 `voltagent-roles-full/AGENTS.md`，让它更偏向 172 个全量专家路由；Codex runtime 仍然直接读取 `.toml` 身份定义。

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex/scripts

./setup-codex-workflow.sh --preset-dir=voltagent-roles-full
./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles-full
```

确认覆盖时：

```bash
./setup-codex-workflow.sh --preset-dir=voltagent-roles-full --force
./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles-full --force
```

## 离线安装

如果机器不能访问 GitHub，或你已经把 `VoltAgent/awesome-codex-subagents` 下载到本地，可以用 `--local-source` 指定源码目录。这个参数会跳过 `git clone/pull`。

本地目录应类似：

```text
awesome-codex-subagents/
  categories/
    01-core-development/
      api-designer.toml
      backend-developer.toml
      ...
```

例如使用当前仓库内的离线源码目录安装 lite 模式：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex/scripts

./setup-codex-workflow.sh --preset-dir=voltagent-roles-lite
./setup-codex-voltagent-roles.sh \
  --preset-dir=voltagent-roles-lite \
  --local-source=/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/awesome-codex-subagents
```

默认模式和全量模式使用同样参数，只需要改 `--preset-dir`。

脚本会在前置检查阶段确认本地目录存在，并统计 `.toml` 角色文件数量。三种模式都会全量安装上游 `.toml`；`--preset-dir` 只决定显示哪个模式、读取哪个 `AGENTS.md` 工作流模板，以及展示哪个 `ROUTE_ALLOWLIST.txt` 路由参考数量。

## `~/.codex` 生成结果

执行公共脚本并指定 `--preset-dir` 后，会额外新增或更新对应内容。

```text
~/.codex/
  AGENTS.md
    由 setup-codex-workflow.sh 写入
    作用：Codex 工作流规则

  _awesome-codex-subagents/
    由 setup-codex-voltagent-roles.sh clone/update
    作用：缓存 https://github.com/VoltAgent/awesome-codex-subagents.git
    仅在线安装模式使用；离线安装时读取 --local-source 指定目录

  agents/
    api-designer.toml
    code-reviewer.toml
    typescript-pro.toml
    ...
      由 setup-codex-voltagent-roles.sh 从上游 categories/**/*.toml 复制

    .voltagent-codex-subagents-v1.txt
      本脚本安装清单
```

最重要的是这两类文件：

```text
~/.codex/AGENTS.md
~/.codex/agents/*.toml
```

前者告诉主 agent 怎么工作，后者告诉 Codex runtime 有哪些专家角色可以被派发。

## 验证

验证工作流规则：

```bash
test -f ~/.codex/AGENTS.md
grep -n 'Codex Multi-Agent Workflow' ~/.codex/AGENTS.md
```

验证 lite 专家角色：

```bash
test -f ~/.codex/agents/api-designer.toml
test -f ~/.codex/agents/code-reviewer.toml
wc -l ~/.codex/agents/.voltagent-codex-subagents-v1.txt
```

最后一条应输出当前上游全量角色数量，例如当前是 `172`。`ROUTE_ALLOWLIST.txt` 不影响安装数量，只用于维护对应模式的 `AGENTS.md` 路由范围。

验证本地源码中可安装角色：

```bash
./setup-codex-voltagent-roles.sh \
  --preset-dir=voltagent-roles-lite \
  --local-source=/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/awesome-codex-subagents \
  --list
```

## 项目级安装

项目级安装适合只想让某个仓库使用这套规则和角色。需要在目标项目目录中执行脚本，或通过绝对路径调用脚本。

```bash
cd /path/to/target-project

/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex/scripts/setup-codex-workflow.sh \
  --preset-dir=voltagent-roles-lite \
  --project

/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-codex/scripts/setup-codex-voltagent-roles.sh \
  --preset-dir=voltagent-roles-lite \
  --project
```

项目级写入：

```text
目标项目/AGENTS.md
目标项目/.codex/agents/*.toml
目标项目/.codex/agents/.voltagent-codex-subagents-v1.txt
```

## 常见问题

### 只安装 workflow 可以吗

只能得到工作流规则，不能得到 custom agents。完整流程需要执行两个脚本：

```bash
./setup-codex-workflow.sh --preset-dir=<mode>
./setup-codex-voltagent-roles.sh --preset-dir=<mode>
```

### 只安装 roles 可以吗

Codex 会看到 `.toml` custom agents，但主 agent 不一定按你期望的流程先问工作流、再 review/verify。建议两个脚本都执行。

### `ROUTE_ALLOWLIST.txt` 是给 Codex 读取的吗

不是。它是给人和维护脚本看的路由参考真源，用来说明当前模式的 `AGENTS.md` 应重点覆盖哪些专家。Codex runtime 真正读取的是最终安装到 `~/.codex/agents/*.toml` 的文件；安装脚本会全量复制上游 `.toml`。

### 切换模式是否会重复安装

不会按目录重复安装；三种模式都写入同一个目标 `agents/` 目录。脚本会根据 manifest 管理本脚本安装过的 `.toml`，并全量复制当前上游角色。

### 如何停用

停用全局工作流规则：

```bash
mv ~/.codex/AGENTS.md ~/.codex/AGENTS.md.disabled.YYYYMMDDHHMMSS
```

停用本脚本安装的 agents：

```bash
mkdir -p ~/.codex/agents.disabled.YYYYMMDDHHMMSS
while read -r file; do
  mv ~/.codex/agents/"$file" ~/.codex/agents.disabled.YYYYMMDDHHMMSS/
done < ~/.codex/agents/.voltagent-codex-subagents-v1.txt
```
