# DeepSeek Harness 固定角色子 Agent 快速开始

本文说明如何直接以 `VoltAgent/awesome-codex-subagents` 为角色来源，生成 DeepSeek Harness 原生 `agent preset`，从而在 `dsh web` 中使用固定专家子 agent。

## 先理解这件事

这套方案不是替换 LLM URL，也不是让 DeepSeek 临时扮演 Codex。它把上游仓库里的 Codex 风格角色 TOML 转换成 DeepSeek Harness 自己能加载的 preset：

```text
VoltAgent/awesome-codex-subagents
  categories/**/*.toml
    ↓ 转换
~/.dsh/.agent-presets/codex-roles/
  preset.yml
  agent.cordis.yml
  agents/*.cordis.yml
    ↓ dsh web 加载
Web UI 选择「专家角色模式」
    ↓
主 agent 可调用 subagent_api_designer、subagent_code_reviewer 等固定专家工具
```

两层职责要分清：

| 文件或目录 | 运行时职责 |
|---|---|
| `~/.dsh/AGENTS.md` | 工作流规则：什么时候先问工作流、什么时候派发 subagent、如何 review/verify |
| `~/.dsh/.agent-presets/codex-roles/agent.cordis.yml` | Harness preset 入口：注册工具、persona、172 个固定专家子 agent |
| `~/.dsh/.agent-presets/codex-roles/preset.yml` | Web UI 展示名，例如「专家角色模式」 |
| `~/.dsh/.agent-presets/codex-roles/agents/*.cordis.yml` | 人读拆分文件，方便查单个角色；运行时入口仍是 `agent.cordis.yml` |

所以等价关系是：

```text
Codex:
  AGENTS.md 管规则
  ~/.codex/agents/*.toml 管专家身份

DeepSeek Harness:
  ~/.dsh/AGENTS.md 管规则
  ~/.dsh/.agent-presets/<preset-id>/agent.cordis.yml 管工具和专家 persona
```

## 文件说明

本目录包含：

```text
voltagent-deepseek-harness/
  AGENTS.md
  convert-codex-agents-to-dsh-preset.py
  setup-deepseek-harness-codex-agents.sh
  setup-deepseek-harness-workflow.sh
  voltagent-deepseek-harness-快速开始.md
  notes.md
```

- `AGENTS.md`：DeepSeek Harness 工作流规则模板。
- `setup-deepseek-harness-workflow.sh`：把模板写入 `~/.dsh/AGENTS.md` 或项目级 `AGENTS.md`。
- `setup-deepseek-harness-codex-agents.sh`：clone/update `VoltAgent/awesome-codex-subagents`，并生成 Harness 专家 preset。
- `convert-codex-agents-to-dsh-preset.py`：转换器，读取 `categories/**/*.toml` 或显式 source 目录。
- `notes.md`：机制说明和维护笔记，不是安装必做步骤。

## 前置条件

需要本机有：

```bash
git --version
python3 --version
node --version
npx --version
```

DeepSeek Harness 当前使用：

```bash
npx @deepseek-ai/dsh@0.1.0-rc.7 web
```

如果已经全局安装，也可以直接：

```bash
dsh web
```

## 第一步：安装工作流规则

先预览：

```bash
cd docs/ClaudeCodeCli/voltagent-deepseek-harness
bash setup-deepseek-harness-workflow.sh --dry-run
```

写入全局规则：

```bash
bash setup-deepseek-harness-workflow.sh
```

默认写入：

```text
~/.dsh/AGENTS.md
```

如果已存在，脚本会停止。确认要覆盖时：

```bash
bash setup-deepseek-harness-workflow.sh --force
```

覆盖前会生成 `.bak.YYYYMMDDHHMMSS` 备份。

项目级安装：

```bash
# 在目标项目根目录执行
bash /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/setup-deepseek-harness-workflow.sh --project
```

项目级模式会写入当前 Git 项目的：

```text
AGENTS.md
```

## 第二步：安装专家角色 preset

先预览完整流程：

```bash
cd docs/ClaudeCodeCli/voltagent-deepseek-harness
bash setup-deepseek-harness-codex-agents.sh --dry-run
```

正式生成：

```bash
bash setup-deepseek-harness-codex-agents.sh
```

脚本默认做这些事：

```text
1. clone/update https://github.com/VoltAgent/awesome-codex-subagents.git
2. 缓存到 ~/.dsh/_awesome-codex-subagents
3. 读取 categories/**/*.toml
4. 复制 DeepSeek Harness 内置 standard preset 作为基底
5. 生成 ~/.dsh/.agent-presets/codex-roles
```

生成后的目录：

```text
~/.dsh/.agent-presets/codex-roles/
  preset.yml
  agent.cordis.yml
  base/
    standard.agent.cordis.yml
  agents/
    index.cordis.yml
    api-designer.cordis.yml
    code-reviewer.cordis.yml
    ...
  agent-role-map.md
```

如果目标 preset 已存在，脚本会停止。确认要替换时：

```bash
bash setup-deepseek-harness-codex-agents.sh --force
```

替换前会把旧目录改名为：

```text
~/.dsh/.agent-presets/codex-roles.bak.YYYYMMDDHHMMSS
```

### 使用本地 source 目录

如果你已经有上游仓库本地副本，可以跳过 clone/pull：

```bash
bash setup-deepseek-harness-codex-agents.sh \
  --source-dir=/Users/admin/.codex/_awesome-codex-subagents \
  --force
```

旧参数仍兼容，但不再是默认路径：

```bash
bash setup-deepseek-harness-codex-agents.sh \
  --codex-agents-dir=/Users/admin/.codex/agents \
  --force
```

这只适合调试或兼容旧流程。推荐主流程始终使用 upstream repo。

## 第三步：启动 DeepSeek Harness Web

在要工作的项目目录启动：

```bash
cd /path/to/your/project
dsh web
```

如果没有全局 `dsh`：

```bash
npx @deepseek-ai/dsh@0.1.0-rc.7 web
```

打开 Web UI 后：

1. 选择工作区目录。
2. 配置模型和 API key。
3. 新建会话时选择「专家角色模式」。
4. 不要用「极简模式」复现多 agent 工作流。

已经开始的会话不会自动切换到新 preset。安装或重新生成 preset 后，建议重启 `dsh web` 并新建会话验证。

## 第四步：验证 profile 能力

检查 `web` profile 是否包含通用 subagent / workflow 能力：

```bash
dsh web --dump-config > /tmp/dsh-web-config.yml
grep -E 'id: tool-subagent$|toolName: subagent$' /tmp/dsh-web-config.yml
grep -E 'id: tool-subagent-fork$|toolName: subagent_fork$' /tmp/dsh-web-config.yml
grep -E 'id: tool-workflow$|name: .+dsh-tool-workflow' /tmp/dsh-web-config.yml
grep -E 'id: agent-presets$|default: standard' /tmp/dsh-web-config.yml
```

四条 `grep` 都应有输出。

检查专家 preset 是否生成完整：

```bash
test -f ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
test -f ~/.dsh/.agent-presets/codex-roles/preset.yml
grep -c '^- id: tool-subagent-role-' ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

最后一条应输出上游仓库当前的角色数量，例如 `172`。

## 第五步：验证工作流

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
- 派发一个只读 subagent。
- 主 agent 汇总子 agent 结果。
- 最后说明没有修改文件，因此 verify 以只读检查为准。

## 固定专家工具怎么用

上游角色名会转换成 Harness 工具名：

```text
api-designer                  -> subagent_api_designer
code-reviewer                 -> subagent_code_reviewer
typescript-pro                -> subagent_typescript_pro
dotnet-framework-4.8-expert   -> subagent_dotnet_framework_4_8_expert
```

可以直接要求主 agent 调用：

```text
使用工作流 1。请调用 subagent_code_reviewer 审查当前改动，只输出阻断级问题、证据和建议。
```

固定工具已经带有 persona，但 prompt 仍要写清：

- 任务目标。
- 可读或可写范围。
- 是否允许修改文件。
- 输出格式。
- 验证要求。

原因是：persona 固定“这个专家是谁”，本次 prompt 固定“这次具体做什么”。

## 常用命令

只更新专家 preset：

```bash
cd docs/ClaudeCodeCli/voltagent-deepseek-harness
bash setup-deepseek-harness-codex-agents.sh --force
```

查看角色映射表：

```bash
less ~/.dsh/.agent-presets/codex-roles/agent-role-map.md
```

查看是否还有运行时 include：

```bash
grep -n '^- id: include-' ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

这条命令应该没有输出。当前实现要求 `agent.cordis.yml` 是扁平化入口，避免用户 preset 子 include 的包解析问题。

## 排查

### `AGENTS.md` 没生效

确认写入位置：

```bash
test -f ~/.dsh/AGENTS.md
```

然后重启 `dsh web` 或新建会话。DeepSeek Harness 的 instruction 不是简单文件 watcher；新会话最容易验证。

### 看不到「专家角色模式」

确认 preset 文件存在：

```bash
test -f ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
test -f ~/.dsh/.agent-presets/codex-roles/preset.yml
```

确认 `preset.yml`：

```bash
cat ~/.dsh/.agent-presets/codex-roles/preset.yml
```

### 选择「专家角色模式」后秒切回「标准模式」

这通常表示 preset 被发现了，但 mount 失败。重新生成扁平化 preset：

```bash
cd docs/ClaudeCodeCli/voltagent-deepseek-harness
bash setup-deepseek-harness-codex-agents.sh --force
```

然后重启 `dsh web` 并新建会话。

### 端口占用

如果出现：

```text
EADDRINUSE: address already in use 127.0.0.1:3080
```

说明已有 `dsh web` 在运行。关闭旧进程或直接打开已有地址：

```text
http://127.0.0.1:3080
```

## 回滚

回滚全局工作流规则：

```bash
mv ~/.dsh/AGENTS.md.bak.YYYYMMDDHHMMSS ~/.dsh/AGENTS.md
```

删除专家 preset：

```bash
mv ~/.dsh/.agent-presets/codex-roles ~/.dsh/.agent-presets/codex-roles.disabled.YYYYMMDDHHMMSS
```

删除上游缓存：

```bash
mv ~/.dsh/_awesome-codex-subagents ~/.dsh/_awesome-codex-subagents.disabled.YYYYMMDDHHMMSS
```

删除 preset 不会删除 DeepSeek Harness 会话记录、模型配置或 npm 包缓存。
