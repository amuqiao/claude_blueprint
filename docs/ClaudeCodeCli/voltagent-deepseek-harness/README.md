# VoltAgent Roles for DeepSeek Harness

本目录提供 DeepSeek Harness 版 VoltAgent roles 的公共文档、公共转换器和多个 preset 配置。主目录负责文档说明；`scripts/` 负责安装入口、转换器和具体模式配置。

## 先读哪篇

```text
第一次安装 / 给别人复现：
  读 voltagent-deepseek-harness-快速开始.md

想理解为什么这样实现：
  读 Codex 与 DeepSeek Harness 多角色 Agent 机制映射.md

只想看脚本用途：
  看本文的“文件职责”
```

## 目录职责

| 路径 | 职责 | 用户是否直接执行 |
|---|---|---|
| [voltagent-deepseek-harness-快速开始.md](./voltagent-deepseek-harness-快速开始.md) | 完整安装、验证、使用、排查流程 | 阅读 |
| [Codex 与 DeepSeek Harness 多角色 Agent 机制映射.md](./Codex%20与%20DeepSeek%20Harness%20多角色%20Agent%20机制映射.md) | 详细机制说明、心智模型、Codex 与 Harness 对照 | 阅读 |
| [scripts/setup-deepseek-harness-workflow.sh](./scripts/setup-deepseek-harness-workflow.sh) | 公共工作流规则安装入口，通过 `--preset-dir` 选择模式配置目录 | 是 |
| [scripts/setup-deepseek-harness-voltagent-roles.sh](./scripts/setup-deepseek-harness-voltagent-roles.sh) | 公共专家角色 preset 安装入口，通过 `--preset-dir` 选择模式配置目录 | 是 |
| [scripts/common/](./scripts/common/) | 公共转换器，把上游 TOML 转成 Harness `.cordis.yml` | 通常否 |
| [scripts/voltagent-roles-lite/](./scripts/voltagent-roles-lite/) | 推荐日常使用的 lite 专家角色配置，按 `ROLE_ALLOWLIST.txt` 生成较少但覆盖常用领域的固定专家工具 | 否 |
| [scripts/voltagent-roles/](./scripts/voltagent-roles/) | 默认专家角色配置，`ROLE_ALLOWLIST.txt` 固定全量角色集，`AGENTS.md` 保持精简路由规则 | 否 |
| [scripts/voltagent-roles-full/](./scripts/voltagent-roles-full/) | 全量专家角色配置，`ROLE_ALLOWLIST.txt` 固定全量角色集，安装 workflow 时追加 `ROLE_INDEX.md` | 否 |

三个 preset 子目录都从 `VoltAgent/awesome-codex-subagents` 读取角色源，并通过各自的 `ROLE_ALLOWLIST.txt` 明确声明要注册哪些角色。`voltagent-roles-lite` 是 67 个常用专家；`voltagent-roles` 和 `voltagent-roles-full` 当前是 172 个全量专家。二者区别在规则层：`voltagent-roles` 让主 agent 按精简规则选择常见专家；`voltagent-roles-full` 把完整角色索引写入最终 `AGENTS.md`，方便主 agent 直接按全量表路由。

## 最短复现路径

先安装 DeepSeek Harness：

```bash
npm install -g @deepseek-ai/dsh@0.1.0-rc.7
dsh web
```

安装推荐的 lite 专家角色模式：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/scripts

./setup-deepseek-harness-workflow.sh --preset-dir=voltagent-roles-lite
./setup-deepseek-harness-voltagent-roles.sh --preset-dir=voltagent-roles-lite
```

离线安装时，把第二条命令改为指定本地源码目录：

```bash
./setup-deepseek-harness-voltagent-roles.sh \
  --preset-dir=voltagent-roles-lite \
  --local-source=/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/awesome-codex-subagents
```

`--local-source` 要求目录是 `VoltAgent/awesome-codex-subagents` 仓库根目录，并且包含 `categories/**/*.toml`。脚本会跳过 `git clone/pull`，直接读取本地角色文件。

脚本按内容保证幂等：重复执行同样输入时会提示目标已是最新，不会重写或创建备份。只有目标内容不同才需要显式加 `--force` 覆盖，覆盖前会生成 `.bak` 备份。每个模式目录的 `ROLE_ALLOWLIST.txt` 是安装契约的一部分，缺失时脚本会直接失败，避免意外退化成全量安装。

安装当前默认专家角色模式：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/scripts

./setup-deepseek-harness-workflow.sh --preset-dir=voltagent-roles
./setup-deepseek-harness-voltagent-roles.sh --preset-dir=voltagent-roles
```

安装全量专家角色模式：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/scripts

./setup-deepseek-harness-workflow.sh --preset-dir=voltagent-roles-full
./setup-deepseek-harness-voltagent-roles.sh --preset-dir=voltagent-roles-full
```

最后重启：

```bash
dsh web
```

在 Web UI 新建会话时选择对应模式：

```text
专家角色精简模式
专家角色模式
专家角色全量模式
```

## 本方案新增配置

`dsh web` 首次启动会初始化 `~/.dsh`，其中 `profiles/`、`settings.yaml`、会话和缓存目录属于 DeepSeek Harness 自身运行配置。本文脚本只负责额外写入下面内容：

```text
~/.dsh/AGENTS.md
  由 ./scripts/setup-deepseek-harness-workflow.sh --preset-dir=<mode> 写入
  作用：工作流规则

~/.dsh/_awesome-codex-subagents/
  由 preset 安装脚本 clone/update
  作用：GitHub 上游仓库缓存
  仅在线安装模式使用；离线安装时由 --local-source 指定源码目录

~/.dsh/.agent-presets/voltagent-roles-lite/
  由 ./scripts/setup-deepseek-harness-voltagent-roles.sh --preset-dir=voltagent-roles-lite 生成
  作用：DeepSeek Harness lite 专家角色 preset

~/.dsh/.agent-presets/voltagent-roles/
  由 ./scripts/setup-deepseek-harness-voltagent-roles.sh --preset-dir=voltagent-roles 生成
  作用：DeepSeek Harness 专家角色 preset

~/.dsh/.agent-presets/voltagent-roles-full/
  由 ./scripts/setup-deepseek-harness-voltagent-roles.sh --preset-dir=voltagent-roles-full 生成
  作用：DeepSeek Harness 全量专家角色 preset
```

运行时关系：

```text
AGENTS.md
  告诉主 agent 怎么工作

~/.dsh/.agent-presets/voltagent-roles-lite/agent.cordis.yml
或 ~/.dsh/.agent-presets/voltagent-roles/agent.cordis.yml
或 ~/.dsh/.agent-presets/voltagent-roles-full/agent.cordis.yml
  让主 agent 看到 subagent_api_designer、subagent_code_reviewer 等专家工具
```
