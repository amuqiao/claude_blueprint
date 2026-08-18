# DeepSeek Harness 固定角色子 Agent 机制笔记

本文记录 `voltagent-deepseek-harness` 的机制结论和维护边界。安装操作见 [voltagent-deepseek-harness-快速开始.md](./voltagent-deepseek-harness-快速开始.md)。

## 核心结论

DeepSeek Harness 可以实现类似 Codex `AGENTS.md + custom agents` 的固定角色子 agent 工作流，但接入点不同：

```text
Codex:
  AGENTS.md
    工作流规则
  ~/.codex/agents/*.toml
    Codex runtime 原生 custom agent 定义

DeepSeek Harness:
  ~/.dsh/AGENTS.md
    工作流规则，由 dsh-agent-instructions 注入
  ~/.dsh/.agent-presets/<preset-id>/agent.cordis.yml
    Harness preset composition，由 dsh-agent-presets 挂载
  @deepseek-ai/dsh-tool-subagent + persona
    每个固定专家子 agent 的工具和身份
```

所以这里不是把 DeepSeek 模型接到 Codex TUI，也不是单纯替换模型 API。真正复现的是“工作流规则 + runtime 可派发子 agent + 固定角色 persona”这三层。

## 为什么源头改成 upstream repo

旧思路把 `~/.codex/agents` 当作输入源：

```text
~/.codex/agents/*.toml
  ↓
生成 ~/.dsh/.agent-presets/codex-roles
```

这能跑通，但不适合作为可复现文档的主流程。原因是：

- `~/.codex/agents` 是本机 Codex 安装结果，不是稳定上游。
- 不同机器可能没有安装 Codex，也可能只安装了部分 agents。
- DeepSeek Harness 方案本身不应该依赖 Codex runtime。

新主流程改为：

```text
VoltAgent/awesome-codex-subagents
  categories/**/*.toml
    ↓
转换成 DeepSeek Harness preset
    ↓
~/.dsh/.agent-presets/codex-roles
```

`~/.codex/agents` 仍可通过 `--source-dir` 或兼容参数 `--codex-agents-dir` 用于调试，但不再是默认路径。

## Harness 如何加载这套配置

DeepSeek Harness 的 preset discovery 约定是：

```text
$DSH_HOME/.agent-presets/<preset-id>/agent.cordis.yml
```

默认 `$DSH_HOME` 是：

```text
~/.dsh
```

因此本方案生成：

```text
~/.dsh/.agent-presets/codex-roles/
  preset.yml
  agent.cordis.yml
  agents/*.cordis.yml
  agent-role-map.md
```

运行时关键文件只有：

```text
~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

`preset.yml` 只是 UI 展示元数据。`agents/*.cordis.yml` 和 `agent-role-map.md` 是人读产物，方便查映射和调试。

## 为什么 agent.cordis.yml 是扁平化文件

最初尝试过：

```text
agent.cordis.yml
  include standard
  include agents/index.cordis.yml
    include agents/*.cordis.yml
```

但用户 preset 位于 `~/.dsh/.agent-presets/...`，嵌套 `cordis:include` 子文件里的 `@deepseek-ai/dsh-*` package 解析不总是继承 Harness host base。结果是 Web UI 能看到 preset，但选择「专家角色模式」时 mount 失败，并回退到「标准模式」。

当前实现改为：

```text
agent.cordis.yml
  直接包含 standard preset rows
  直接包含 172 个 tool-subagent role rows
```

也就是运行时入口扁平化。`agents/*.cordis.yml` 仍生成，但只作为拆分阅读文件，不参与运行时 include。

## 角色如何转换

上游每个 TOML 角色包含：

```toml
name = "api-designer"
description = "..."
model = "..."
model_reasoning_effort = "..."
sandbox_mode = "..."
developer_instructions = """
...
"""
```

转换成 Harness row：

```yaml
- id: tool-subagent-role-api-designer
  name: '@deepseek-ai/dsh-tool-subagent'
  config:
    provider: spawn
    toolName: subagent_api_designer
    backgroundMode: one-shot
    enableRunInBackground: false
    persona: |-
      You are the DeepSeek Harness child-agent role "api-designer".
      ...
```

字段对应关系：

| 上游 TOML 字段 | Harness 用途 |
|---|---|
| `name` | 生成 row id、角色文件名、工具名 |
| `description` | 写入 persona 和映射表，帮助主 agent 选择 |
| `developer_instructions` | 写入 `persona`，成为 child agent 固定身份 |
| `model` | 只写入 persona 元信息，不改变 Harness 模型路由 |
| `model_reasoning_effort` | 只写入 persona 元信息 |
| `sandbox_mode` | 只写入 persona 元信息；`read-only` 会追加“不主动改文件”的角色提示 |

工具名规则：

```text
api-designer                  -> subagent_api_designer
code-reviewer                 -> subagent_code_reviewer
dotnet-framework-4.8-expert   -> subagent_dotnet_framework_4_8_expert
```

## AGENTS.md 的职责边界

`~/.dsh/AGENTS.md` 不注册工具，也不定义专家身份。它只是一份模型可见规则，告诉主 agent 如何使用当前 preset 暴露出来的工具。

它负责：

- 代码任务开始前询问工作流。
- 工作流 1 必须执行 plan、subagent、review、verify。
- 工作流 2 直接执行，但最后仍要验证。
- 使用固定专家工具时调用 `subagent_<role>`。
- 派发 child agent 时告诉 child：主会话已选择工作流 1，不要再次询问。
- 控制并发：实现类默认 2-3 个并发，只读/review/verify 可以适度增加。

它不负责：

- 让 `subagent_api_designer` 这个工具出现。
- 加载上游 TOML。
- 改变模型路由。
- 强制 runtime 必须调用某个子 agent。

这意味着 `AGENTS.md` 是提示词规则，`agent.cordis.yml` 才是工具和 persona 注册入口。

## 并发与派发边界

DeepSeek Harness 支持多种子 agent 派发方式：

| 工具 | 用途 |
|---|---|
| `subagent` | 独立 child agent，适合自包含探索、实现、审查 |
| `subagent_fork` | 继承已完成对话上下文，适合复核、review、延续分析 |
| `workflow` | 大规模 fan-out 或多阶段编排 |
| `list_agents` / `send_message` / `interrupt_agent` | 后台 child agent 管理 |

并发不是“越多越好”。当前规则建议：

```text
实现类 subagent:
  默认 2-3 个并发
  避免同时编辑同一文件或强耦合模块

只读 / review / verify:
  可以适度增加
  大规模 fan-out 使用 workflow 或分批
```

这是工作流约束，不是 Harness runtime 的硬锁。主 agent 仍要在 prompt 中写清范围和禁止事项。

## 脚本分工

```text
setup-deepseek-harness-workflow.sh
  输入：本目录 AGENTS.md
  输出：~/.dsh/AGENTS.md 或项目 AGENTS.md
  职责：安装工作流规则

setup-deepseek-harness-codex-agents.sh
  输入：VoltAgent/awesome-codex-subagents
  输出：~/.dsh/.agent-presets/codex-roles
  职责：获取上游仓库并生成 Harness preset

convert-codex-agents-to-dsh-preset.py
  输入：categories/**/*.toml 或显式 source dir
  输出：preset 目录结构
  职责：纯转换，不负责 git clone/pull
```

脚本不会做这些事：

- 不修改 `~/.codex`。
- 不安装 Codex。
- 不把 VoltAgent 变成 DeepSeek Harness 插件。
- 不写 `cordis.patch.yml`。
- 不改变 DeepSeek Harness 的模型、API key 或权限配置。

## 维护原则

更新上游角色时，只需要重新运行：

```bash
cd docs/ClaudeCodeCli/voltagent-deepseek-harness
bash setup-deepseek-harness-codex-agents.sh --force
```

如果 DeepSeek Harness 后续改变 preset 机制，优先检查：

```text
1. agent-presets 是否仍扫描 ~/.dsh/.agent-presets
2. preset 入口是否仍是 agent.cordis.yml
3. tool-subagent 是否仍支持 provider / toolName / persona
4. user preset 下嵌套 include 的 package resolution 是否已改变
```

只有第 4 点被官方修复且行为稳定后，才考虑让运行时入口重新使用 include。否则保持扁平化入口。
