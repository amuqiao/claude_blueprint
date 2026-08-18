# DeepSeek Harness 固定角色子 Agent 快速开始

本文是一份可交给其他人复现的安装手册：先完成 DeepSeek Harness 前置安装，再从 `VoltAgent/awesome-codex-subagents` 生成 Harness 专家 preset，最后用 `AGENTS.md` 规则驱动多 agent 工作流。

如果你想先理解 Codex 和 DeepSeek Harness 分别如何实现多角色 agent 协作，读 [Codex 与 DeepSeek Harness 多角色 Agent 机制映射.md](./Codex%20与%20DeepSeek%20Harness%20多角色%20Agent%20机制映射.md)。本文只保留安装、验证和排查所需的最少解释。

## 整体流程

先看完整链路，后面的步骤就是按这张图落地：

```text
安装 DeepSeek Harness
  npm install -g @deepseek-ai/dsh@0.1.0-rc.7
  dsh web
    ↓ 初始化 ~/.dsh

安装工作流规则
  setup-deepseek-harness-workflow.sh
    ↓ 写入 ~/.dsh/AGENTS.md

安装专家角色 preset
  setup-deepseek-harness-codex-agents.sh
    ↓ clone/update VoltAgent/awesome-codex-subagents
    ↓ 读取 categories/**/*.toml
    ↓ 生成 ~/.dsh/.agent-presets/codex-roles

使用
  dsh web
    ↓ Web UI 新建会话选择「专家角色模式」
    ↓ 主 agent 按 AGENTS.md 调用 subagent_api_designer / subagent_code_reviewer 等工具
```

这套方案不是替换模型 URL，也不是让 DeepSeek 临时扮演 Codex。它使用 DeepSeek Harness 原生机制：

```text
~/.dsh/AGENTS.md
  负责规则：什么时候问工作流、什么时候派发子 agent、怎么 review/verify

~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
  负责能力：注册固定专家 subagent 工具和 persona
```

## 前置安装 DeepSeek Harness

需要本机已有：

```bash
git --version
node --version
npm --version
python3 --version
```

安装固定版本的 DeepSeek Harness：

```bash
npm install -g @deepseek-ai/dsh@0.1.0-rc.7
```

确认命令可用：

```bash
dsh --version
```

首次启动 Web UI：

```bash
dsh web
```

终端打印类似下面内容时，说明 Web 服务启动成功：

```text
dsh web: http://127.0.0.1:3080
```

首次启动会初始化 `~/.dsh`。可以先打开 Web UI 完成模型和 API key 配置；如果只是初始化目录，也可以稍后停止服务，等安装完本文的工作流和 preset 后再重启。

## 一次性完整命令

如果你只是想按默认路径完整安装，可以直接复制下面这组命令：

```bash
npm install -g @deepseek-ai/dsh@0.1.0-rc.7
dsh --version

cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness

./setup-deepseek-harness-workflow.sh
./setup-deepseek-harness-codex-agents.sh

dsh web
```

如果 `~/.dsh/AGENTS.md` 或 `~/.dsh/.agent-presets/codex-roles` 已经存在，脚本会停止，避免覆盖。确认要更新时使用：

```bash
./setup-deepseek-harness-workflow.sh --force
./setup-deepseek-harness-codex-agents.sh --force
```

后面的章节会解释这些命令分别创建了什么文件、如何验证、以及出问题时怎么排查。

## `~/.dsh` 目录结构

`~/.dsh` 是 DeepSeek Harness 的 home 目录。需要区分两件事：哪些是 Harness 前置安装和首次运行产生的，哪些是本文脚本后续写入的。

### 前置安装后

执行 `npm install -g @deepseek-ai/dsh@0.1.0-rc.7` 只是安装全局命令，不一定立刻写出完整 `~/.dsh` 结构。首次执行 `dsh web` 后，Harness 会按自身需要初始化 home 目录，常见内容类似：

```text
~/.dsh/
  profiles/
    DeepSeek Harness 自己的 profile 配置

  settings.yaml
    DeepSeek Harness 用户设置；可能在配置模型、默认 preset 等操作后出现

  sessions/ 或其他运行时目录
    DeepSeek Harness 会话、缓存、运行状态等；具体名称以后续版本为准
```

这些是 DeepSeek Harness 自己的运行目录，不是本文方案新增的专家 preset。

### 执行本文脚本后

执行本文两个脚本后，会额外新增或更新这些内容：

```text
~/.dsh/
  AGENTS.md
    由 setup-deepseek-harness-workflow.sh 写入
    作用：DeepSeek Harness 工作流规则

  _awesome-codex-subagents/
    由 setup-deepseek-harness-codex-agents.sh clone/update
    作用：缓存 https://github.com/VoltAgent/awesome-codex-subagents.git

  .agent-presets/
    codex-roles/
      由 setup-deepseek-harness-codex-agents.sh 生成
      作用：DeepSeek Harness 专家角色 preset

      preset.yml
        Web UI 展示名：专家角色模式

      agent.cordis.yml
        Harness 运行时真正加载的 preset 入口

      base/
        standard.agent.cordis.yml
          生成时复制的 standard preset 基底

      agents/
        index.cordis.yml
        api-designer.cordis.yml
        code-reviewer.cordis.yml
        ...
          人读拆分文件，不是运行时入口

      agent-role-map.md
        上游角色名到 Harness 工具名的映射表
```

最重要的是这两个文件：

```text
~/.dsh/AGENTS.md
~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

前者告诉主 agent 怎么工作，后者让专家子 agent 工具真正出现在 Harness runtime 里。

对应关系：

| 路径 | 创建者 | 是否 dsh 默认自带 |
|---|---|---|
| `~/.dsh/` | DeepSeek Harness | 是，Harness home |
| `~/.dsh/profiles/` | DeepSeek Harness | 通常由 `dsh web` 初始化 |
| `~/.dsh/settings.yaml` | DeepSeek Harness / 用户配置 | 可能存在 |
| `~/.dsh/AGENTS.md` | `setup-deepseek-harness-workflow.sh` | 否 |
| `~/.dsh/_awesome-codex-subagents/` | `setup-deepseek-harness-codex-agents.sh` | 否 |
| `~/.dsh/.agent-presets/codex-roles/` | `setup-deepseek-harness-codex-agents.sh` | 否 |

## 本目录文件职责

```text
voltagent-deepseek-harness/
  README.md
    目录入口和文件职责索引

  voltagent-deepseek-harness-快速开始.md
    面向用户的完整复现步骤，也就是本文

  Codex 与 DeepSeek Harness 多角色 Agent 机制映射.md
    详细机制说明、心智模型、Codex 与 Harness 对照

  AGENTS.md
    要安装到 ~/.dsh/AGENTS.md 的工作流规则模板

  setup-deepseek-harness-workflow.sh
    安装工作流规则

  setup-deepseek-harness-codex-agents.sh
    从 GitHub 上游安装专家角色 preset

  convert-codex-agents-to-dsh-preset.py
    内部转换器，把上游 TOML 转成 Harness .cordis.yml
```

脚本关系：

```text
setup-deepseek-harness-workflow.sh
  直接给用户执行
  输入：本目录 AGENTS.md
  输出：~/.dsh/AGENTS.md

setup-deepseek-harness-codex-agents.sh
  直接给用户执行
  输入：VoltAgent/awesome-codex-subagents
  输出：~/.dsh/.agent-presets/codex-roles

convert-codex-agents-to-dsh-preset.py
  通常不用手动执行
  被 setup-deepseek-harness-codex-agents.sh 调用
```

### 转换器具体做什么

`convert-codex-agents-to-dsh-preset.py` 是内部转换器。新手正常不需要手动运行它，因为 `setup-deepseek-harness-codex-agents.sh` 会自动调用。

它做的是纯文件转换：

```text
输入：
  ~/.dsh/_awesome-codex-subagents/categories/**/*.toml

读取字段：
  name
  description
  developer_instructions
  model / model_reasoning_effort / sandbox_mode

转换：
  name                       -> Harness 工具名，例如 subagent_api_designer
  description                -> 写入 persona 和映射表
  developer_instructions     -> 写入 persona，成为专家子 agent 身份
  model / reasoning / sandbox -> 写入说明性元信息，不改变 Harness 模型路由

输出：
  ~/.dsh/.agent-presets/codex-roles/preset.yml
  ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
  ~/.dsh/.agent-presets/codex-roles/agents/*.cordis.yml
  ~/.dsh/.agent-presets/codex-roles/agent-role-map.md
```

也就是说：

```text
setup-deepseek-harness-codex-agents.sh
  负责 git clone/pull、参数组织、备份、验证

convert-codex-agents-to-dsh-preset.py
  负责把 TOML 角色内容转成 DeepSeek Harness 可加载的 preset 文件
```

只有调试转换逻辑时才需要手动运行它，例如：

```bash
python3 convert-codex-agents-to-dsh-preset.py \
  --source-dir=~/.dsh/_awesome-codex-subagents \
  --output-dir=/tmp/codex-roles-preview \
  --preset-id=codex-roles \
  --force
```

## 安装工作流规则

进入本目录：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness
```

先预览：

```bash
./setup-deepseek-harness-workflow.sh --dry-run
```

写入全局规则：

```bash
./setup-deepseek-harness-workflow.sh
```

默认写入：

```text
~/.dsh/AGENTS.md
```

如果目标文件已存在，脚本会停止。确认要覆盖时：

```bash
./setup-deepseek-harness-workflow.sh --force
```

覆盖前会生成备份：

```text
~/.dsh/AGENTS.md.bak.YYYYMMDDHHMMSS
```

项目级安装是可选项，适合只想让某个仓库使用这套规则：

```bash
# 在目标项目根目录执行
/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/setup-deepseek-harness-workflow.sh --project
```

项目级模式会写入当前 Git 项目的：

```text
AGENTS.md
```

## 安装专家角色 preset

先预览：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness
./setup-deepseek-harness-codex-agents.sh --dry-run
```

正式安装：

```bash
./setup-deepseek-harness-codex-agents.sh
```

脚本会执行：

```text
1. clone/update https://github.com/VoltAgent/awesome-codex-subagents.git
2. 缓存到 ~/.dsh/_awesome-codex-subagents
3. 读取 ~/.dsh/_awesome-codex-subagents/categories/**/*.toml
4. 从 DeepSeek Harness 安装包中读取 standard preset
5. 生成 ~/.dsh/.agent-presets/codex-roles
```

目标 preset 已存在时，脚本会停止。确认要替换时：

```bash
./setup-deepseek-harness-codex-agents.sh --force
```

替换前会生成备份目录：

```text
~/.dsh/.agent-presets/codex-roles.bak.YYYYMMDDHHMMSS
```

### 本地 source 目录

默认不依赖 `~/.codex/agents`。如果你已经有上游仓库本地副本，可以显式指定：

```bash
./setup-deepseek-harness-codex-agents.sh \
  --source-dir=/path/to/awesome-codex-subagents \
  --force
```

兼容旧参数：

```bash
./setup-deepseek-harness-codex-agents.sh \
  --codex-agents-dir=/Users/admin/.codex/agents \
  --force
```

这个兼容参数只用于调试或旧流程，不是推荐主流程。

## 转换过程可视化

上游角色文件：

```text
VoltAgent/awesome-codex-subagents/categories/01-core-development/api-designer.toml
```

转换成 Harness 工具：

```text
api-designer.toml
  name = "api-designer"
  description = "..."
  developer_instructions = "..."
    ↓
~/.dsh/.agent-presets/codex-roles/agents/api-designer.cordis.yml
    ↓
~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
  - id: tool-subagent-role-api-designer
    name: '@deepseek-ai/dsh-tool-subagent'
    config:
      toolName: subagent_api_designer
      persona: api-designer 的角色说明
    ↓
dsh web 选择「专家角色模式」
    ↓
模型可调用工具：subagent_api_designer
```

工具命名规则：

```text
api-designer                  -> subagent_api_designer
code-reviewer                 -> subagent_code_reviewer
typescript-pro                -> subagent_typescript_pro
dotnet-framework-4.8-expert   -> subagent_dotnet_framework_4_8_expert
```

## 启动和使用

安装完成后，重启 DeepSeek Harness：

```bash
cd /path/to/your/project
dsh web
```

打开 Web UI：

```text
http://127.0.0.1:3080
```

在 Web UI 中：

1. 选择工作区目录。
2. 配置模型和 API key。
3. 新建会话时选择「专家角色模式」。
4. 不要使用「极简模式」复现多 agent 工作流。

已经开始的会话不会自动切换到新 preset。重新生成 preset 后，建议重启 `dsh web` 并新建会话。

## 验证安装

验证 `dsh web` profile 有通用多 agent 工具：

```bash
dsh web --dump-config > /tmp/dsh-web-config.yml
grep -E 'id: tool-subagent$|toolName: subagent$' /tmp/dsh-web-config.yml
grep -E 'id: tool-subagent-fork$|toolName: subagent_fork$' /tmp/dsh-web-config.yml
grep -E 'id: tool-workflow$|name: .+dsh-tool-workflow' /tmp/dsh-web-config.yml
grep -E 'id: agent-presets$|default: standard' /tmp/dsh-web-config.yml
```

验证专家 preset：

```bash
test -f ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
test -f ~/.dsh/.agent-presets/codex-roles/preset.yml
grep -c '^- id: tool-subagent-role-' ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

最后一条应输出上游仓库当前角色数量，例如：

```text
172
```

验证没有运行时 include：

```bash
grep -n '^- id: include-' ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

这条命令应该没有输出。当前方案要求 `agent.cordis.yml` 保持扁平化，避免用户 preset 子 include 的包解析问题。

## 验证工作流

在 Web UI 输入：

```text
请为当前项目拟定一个新增临时说明文件的实现方案。不要创建或修改任何文件；开始前按项目规则处理。
```

预期先回复：

```text
选择工作流：

1. plan -> subagent -> review -> verify（完整多 agent 流水线）
2. Just do it（直接执行，最后验证）

请回复 1 或 2。
```

回复：

```text
1
```

再输入：

```text
使用工作流 1。请让一个 explorer 子 agent 只读分析项目结构，然后主 agent 汇总结论。不要修改任何文件。
```

预期行为：

- 主 agent 制定计划。
- 派发只读 subagent。
- 主 agent 汇总子 agent 结果。
- 最后说明没有修改文件，因此 verify 以只读检查为准。

## 日常使用示例

调用固定专家：

```text
使用工作流 1。请调用 subagent_code_reviewer 审查当前改动，只输出阻断级问题、证据和建议。
```

API 合同设计：

```text
使用工作流 1。请调用 subagent_api_designer 只读审查这个 API 方案，输出合同风险、兼容性问题和迁移建议。
```

直接执行小改动：

```text
使用工作流 2。请直接修复这个 typo，最后运行最小必要验证。
```

即使固定专家工具已经带 persona，本次 prompt 仍要写清：

- 任务目标。
- 可读或可写范围。
- 是否允许修改文件。
- 输出格式。
- 验证要求。

## 常见问题

### 是否只执行 `setup-deepseek-harness-workflow.sh` 就够了

不够。它只安装规则：

```text
~/.dsh/AGENTS.md
```

如果要使用固定专家工具，还必须执行：

```text
setup-deepseek-harness-codex-agents.sh
```

它负责生成：

```text
~/.dsh/.agent-presets/codex-roles
```

### npm 安装时出现 warn 是否异常

类似下面的 npm warn 通常不是安装失败：

```text
npm warn Unknown env config "disturl"
npm warn Unknown env config "electron-mirror"
```

只要命令最终没有 `ERR!` 并且 `dsh --version` 可用，就可以继续。

### `dsh web` 报端口占用

如果看到：

```text
EADDRINUSE: address already in use 127.0.0.1:3080
```

说明已有 `dsh web` 在运行。可以直接打开：

```text
http://127.0.0.1:3080
```

或者关闭旧进程后重新启动。

### 看不到「专家角色模式」

确认：

```bash
test -f ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
test -f ~/.dsh/.agent-presets/codex-roles/preset.yml
```

然后重启 `dsh web` 并新建会话。

### 选择「专家角色模式」后秒切回「标准模式」

通常表示 preset 被发现了，但 mount 失败。重新生成扁平化 preset：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness
./setup-deepseek-harness-codex-agents.sh --force
```

然后重启 `dsh web` 并新建会话。

## 回滚

回滚工作流规则：

```bash
mv ~/.dsh/AGENTS.md.bak.YYYYMMDDHHMMSS ~/.dsh/AGENTS.md
```

停用专家 preset：

```bash
mv ~/.dsh/.agent-presets/codex-roles ~/.dsh/.agent-presets/codex-roles.disabled.YYYYMMDDHHMMSS
```

停用上游缓存：

```bash
mv ~/.dsh/_awesome-codex-subagents ~/.dsh/_awesome-codex-subagents.disabled.YYYYMMDDHHMMSS
```

这些操作不会删除 DeepSeek Harness 会话记录、模型配置或 npm 包缓存。
