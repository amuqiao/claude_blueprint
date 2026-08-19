# Codex 多角色 Agent 工作机制

本文解释 Codex 为什么可以通过 `AGENTS.md + agents/*.toml` 实现多角色 agent 协作。它不是安装手册；只想复制命令安装时，读 [快速开始](./voltagent-codex-快速开始.md)。

## 先理解这件事

大模型本身只负责根据上下文生成文本。真正决定“读哪些文件、用什么工具、派发哪个专家、最后怎么验证”的，是 Codex 这样的 agent runtime。

可以把 Codex 多角色协作理解成三层：

```text
LLM / Model
  负责推理和生成

Codex runtime
  负责读仓库、执行命令、管理上下文、加载规则、调用 subagent

配置文件
  AGENTS.md                 工作规则
  ~/.codex/agents/*.toml    全局 custom agent 身份定义
  .codex/agents/*.toml      项目级 custom agent 身份定义
```

所以，`VoltAgent/awesome-codex-subagents` 在 Codex 里不需要转换成插件，也不需要转换成 `agent.cordis.yml`。它提供的就是 Codex 可读取的 `.toml` custom agent 定义。

## Codex 的心智模型

Codex 里要区分两类配置：

```text
AGENTS.md
  写的是“主 agent 应该怎么工作”
  例如：先问工作流、什么时候派发 subagent、review 后再 verify

agents/*.toml
  写的是“有哪些可派发的专家”
  例如：typescript-pro、api-designer、code-reviewer、security-auditor
```

运行时可以这样理解：

```text
用户提出任务
  ↓
Codex 主 agent 读取 AGENTS.md
  ↓
AGENTS.md 要求先选择工作流
  ↓
用户选择完整多 agent 流程
  ↓
Codex 根据任务和已加载的 custom agents 选择 subagent
  ↓
subagent 按自己的 .toml 身份处理专项任务
  ↓
主 agent 汇总结果、修正、review、verify
```

## `AGENTS.md` 是什么

`AGENTS.md` 是给主 agent 的工作规则。它不是 agent 名录，也不是插件安装文件。

在本目录中，各模式目录都有自己的 `AGENTS.md`：

```text
scripts/voltagent-roles-lite/AGENTS.md
scripts/voltagent-roles/AGENTS.md
scripts/voltagent-roles-full/AGENTS.md
```

公共脚本会把你选择的那个模板复制到：

```text
~/.codex/AGENTS.md
  全局规则，所有 Codex 项目可用

项目根目录/AGENTS.md
  项目级规则，只影响当前项目
```

这些规则负责规定：

```text
任务开始前：
  先问用户选择工作流

选择工作流 1：
  plan -> subagent -> review -> verify

选择工作流 2：
  主 agent 直接执行，最后验证

派发 subagent 时：
  根据任务领域匹配 custom agent

完成前：
  必须 review 和 verify
```

## `agents/*.toml` 是什么

`.toml` 文件是 Codex custom agent 的身份定义。每个文件通常描述一个专家角色。

核心字段可以这样理解：

| 字段 | 作用 |
|---|---|
| `name` | agent 的真实调用名称 |
| `description` | Codex 判断何时适合使用它的描述 |
| `developer_instructions` 或 `[instructions]` | 这个 agent 的专业身份、工作方式和约束 |
| `model` / `model_reasoning_effort` | 该 agent 的模型或推理偏好 |
| `sandbox_mode` | 该 agent 的沙箱权限偏好 |

安装位置有两类：

```text
~/.codex/agents/*.toml
  全局 custom agents，所有项目可用

.codex/agents/*.toml
  项目级 custom agents，只在当前项目可用，通常优先级更高
```

## `ROUTE_ALLOWLIST.txt` 是什么

`ROUTE_ALLOWLIST.txt` 不是 Codex runtime 的配置文件，也不是安装清单。它是对应模式 `AGENTS.md` 的路由参考真源。

```text
ROUTE_ALLOWLIST.txt
  记录这个模式的 AGENTS.md 应重点覆盖哪些 agent 名称
  用于维护路由规则，不用于限制安装
```

也就是说：

```text
ROUTE_ALLOWLIST.txt
  决定该模式的 AGENTS.md 应重点提示哪些角色

AGENTS.md
  决定主 agent 如何使用这些角色

agents/*.toml
  Codex runtime 真正加载的 custom agent 定义；本方案默认全量安装
```

## 本目录如何使用上游仓库

`setup-codex-voltagent-roles.sh` 的源头是：

```text
https://github.com/VoltAgent/awesome-codex-subagents.git
```

脚本做的是直接安装，不做格式转换：

```text
clone/update 上游仓库
  ↓
读取 categories/**/*.toml
  ↓
检查 name、description、instructions 字段
  ↓
全量复制到 ~/.codex/agents/ 或 .codex/agents/
  ↓
写入 .voltagent-codex-subagents-v1.txt 安装清单
```

因为上游文件本身就是 Codex `.toml` custom agent，所以这里和 DeepSeek Harness 不同：

```text
Codex:
  上游 TOML 可以直接复制到 agents 目录

DeepSeek Harness:
  需要把上游 TOML 转成 Harness agent preset / Cordis plugin 配置
```

## 为什么分成 workflow 和 roles 两个脚本

只安装 `.toml`，Codex 就知道“有哪些专家”。但它不一定会自动按你想要的方式组织任务。

所以本目录把配置分成两步：

```text
setup-codex-workflow.sh
  安装 AGENTS.md
  解决“主 agent 如何组织工作流”

setup-codex-voltagent-roles.sh
  安装 agents/*.toml
  解决“有哪些专家可以派发”
```

两者合起来才是完整多 agent 机制：

```text
AGENTS.md
  提供流程规则

agents/*.toml
  提供专家身份

Codex runtime
  负责加载规则、识别 custom agents、派发 subagents、汇总结果
```

## 三种模式的含义

```text
voltagent-roles-lite
  ROUTE_ALLOWLIST.txt: 67 个常用路由角色
  AGENTS.md: Codex lite 工作流规则

voltagent-roles
  ROUTE_ALLOWLIST.txt: 80 个高频路由角色
  AGENTS.md: Codex 标准专家工作流规则

voltagent-roles-full
  ROUTE_ALLOWLIST.txt: 172 个全量路由角色
  AGENTS.md: 可单独维护全量专家模式规则
```

注意：三种模式都会全量安装上游 `.toml`。Codex runtime 会读取 `.toml` 中的 `description` 判断是否适合派发某个 custom agent。`AGENTS.md` 不需要重复列出完整 agent 名录；如果你希望某个模式更强调完整路由，可以只调整该模式目录下的 `AGENTS.md` 和 `ROUTE_ALLOWLIST.txt`。

## 安装后的目录关系

全局安装后：

```text
~/.codex/
  AGENTS.md
    工作流规则，由 setup-codex-workflow.sh 写入

  _awesome-codex-subagents/
    上游仓库缓存，由 setup-codex-voltagent-roles.sh clone/update

  agents/
    api-designer.toml
    code-reviewer.toml
    typescript-pro.toml
    ...
    .voltagent-codex-subagents-v1.txt
      本脚本安装清单
```

项目级安装后：

```text
项目根目录/
  AGENTS.md
    项目级工作流规则

  .codex/
    _awesome-codex-subagents/
      项目级上游缓存

    agents/
      api-designer.toml
      code-reviewer.toml
      typescript-pro.toml
      ...
      .voltagent-codex-subagents-v1.txt
```

## 常见误解

### 安装 agents 后是不是自动触发所有专家

不是。`.toml` 只是让 Codex runtime 知道有哪些 custom agents。是否派发、派发谁，取决于用户请求、`AGENTS.md` 工作流规则和 Codex runtime 的任务判断。

### `AGENTS.md` 里要不要列出全部 172 个 agent

默认不建议。`AGENTS.md` 应该写工作规则和高频路由，不应该无差别复制完整 agent 名录。完整身份描述已经在 `.toml` 文件里，重复写入会增加上下文负担，也容易和上游更新不同步。

如果你确实想让某个模式暴露更完整的路由提示，建议只改 `scripts/voltagent-roles-full/AGENTS.md`，不要改公共脚本。

### 为什么不从旧版 `~/.codex/agents` 继续整理

这套流程面向复现和分发，所以源头应该是 GitHub 上游仓库或本地下载好的 `awesome-codex-subagents` 源码目录，而不是某台机器里的历史 `~/.codex/agents`。

### `.voltagent-codex-subagents-v1.txt` 是必须的吗

它不是 Codex runtime 必需文件，而是安装脚本的 manifest。脚本用它判断哪些 `.toml` 是自己安装的，避免误删或误覆盖用户自己写的 custom agents。

## 术语清单

| 术语 | 中文说明 |
|---|---|
| LLM / Model | 大模型，负责生成和推理 |
| Agent runtime | agent 运行时，负责工具、文件、命令、上下文和子 agent 调度 |
| Codex | OpenAI 的编码 agent runtime / CLI 环境 |
| AGENTS.md | Codex 读取的工作规则文件 |
| Custom agent | 用户定义的专项 agent |
| Subagent | 被主 agent 派发的子 agent |
| TOML | Codex custom agent 使用的配置格式 |
| `~/.codex/agents` | 全局 custom agents 目录 |
| `.codex/agents` | 项目级 custom agents 目录 |
| `ROUTE_ALLOWLIST.txt` | 本方案的路由参考清单，不是 Codex runtime 配置，也不限制安装 |
| Manifest | 安装清单；本方案中是 `.voltagent-codex-subagents-v1.txt` |
