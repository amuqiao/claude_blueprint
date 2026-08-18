# VoltAgent Roles for DeepSeek Harness

本目录提供 DeepSeek Harness 版 VoltAgent roles 的公共文档、公共转换器和多个独立 preset 安装方案。公共说明放在主目录；具体模式放在子目录，互不混用脚本参数。

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
| [common/](./common/) | 公共转换器，把上游 TOML 转成 Harness `.cordis.yml` | 通常否 |
| [codex-roles/](./codex-roles/) | 默认专家角色模式，生成 `~/.dsh/.agent-presets/codex-roles`；`AGENTS.md` 保持精简路由规则 | 是 |
| [codex-roles-full/](./codex-roles-full/) | 全量专家角色模式，生成 `~/.dsh/.agent-presets/codex-roles-full`；安装时把完整 `ROLE_INDEX.md` 追加进最终 `AGENTS.md` | 是 |

两个 preset 子目录都从 `VoltAgent/awesome-codex-subagents` 读取当前上游全部角色并注册为 Harness 工具。区别在规则层：`codex-roles` 让主 agent 按精简规则选择常见专家；`codex-roles-full` 把完整角色索引写入最终 `AGENTS.md`，方便主 agent 直接按全量表路由。

## 最短复现路径

先安装 DeepSeek Harness：

```bash
npm install -g @deepseek-ai/dsh@0.1.0-rc.7
dsh web
```

安装当前默认专家角色模式：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/codex-roles

./setup-deepseek-harness-workflow.sh
./setup-deepseek-harness-codex-agents.sh
```

安装全量专家角色模式：

```bash
cd /Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/voltagent-deepseek-harness/codex-roles-full

./setup-deepseek-harness-workflow.sh
./setup-deepseek-harness-codex-agents.sh
```

最后重启：

```bash
dsh web
```

在 Web UI 新建会话时选择对应模式：

```text
专家角色模式
专家角色全量模式
```

## 本方案新增配置

`dsh web` 首次启动会初始化 `~/.dsh`，其中 `profiles/`、`settings.yaml`、会话和缓存目录属于 DeepSeek Harness 自身运行配置。本文脚本只负责额外写入下面内容：

```text
~/.dsh/AGENTS.md
  由 codex-roles/setup-deepseek-harness-workflow.sh
  或 codex-roles-full/setup-deepseek-harness-workflow.sh 写入
  作用：工作流规则

~/.dsh/_awesome-codex-subagents/
  由 preset 安装脚本 clone/update
  作用：GitHub 上游仓库缓存

~/.dsh/.agent-presets/codex-roles/
  由 codex-roles/setup-deepseek-harness-codex-agents.sh 生成
  作用：DeepSeek Harness 专家角色 preset

~/.dsh/.agent-presets/codex-roles-full/
  由 codex-roles-full/setup-deepseek-harness-codex-agents.sh 生成
  作用：DeepSeek Harness 全量专家角色 preset
```

运行时关系：

```text
AGENTS.md
  告诉主 agent 怎么工作

~/.dsh/.agent-presets/codex-roles/agent.cordis.yml
或 ~/.dsh/.agent-presets/codex-roles-full/agent.cordis.yml
  让主 agent 看到 subagent_api_designer、subagent_code_reviewer 等专家工具
```
