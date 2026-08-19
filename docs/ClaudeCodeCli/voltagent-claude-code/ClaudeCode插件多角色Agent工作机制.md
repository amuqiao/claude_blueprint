# Claude Code 插件多角色 Agent 工作机制

本文解释 Claude Code 为什么可以通过 `CLAUDE.md + plugin subagents` 实现多角色 agent 协作。它不是安装手册；只想复制命令安装时，读 [快速开始](./voltagent-claude-code-快速开始.md)。

## 一句话心智模型

```text
CLAUDE.md 是交通规则
Claude Code plugins 是专家名册
Claude Code runtime 是调度系统
主 agent 按规则选择专家，把子任务交给 plugin subagent，再汇总结果
```

这和 Codex、DeepSeek Harness 的配置入口不同：

```text
Codex:
  AGENTS.md + ~/.codex/agents/*.toml

DeepSeek Harness:
  AGENTS.md + ~/.dsh/.agent-presets/<preset>/agent.cordis.yml

Claude Code:
  CLAUDE.md + Claude Code plugins
```

## 三层关系

```text
LLM / Model
  负责推理和生成

Claude Code runtime
  负责读仓库、执行工具、加载 CLAUDE.md、管理 plugin 和 subagent

配置与插件
  CLAUDE.md
    工作流规则

  Claude Code plugins
    subagent 身份定义和命名空间
```

不要把这三层混在一起：`CLAUDE.md` 不安装 plugin；plugin 不决定你的工作流；runtime 负责把两者组合起来。

## `CLAUDE.md` 是什么

`CLAUDE.md` 是给 Claude 主 agent 的工作规则。它不是 plugin 安装文件，也不是完整 agent 名录。

在本目录中，`CLAUDE.md` 负责规定：

```text
任务开始前：
  先问用户选择工作流

选择工作流 1：
  plan -> subagent -> review -> verify

选择工作流 2：
  主 agent 直接执行，最后验证

派发 subagent 时：
  使用已安装 plugin 暴露出来的 namespaced agents

完成前：
  必须 review 和 verify
```

这类规则适合放在：

```text
~/.claude/CLAUDE.md
  全局规则，所有 Claude Code 项目可用

项目根目录/CLAUDE.md
  项目级规则，只影响当前项目
```

## Claude Code plugin 是什么

Claude Code plugin 是 Claude Code runtime 可安装、启用、禁用和更新的扩展包。VoltAgent 的 Claude Code 仓库把不同类别的 subagents 分成多个 plugin。

安装后，agent 名称带 plugin namespace：

```text
voltagent-lang:typescript-pro
voltagent-core-dev:api-designer
voltagent-qa-sec:code-reviewer
```

这个 namespace 很重要。Claude Code plugin 方式下，不建议把 `voltagent-lang:typescript-pro` 省略成裸名 `typescript-pro`，因为裸名更像手动 `.claude/agents` 安装方式。

## 本目录的模式配置是什么

本目录把可复现配置分成公共脚本和模式目录：

```text
scripts/
  setup-claude-code-workflow.sh
    读取 <preset-dir>/CLAUDE.md
    写入 ~/.claude/CLAUDE.md 或项目 CLAUDE.md

  setup-claude-code-voltagent-plugins.sh
    读取 <preset-dir>/PLUGIN_ALLOWLIST.txt
    调用 claude plugin marketplace / install / update

  voltagent-roles-lite/
    CLAUDE.md
    PLUGIN_ALLOWLIST.txt

  voltagent-roles/
    CLAUDE.md
    PLUGIN_ALLOWLIST.txt

  voltagent-roles-full/
    CLAUDE.md
    PLUGIN_ALLOWLIST.txt
```

`PLUGIN_ALLOWLIST.txt` 不是 Claude Code runtime 配置文件。它只是安装脚本的输入，用来显式控制要安装哪些 plugins，避免脚本在清单缺失时意外安装全量插件。

## 本目录如何使用上游仓库

上游源是：

```text
https://github.com/VoltAgent/awesome-claude-code-subagents
```

安装脚本走 Claude Code 原生 plugin 命令：

```text
claude plugin marketplace add VoltAgent/awesome-claude-code-subagents
  ↓
claude plugin install voltagent-core-dev@voltagent-subagents
claude plugin install voltagent-lang@voltagent-subagents
...
  ↓
Claude Code 写入 ~/.claude/plugins/marketplaces 和 ~/.claude/plugins/cache
```

lite 模式当前安装 8 个常用 plugins：

```text
voltagent-core-dev
voltagent-lang
voltagent-infra
voltagent-qa-sec
voltagent-data-ai
voltagent-dev-exp
voltagent-meta
voltagent-research
```

默认模式和全量模式当前安装 10 个上游 plugins，在 lite 基础上增加：

```text
voltagent-domains
voltagent-biz
```

## 为什么还需要工作流复制脚本

只安装 plugin，Claude Code 就知道“有哪些 subagents”。但它不一定会自动按你想要的方式组织任务。

所以本目录把配置分成两步：

```text
setup-claude-code-workflow.sh
  安装 CLAUDE.md
  解决“主 agent 如何组织工作流”

setup-claude-code-voltagent-plugins.sh
  安装或更新 Claude Code plugins
  解决“有哪些专家可以派发”
```

两者合起来才是完整多 agent 机制：

```text
CLAUDE.md
  提供流程规则

Claude Code plugins
  提供专家身份

Claude Code runtime
  负责加载规则、识别 plugin subagents、派发 subagents、汇总结果
```

## 安装后的目录关系

全局安装后：

```text
~/.claude/
  CLAUDE.md
    工作流规则，由 setup-claude-code-workflow.sh 写入

  plugins/
    marketplaces/
      voltagent-subagents/
        从 VoltAgent/awesome-claude-code-subagents 取得的 marketplace 缓存

    cache/
      voltagent-subagents/
        voltagent-core-dev/<version>/
        voltagent-lang/<version>/
        voltagent-qa-sec/<version>/
        ...
          Claude Code plugin 安装缓存
```

项目级工作流安装后：

```text
项目根目录/
  CLAUDE.md
    项目级工作流规则
```

## 常见误解

### 是否要把 `~/.claude` 整个提交到 git

不建议。`~/.claude` 是运行时 home/config 目录，里面可能包含登录态、缓存、会话、日志、本机路径和个人配置。应该提交的是本目录里的模板、脚本和文档，而不是运行时目录。

### plugin 方式和手动 `.claude/agents` 方式一样吗

不一样。plugin 方式由 Claude Code 管理安装、启用、禁用和更新，agent 名称带 plugin namespace。手动方式是把 agent 文件复制到 `~/.claude/agents/` 或项目 `.claude/agents/`，通常不带 plugin namespace。

本目录主路径使用 plugin 方式，因为它更契合 Claude Code 的插件机制。

### `CLAUDE.md` 里要不要列出全部 agent

不建议。完整 agent 描述由 plugin 包提供。`CLAUDE.md` 应该写工作规则和高频路由，不应该复制完整 agent 名录。

### 只安装 plugin 够不够

只安装 plugin 可以让 Claude Code 看到专家角色，但不会自动建立“先选工作流、再派发、最后 review/verify”的规则。完整复现建议两个脚本都执行：

```bash
./setup-claude-code-workflow.sh --preset-dir=voltagent-roles-lite
./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite
```

## 术语清单

| 术语 | 中文说明 |
|---|---|
| LLM / Model | 大模型，负责生成和推理 |
| Agent runtime | agent 运行时，负责工具、文件、命令、上下文和子 agent 调度 |
| Claude Code | Anthropic 的编码 agent runtime / CLI 环境 |
| `CLAUDE.md` | Claude Code 读取的工作规则文件 |
| Plugin | Claude Code 可安装、启用、禁用和更新的扩展包 |
| Marketplace | plugin 来源仓库登记 |
| Subagent | 被主 agent 派发的子 agent |
| Namespace | plugin agent 的前缀，例如 `voltagent-lang:` |
| `PLUGIN_ALLOWLIST.txt` | 本目录安装脚本读取的 plugin 清单，不是 runtime 配置 |
| `~/.claude/plugins` | Claude Code 全局 plugin 目录 |
| `~/.claude/agents` | 手动安装 subagent 文件时使用的目录 |
