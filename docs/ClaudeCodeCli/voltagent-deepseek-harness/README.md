# VoltAgent Roles for DeepSeek Harness

本目录提供一套可复现流程：用 DeepSeek Harness 原生 `agent preset` 和 `tool-subagent` 机制，把 `VoltAgent/awesome-codex-subagents` 中的角色转换成 `dsh web` 可用的固定专家子 agent。

## 先读哪篇

```text
第一次安装 / 给别人复现：
  读 voltagent-deepseek-harness-快速开始.md

想理解为什么这样实现：
  读 Codex 与 DeepSeek Harness 多角色 Agent 机制映射.md

只想看脚本用途：
  看本文的“文件职责”
```

## 文件职责

| 文件 | 职责 | 用户是否直接执行 |
|---|---|---|
| [voltagent-deepseek-harness-快速开始.md](./voltagent-deepseek-harness-快速开始.md) | 完整安装、验证、使用、排查流程 | 阅读 |
| [Codex 与 DeepSeek Harness 多角色 Agent 机制映射.md](./Codex%20与%20DeepSeek%20Harness%20多角色%20Agent%20机制映射.md) | 详细机制说明、心智模型、Codex 与 Harness 对照 | 阅读 |
| [AGENTS.md](./AGENTS.md) | DeepSeek Harness 工作流规则模板 | 不直接执行，由脚本复制 |
| [setup-deepseek-harness-workflow.sh](./setup-deepseek-harness-workflow.sh) | 安装 `~/.dsh/AGENTS.md` 工作流规则 | 是 |
| [setup-deepseek-harness-codex-agents.sh](./setup-deepseek-harness-codex-agents.sh) | 从 GitHub 上游生成 `~/.dsh/.agent-presets/codex-roles` | 是 |
| [convert-codex-agents-to-dsh-preset.py](./convert-codex-agents-to-dsh-preset.py) | 内部转换器，把上游 TOML 转成 Harness `.cordis.yml` | 通常否 |

## 最短复现路径

先安装 DeepSeek Harness：

```bash
npm install -g @deepseek-ai/dsh@0.1.0-rc.7
dsh web
```

然后执行本目录脚本：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness

./setup-deepseek-harness-workflow.sh
./setup-deepseek-harness-codex-agents.sh
```

最后重启：

```bash
dsh web
```

在 Web UI 新建会话时选择「专家角色模式」。

## 本方案新增配置

`dsh web` 首次启动会初始化 `~/.dsh`，其中 `profiles/`、`settings.yaml`、会话和缓存目录属于 DeepSeek Harness 自身运行配置。本文脚本只负责额外写入下面三类内容：

```text
~/.dsh/AGENTS.md
  由 setup-deepseek-harness-workflow.sh 写入
  作用：工作流规则

~/.dsh/_awesome-codex-subagents/
  由 setup-deepseek-harness-codex-agents.sh clone/update
  作用：GitHub 上游仓库缓存

~/.dsh/.agent-presets/codex-roles/
  由 setup-deepseek-harness-codex-agents.sh 生成
  作用：DeepSeek Harness 专家角色 preset
```

运行时关系：

```text
AGENTS.md
  告诉主 agent 怎么工作

codex-roles/agent.cordis.yml
  让主 agent 看到 subagent_api_designer、subagent_code_reviewer 等专家工具
```
