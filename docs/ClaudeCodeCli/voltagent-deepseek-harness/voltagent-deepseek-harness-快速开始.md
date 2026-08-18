# DeepSeek Harness 固定角色子 Agent 快速开始

本文是一份可交给其他人复现的安装手册：先完成 DeepSeek Harness 前置安装，再选择一个 preset 子目录，从 `VoltAgent/awesome-codex-subagents` 生成 Harness 专家角色模式，最后用 `AGENTS.md` 规则驱动多 agent 工作流。

如果你想先理解 Codex 和 DeepSeek Harness 分别如何实现多角色 agent 协作，读 [Codex 与 DeepSeek Harness 多角色 Agent 机制映射.md](./Codex%20与%20DeepSeek%20Harness%20多角色%20Agent%20机制映射.md)。本文只保留安装、验证和排查所需的最少解释。

## 整体流程

```text
安装 DeepSeek Harness
  npm install -g @deepseek-ai/dsh@0.1.0-rc.7
  dsh web
    ↓ 初始化 ~/.dsh

选择 preset 子目录
  codex-roles/
    生成 ~/.dsh/.agent-presets/codex-roles

  codex-roles-full/
    生成 ~/.dsh/.agent-presets/codex-roles-full

安装工作流规则
  setup-deepseek-harness-workflow.sh
    ↓ 写入 ~/.dsh/AGENTS.md

安装专家角色 preset
  setup-deepseek-harness-codex-agents.sh
    ↓ clone/update VoltAgent/awesome-codex-subagents
    ↓ 调用 ../common/convert-codex-agents-to-dsh-preset.py
    ↓ 生成对应 ~/.dsh/.agent-presets/<preset-id>

使用
  dsh web
    ↓ Web UI 新建会话选择对应模式
    ↓ 主 agent 按 AGENTS.md 调用 subagent_api_designer / subagent_code_reviewer 等工具
```

这套方案不是替换模型 URL，也不是让 DeepSeek 临时扮演 Codex。它使用 DeepSeek Harness 原生机制：

```text
~/.dsh/AGENTS.md
  负责规则：什么时候问工作流、什么时候派发子 agent、怎么 review/verify

~/.dsh/.agent-presets/<preset-id>/agent.cordis.yml
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

## 目录结构

```text
voltagent-deepseek-harness/
  README.md
    目录入口和文件职责索引

  voltagent-deepseek-harness-快速开始.md
    面向用户的完整复现步骤，也就是本文

  Codex 与 DeepSeek Harness 多角色 Agent 机制映射.md
    详细机制说明、心智模型、Codex 与 Harness 对照

  common/
    convert-codex-agents-to-dsh-preset.py
      公共转换器，把上游 TOML 转成 Harness .cordis.yml

  codex-roles/
    AGENTS.md
      要安装到 ~/.dsh/AGENTS.md 的工作流规则模板

    setup-deepseek-harness-workflow.sh
      安装工作流规则

    setup-deepseek-harness-codex-agents.sh
      从 GitHub 上游安装专家角色 preset：codex-roles

  codex-roles-full/
    AGENTS.md
      全量模式独立工作流规则模板

    ROLE_INDEX.md
      全量固定专家角色索引；安装 workflow 时会追加到最终 AGENTS.md

    setup-deepseek-harness-workflow.sh
      安装工作流规则，并合并 ROLE_INDEX.md

    setup-deepseek-harness-codex-agents.sh
      从 GitHub 上游安装全量专家角色 preset：codex-roles-full
```

## 安装默认专家角色模式

默认专家角色模式生成：

```text
~/.dsh/.agent-presets/codex-roles
```

它会从 `VoltAgent/awesome-codex-subagents` 生成当前上游全部角色工具，但最终 `AGENTS.md` 只保留精简路由规则，不把完整角色表塞进规则文件。

执行：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/codex-roles

./setup-deepseek-harness-workflow.sh
./setup-deepseek-harness-codex-agents.sh
```

如果目标文件或目录已存在，脚本会停止，避免覆盖。确认要更新时使用：

```bash
./setup-deepseek-harness-workflow.sh --force
./setup-deepseek-harness-codex-agents.sh --force
```

Web UI 中选择：

```text
专家角色模式
```

## 安装全量专家角色模式

全量专家角色模式生成：

```text
~/.dsh/.agent-presets/codex-roles-full
```

它和默认模式的区别在规则层：全量模式的 workflow 安装脚本会把 `codex-roles-full/ROLE_INDEX.md` 追加到最终生效的 `AGENTS.md`，让主 agent 在规则文件里直接看到完整角色路由索引。

执行：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/codex-roles-full

./setup-deepseek-harness-workflow.sh
./setup-deepseek-harness-codex-agents.sh
```

如果目标文件或目录已存在，脚本会停止，避免覆盖。确认要更新时使用：

```bash
./setup-deepseek-harness-workflow.sh --force
./setup-deepseek-harness-codex-agents.sh --force
```

Web UI 中选择：

```text
专家角色全量模式
```

## `~/.dsh` 生成结果

执行某个 preset 子目录脚本后，会额外新增或更新对应内容。只运行 `codex-roles/` 就只生成 `codex-roles`；只运行 `codex-roles-full/` 就只生成 `codex-roles-full`。

```text
~/.dsh/
  AGENTS.md
    由 setup-deepseek-harness-workflow.sh 写入
    作用：DeepSeek Harness 工作流规则

  _awesome-codex-subagents/
    由 setup-deepseek-harness-codex-agents.sh clone/update
    作用：缓存 https://github.com/VoltAgent/awesome-codex-subagents.git

  .agent-presets/
    <preset-id>/
      例如 codex-roles 或 codex-roles-full
      由当前执行的 preset 子目录决定
```

每个 preset 目录内部结构类似：

```text
preset.yml
  Web UI 展示名

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

## 转换器调试

正常用户不需要手动运行转换器。调试转换逻辑时，可以从主目录执行：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness

python3 common/convert-codex-agents-to-dsh-preset.py \
  --source-dir=~/.dsh/_awesome-codex-subagents \
  --output-dir=/tmp/codex-roles-preview \
  --preset-id=codex-roles \
  --force
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
3. 新建会话时选择「专家角色模式」或「专家角色全量模式」。
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

验证默认专家 preset：

```bash
test -f ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
test -f ~/.dsh/.agent-presets/codex-roles/preset.yml
grep -c '^- id: tool-subagent-role-' ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
```

验证全量专家 preset：

```bash
test -f ~/.dsh/.agent-presets/codex-roles-full/agent.cordis.yml
test -f ~/.dsh/.agent-presets/codex-roles-full/preset.yml
grep -c '^- id: tool-subagent-role-' ~/.dsh/.agent-presets/codex-roles-full/agent.cordis.yml
```

最后一条应输出上游仓库当前角色数量，例如：

```text
172
```

验证没有运行时 include：

```bash
grep -n '^- id: include-' ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
grep -n '^- id: include-' ~/.dsh/.agent-presets/codex-roles-full/agent.cordis.yml
```

这两条命令应该没有输出。当前方案要求 `agent.cordis.yml` 保持扁平化，避免用户 preset 子 include 的包解析问题。

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

### 是否只执行工作流脚本就够了

不够。工作流脚本只安装规则：

```text
~/.dsh/AGENTS.md
```

如果要使用固定专家工具，还必须执行同一 preset 子目录下的：

```text
setup-deepseek-harness-codex-agents.sh
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

### 看不到专家模式

确认对应 preset 文件存在：

```bash
test -f ~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
test -f ~/.dsh/.agent-presets/codex-roles-full/agent.cordis.yml
```

然后重启 `dsh web` 并新建会话。

### 选择专家模式后秒切回标准模式

通常表示 preset 被发现了，但 mount 失败。重新生成对应 preset：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/codex-roles
./setup-deepseek-harness-codex-agents.sh --force
```

或：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/codex-roles-full
./setup-deepseek-harness-codex-agents.sh --force
```

然后重启 `dsh web` 并新建会话。

## 回滚

回滚工作流规则：

```bash
mv ~/.dsh/AGENTS.md.bak.YYYYMMDDHHMMSS ~/.dsh/AGENTS.md
```

停用默认专家 preset：

```bash
mv ~/.dsh/.agent-presets/codex-roles ~/.dsh/.agent-presets/codex-roles.disabled.YYYYMMDDHHMMSS
```

停用全量专家 preset：

```bash
mv ~/.dsh/.agent-presets/codex-roles-full ~/.dsh/.agent-presets/codex-roles-full.disabled.YYYYMMDDHHMMSS
```

停用上游缓存：

```bash
mv ~/.dsh/_awesome-codex-subagents ~/.dsh/_awesome-codex-subagents.disabled.YYYYMMDDHHMMSS
```

这些操作不会删除 DeepSeek Harness 会话记录、模型配置或 npm 包缓存。
