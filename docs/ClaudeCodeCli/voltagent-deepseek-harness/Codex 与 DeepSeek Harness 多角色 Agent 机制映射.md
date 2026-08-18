# Codex 与 DeepSeek Harness 多角色 Agent 机制映射

本文面向只知道“大模型可以问答”的读者。目标不是讲源码细节，而是讲清楚 Codex 和 DeepSeek Harness 这两套 agent runtime 如何组装多角色子 agent 协作，以及本目录为什么要生成 `~/.dsh/.agent-presets/codex-roles`。

如果你只想复制命令安装，读 [快速开始](./voltagent-deepseek-harness-快速开始.md)。

## 先理解：大模型不是完整的 agent 系统

大模型本身只会根据输入文本生成输出文本。它可以回答问题，但它天然不知道：

```text
该读哪个项目文件
该运行哪个命令
有哪些专家角色
什么时候派发子 agent
子 agent 的结果如何回到主会话
最后要不要测试、review、verify
```

这些能力来自 **agent runtime**。可以用“组装一辆车”来理解：

```text
LLM / Model
  像发动机：提供推理和生成能力，但不是完整车辆。

Agent runtime
  像车架、方向盘、传动和控制系统：负责把模型、工具、文件、命令、规则、子 agent 串起来。

Tool
  像车上的按钮或接口：模型可以调用，例如读文件、运行命令、派发子 agent。

Rules / Instructions
  像驾驶规则：什么时候先问用户、什么时候审查、什么时候验证。

Persona
  像岗位说明：这个 agent 是 API 设计师、代码审查员，还是通用开发者。

Subagent / Child agent
  像被派出去处理专项任务的同事：主 agent 分配任务，子 agent 返回结果。
```

所以“多 agent 协作”至少需要五件事：

```text
1. 规则
   主 agent 要知道什么时候使用多 agent 流程。

2. 角色
   系统要知道 api-designer、code-reviewer 这些专家分别是谁。

3. 工具
   主 agent 要能看到并调用 subagent_api_designer 这样的工具。

4. runtime
   runtime 要能创建 child agent、注入 persona、执行任务、返回结果。

5. 验证
   主 agent 要把结果汇总，并完成 review / verify。
```

只替换模型 API，只能换“发动机”，不会自动得到这套车架和控制系统。

## 术语清单

下面这些英文术语会在文档和配置里直接出现，不强行翻译。先把它们的职责看懂。

| 术语 | 中文说明 | 在本文里的作用 |
|---|---|---|
| LLM / Model | 大模型，负责根据上下文生成回答 | 只提供推理和文本生成，不负责工具和子 agent 管理 |
| Agent | 带有模型、规则和工具的执行者 | 主 agent 处理用户请求，子 agent 处理专项任务 |
| Agent runtime | agent 运行时系统 | 加载规则、注册工具、创建子 agent、管理执行过程 |
| Tool | 模型可调用的能力入口 | 例如读文件、运行命令、调用 `subagent_api_designer` |
| Subagent / Child agent | 被主 agent 派发出去的子 agent | 处理探索、实现、审查、验证等专项任务 |
| Workflow | 多步骤或多 agent 编排流程 | 例如 `plan -> subagent -> review -> verify` |
| AGENTS.md | 工作规则文件 | 告诉主 agent 什么时候问工作流、什么时候派发子 agent |
| Persona | agent 的身份说明 | 固定某个专家“是谁”和“应该关注什么” |
| Custom agent | Codex 里的自定义 agent | 由 Codex 的 `.toml` 文件定义 |
| TOML | 一种配置文件格式 | `VoltAgent/awesome-codex-subagents` 里的角色定义格式 |
| Cordis plugin | DeepSeek Harness 的功能插件 | 给 Harness 增加工具、prompt、preset、子 agent 等能力 |
| Profile | DeepSeek Harness 启动配置组合 | `dsh web` 启动时加载的一组插件和服务 |
| Agent preset | DeepSeek Harness 的 agent 能力包 | Web UI 里选择“标准模式”“专家角色模式”等 |
| agent.cordis.yml | Harness preset 的组装说明书 | runtime 真正加载的 preset 入口 |
| tool-subagent | DeepSeek Harness 的子 agent 工具插件 | 把一个工具注册成“可创建 child agent”的入口 |

## Codex 的心智模型

Codex 可以理解为一个编码 agent runtime。它不是单纯把你的问题发给模型，而是会读取规则、管理工具、加载 custom agents。

Codex 的多角色协作由三部分组成：

```text
Codex runtime
  负责启动主 agent、加载规则、发现 custom agents、派发子 agent

AGENTS.md
  负责工作规则

~/.codex/agents/*.toml
  负责 custom agent 身份定义
```

### Codex 的目录和职责

```text
~/.codex/
  AGENTS.md
    全局工作规则

  agents/
    api-designer.toml
    code-reviewer.toml
    typescript-pro.toml
    ...
      每个文件定义一个 custom agent
```

项目里也可以有类似结构：

```text
project/
  AGENTS.md
    项目工作规则

  .codex/
    agents/
      xxx.toml
```

### Codex 中 AGENTS.md 是什么

`AGENTS.md` 是主 agent 的工作规则，不是专家身份库。它告诉 Codex 主 agent：

```text
代码任务开始前先问用户选择工作流
工作流 1 要 plan -> subagent -> review -> verify
API 设计任务优先找 api-designer
代码审查任务优先找 code-reviewer
完成前要运行最小必要验证
```

一句话：

```text
AGENTS.md 负责“什么时候做什么”。
```

### Codex 中 .toml 是什么

`.toml` 是每个专家的岗位说明。一个简化例子：

```toml
name = "api-designer"
description = "Use when a task needs API contract design."
developer_instructions = """
Design APIs as long-lived contracts.
Focus on compatibility, schemas, errors, versioning, and migration risk.
"""
```

这份文件告诉 Codex runtime：

```text
有一个专家叫 api-designer
它适合 API 合同设计
它的行为边界写在 developer_instructions 里
```

一句话：

```text
.toml 负责“这个专家是谁”。
```

### Codex 一次任务如何跑

```text
用户提出任务
  ↓
Codex runtime 启动主 agent
  ↓
主 agent 读取 AGENTS.md，知道要先问工作流
  ↓
用户选择工作流 1
  ↓
主 agent 根据任务判断需要 api-designer
  ↓
Codex runtime 根据 ~/.codex/agents/api-designer.toml 创建对应子 agent
  ↓
子 agent 完成专项分析
  ↓
主 agent 汇总结果，继续 review / verify
```

Codex 的核心心智模型是：

```text
Codex:
  AGENTS.md = 工作规则
  agents/*.toml = 专家身份
  Codex runtime = 读取规则和身份，并负责派发
```

## DeepSeek Harness 的心智模型

DeepSeek Harness 也是 agent runtime，但它的组装方式和 Codex 不一样。它不原生读取 Codex 的 `~/.codex/agents/*.toml`。它用自己的插件和 preset 机制。

先用一张图看整体：

```text
dsh web
  ↓
启动 DeepSeek Harness Web runtime
  ↓
加载 profile
  ↓
profile 加载 Cordis plugins
  ↓
plugins 提供能力：
  - 读取 AGENTS.md
  - 暴露 tools
  - 管理 agent presets
  - 创建 subagents
  ↓
Web UI 新建会话时选择 agent preset
  ↓
当前 agent 得到对应工具和 persona
```

### DeepSeek Harness 是什么

可以把 DeepSeek Harness 理解成：

```text
一个 Web 形态的 agent runtime
```

它负责：

```text
启动 Web UI
管理会话
加载配置
把工具暴露给模型
读取工作区规则
创建 child agent
记录会话日志
```

### Cordis plugin 是什么

`Cordis plugin` 是 DeepSeek Harness 的能力插件。不要把它想复杂，它就是“往 runtime 里安装一个功能模块”。

例子：

```text
dsh-agent-instructions
  负责读取 ~/.dsh/AGENTS.md 和项目 AGENTS.md

dsh-agent-presets
  负责发现和挂载 agent preset

dsh-tool-subagent
  负责提供创建 child agent 的工具

dsh-tool-workflow
  负责多阶段、多 agent 编排
```

心智模型：

```text
Cordis plugin
  像安装到车上的部件
  有的部件提供规则读取
  有的部件提供工具
  有的部件提供 preset 管理
```

### Tool 是什么

`Tool` 是插件暴露给模型的可调用能力。模型不是直接操作你的电脑，而是通过 runtime 提供的工具做事。

例子：

```text
文件工具
  读写文件

Shell 工具
  运行命令

subagent 工具
  创建 child agent

workflow 工具
  编排多个子 agent
```

在本方案里，固定专家最终会变成这些工具：

```text
subagent_api_designer
subagent_code_reviewer
subagent_typescript_pro
...
```

主 agent 看到这些工具后，才能真的调用对应专家。

### Agent preset 是什么

`Agent preset` 是一套 agent 能力配置包。它决定当前会话的 agent 拥有哪些工具、prompt sections、persona 等。

Web UI 里你看到的：

```text
标准模式
PTC 模式
专家角色模式
```

本质上就是不同 preset。

心智模型：

```text
agent preset
  像一套驾驶舱配置
  选择不同 preset
  当前 agent 看到的按钮和工具就不同
```

用户自定义 preset 放在：

```text
~/.dsh/.agent-presets/<preset-id>/agent.cordis.yml
```

本方案生成：

```text
~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

它在 Web UI 中显示为：

```text
专家角色模式
```

### Persona 是什么

`Persona` 是 agent 的身份说明。它告诉某个 agent：

```text
你是谁
你关注什么
你应该如何回答
你不能做什么
```

例如 `api-designer` 的 persona 会强调：

```text
关注 API 合同、兼容性、错误模型、版本策略、迁移风险
除非父 agent 明确要求，不要实现代码
```

注意：

```text
persona 不是本次任务
persona 是长期身份

本次 prompt 才是具体任务
```

主 agent 调用 `subagent_api_designer` 时，仍要写清楚：

```text
这次审查哪个 API
是否只读
输出什么格式
禁止修改哪些文件
```

### agent.cordis.yml 是什么

`agent.cordis.yml` 是 Harness preset 的组装说明书。DeepSeek Harness 会读取它，知道这个 preset 要安装哪些插件、注册哪些工具。

本方案里的关键入口是：

```text
~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

它里面会有很多类似这样的配置：

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

这段配置等价于：

```text
给当前 agent 安装一个工具：subagent_api_designer
这个工具会创建一个 child agent
这个 child agent 使用 api-designer persona
```

## Codex 和 DeepSeek Harness 对照

| 问题 | Codex | DeepSeek Harness |
|---|---|---|
| runtime 是谁 | Codex CLI/TUI | `dsh web` / DeepSeek Harness |
| 规则放哪里 | `AGENTS.md` | `~/.dsh/AGENTS.md` 或项目 `AGENTS.md` |
| 专家身份放哪里 | `~/.codex/agents/*.toml` | `agent.cordis.yml` 里的 `tool-subagent + persona` |
| 专家如何出现 | Codex runtime 扫描 `.toml` | Harness preset 注册 tool |
| 用户如何启用 | 进入 Codex runtime | Web UI 选择「专家角色模式」 |
| API 设计专家叫法 | `api-designer` | `subagent_api_designer` |
| 代码审查专家叫法 | `code-reviewer` | `subagent_code_reviewer` |

压缩理解：

```text
Codex:
  AGENTS.md 管规则
  .toml 管专家身份
  Codex runtime 负责派发

DeepSeek Harness:
  AGENTS.md 管规则
  agent preset 管工具和 persona
  Harness runtime 负责派发
```

## 为什么不能直接用 VoltAgent 的 TOML

`VoltAgent/awesome-codex-subagents` 提供的是 Codex 风格的 `.toml` 角色定义。

这些 TOML 对 Codex 来说是原生格式：

```text
Codex runtime 会扫描 agents/*.toml
```

但对 DeepSeek Harness 来说不是原生格式：

```text
DeepSeek Harness 不会自动扫描 Codex TOML
DeepSeek Harness 需要 agent preset / agent.cordis.yml
```

所以我们不能直接把 TOML 丢给 Harness。必须转换。

转换前：

```text
VoltAgent/awesome-codex-subagents/categories/**/*.toml
```

转换后：

```text
~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

## 本方案如何转换

本目录的转换流程是：

```text
setup-deepseek-harness-codex-agents.sh
  ↓ clone/update
~/.dsh/_awesome-codex-subagents/
  ↓ 读取 categories/**/*.toml
convert-codex-agents-to-dsh-preset.py
  ↓ 生成 Harness preset
~/.dsh/.agent-presets/codex-roles/
```

上游一个 TOML 角色：

```toml
name = "api-designer"
description = "Use when a task needs API contract design..."
developer_instructions = """
Design APIs as long-lived contracts...
"""
```

转换成 Harness 工具：

```text
role name:
  api-designer

tool name:
  subagent_api_designer

persona:
  developer_instructions 的内容

runtime row:
  @deepseek-ai/dsh-tool-subagent
```

工具名规则：

```text
角色名小写
非字母数字字符变成 _
前面加 subagent_
```

例子：

```text
api-designer                  -> subagent_api_designer
code-reviewer                 -> subagent_code_reviewer
typescript-pro                -> subagent_typescript_pro
dotnet-framework-4.8-expert   -> subagent_dotnet_framework_4_8_expert
```

## 关键目录层级

### DeepSeek Harness 自己的目录

`dsh web` 首次启动后，`~/.dsh` 是 Harness home：

```text
~/.dsh/
  profiles/
    Harness 自己的 profile 配置

  settings.yaml
    Harness 用户设置，可能包含模型、默认 preset 等

  sessions/ 或其他运行时目录
    会话、缓存、日志等，具体随 Harness 版本变化
```

这些不是本方案创建的专家角色。

### 本方案新增的目录

```text
~/.dsh/
  AGENTS.md
    由 setup-deepseek-harness-workflow.sh 写入
    规则层：告诉主 agent 如何工作

  _awesome-codex-subagents/
    由 setup-deepseek-harness-codex-agents.sh clone/update
    来源层：缓存上游 TOML 角色素材

  .agent-presets/
    codex-roles/
      由 setup-deepseek-harness-codex-agents.sh 生成
      能力层：让 Harness 看到固定专家工具

      preset.yml
        UI 展示名，例如「专家角色模式」

      agent.cordis.yml
        runtime 真正加载的入口

      agents/*.cordis.yml
        给人看的拆分文件，不是 runtime 入口

      agent-role-map.md
        上游角色名和 Harness 工具名映射
```

最重要的两个文件：

```text
~/.dsh/AGENTS.md
  没有它：主 agent 不知道你的工作流规则

~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
  没有它：主 agent 看不到固定专家工具
```

## 一次任务实际如何运行

假设你在 Web UI 里输入：

```text
使用工作流 1。请调用 subagent_api_designer 只读审查这个 API 方案。
```

实际链路是：

```text
1. dsh web 已启动
   ↓
2. 当前会话选择「专家角色模式」
   ↓
3. Harness 加载 codex-roles/agent.cordis.yml
   ↓
4. 主 agent 看到 subagent_api_designer 工具
   ↓
5. Harness 注入 ~/.dsh/AGENTS.md 工作规则
   ↓
6. 主 agent 知道工作流 1 已允许派发子 agent
   ↓
7. 主 agent 调用 subagent_api_designer
   ↓
8. dsh-tool-subagent 创建 child agent
   ↓
9. child agent 获得 api-designer persona
   ↓
10. child agent 完成只读审查并返回结果
   ↓
11. 主 agent 汇总，继续 review / verify
```

如果没有选择「专家角色模式」：

```text
主 agent 可能仍有通用 subagent
但看不到 subagent_api_designer 这种固定专家工具
```

如果没有安装 `~/.dsh/AGENTS.md`：

```text
专家工具可能存在
但主 agent 不一定按你的工作流规则使用它们
```

## 为什么 agent.cordis.yml 要扁平化

Harness 的用户 preset 入口是：

```text
~/.dsh/.agent-presets/<preset-id>/agent.cordis.yml
```

早期尝试过让入口文件 include 子文件：

```text
agent.cordis.yml
  include standard
  include agents/index.cordis.yml
    include agents/*.cordis.yml
```

但用户 preset 在 `~/.dsh/.agent-presets/...` 下，嵌套 include 的子文件里如果再引用 `@deepseek-ai/dsh-*` package，可能无法继承 Harness host 的 package resolution。结果是：

```text
Web UI 看得到 preset
选择「专家角色模式」时 mount 失败
UI 回退到「标准模式」
```

当前实现采用扁平化入口：

```text
agent.cordis.yml
  直接包含 standard preset rows
  直接包含全部 tool-subagent role rows
```

这就是为什么 `agents/*.cordis.yml` 只是人读拆分文件，而不是 runtime 入口。

## 并发和工作流边界

DeepSeek Harness 提供的子 agent 工具有不同用途：

| 工具 | 用途 |
|---|---|
| `subagent` | 独立 child agent，适合自包含任务 |
| `subagent_fork` | 继承已完成对话上下文，适合 review、复核、延续分析 |
| `subagent_<role>` | 固定专家角色，例如 `subagent_code_reviewer` |
| `workflow` | 大规模 fan-out 或多阶段并行编排 |
| `list_agents` / `send_message` / `interrupt_agent` | 管理后台子 agent |

本方案的 `AGENTS.md` 规则要求：

```text
实现类 subagent:
  默认最多同时运行 2-3 个
  避免多个 agent 同时编辑同一文件或强耦合模块

只读 / review / verify:
  可以适度增加并发
  大规模任务应分批，或使用 workflow
```

这些是模型可见规则，不是文件锁。主 agent 派发时仍要写清楚：

```text
角色
任务
范围
是否允许修改文件
输出格式
禁止事项
验证要求
```

## 常见误解

### 误解 1：只换模型 URL 就能得到多 agent

不对。换模型只换了推理引擎。多 agent 还需要 runtime 加载规则、注册工具、创建 child agent、注入 persona、回收结果。

### 误解 2：`AGENTS.md` 会注册专家工具

不对。`AGENTS.md` 只写规则。固定专家工具来自：

```text
~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

### 误解 3：`agents/*.cordis.yml` 是 Harness 运行时入口

不对。它们是人读拆分文件。运行时入口是：

```text
codex-roles/agent.cordis.yml
```

### 误解 4：`~/.codex/agents` 是本方案默认来源

不对。默认来源是：

```text
https://github.com/VoltAgent/awesome-codex-subagents
```

脚本会 clone/update 到：

```text
~/.dsh/_awesome-codex-subagents
```

`--codex-agents-dir` 只是兼容旧流程和调试用途。

## 文档职责

本目录现在分成三类文档：

```text
README.md
  目录入口：先读哪篇，每个文件干什么

voltagent-deepseek-harness-快速开始.md
  快速使用手册：安装、验证、排查

Codex 与 DeepSeek Harness 多角色 Agent 机制映射.md
  详细机制说明：为什么这样做，各部件如何组装
```

维护原则：

```text
快速开始写“怎么做”
机制文档写“为什么”
README 写“先读哪里”
```

## 最终压缩理解

一句话：

```text
我们不是把 Codex 跑在 DeepSeek Harness 里；
我们是把 Codex 风格的专家角色素材
转换成 DeepSeek Harness 原生可加载的固定角色子 agent preset。
```

最终落地：

```text
规则层：
  ~/.dsh/AGENTS.md

来源层：
  ~/.dsh/_awesome-codex-subagents/categories/**/*.toml

能力层：
  ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml

使用入口：
  dsh web -> 新建会话 -> 专家角色模式
```
