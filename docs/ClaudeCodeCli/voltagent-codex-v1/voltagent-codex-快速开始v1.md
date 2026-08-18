# VoltAgent Codex Subagents 快速开始 v1

> 本文只说明如何把 `VoltAgent/awesome-codex-subagents` 作为 Codex 原生 custom agents 使用。

## 先理解这件事

`awesome-codex-subagents` 是一组面向 Codex 的 `.toml` subagent 定义。Codex 读取这些文件后，你可以在任务里显式点名或要求 Codex 派发对应 subagent。

安装入口只有两个：

```text
~/.codex/agents/      # 全局 agents，所有项目可用
.codex/agents/        # 项目级 agents，只在当前项目可用，优先级更高
```

使用时直接引用 agent 名称。agent 名称以 `.toml` 文件里的 `name` 字段为准。

## 使用脚本安装

本文同目录提供独立脚本：

```bash
cd docs/ClaudeCodeCli/voltagent-codex-v1
bash setup-codex-subagents-v1.sh --dry-run
```

全局安装：

```bash
cd docs/ClaudeCodeCli/voltagent-codex-v1
bash setup-codex-subagents-v1.sh
```

项目级安装：

```bash
# 在要安装 agents 的项目根目录执行
bash /path/to/setup-codex-subagents-v1.sh --project
```

脚本会做这些事：

1. clone 或更新 `VoltAgent/awesome-codex-subagents`。
2. 复制上游 `categories/` 下全部 `.toml` agents 到目标 Codex agents 目录。
3. 写入本次安装清单，便于查看哪些 agent 由脚本安装。

脚本只安装 Codex subagent 文件。项目规则按项目需要单独维护。

只安装指定 agents：

```bash
bash setup-codex-subagents-v1.sh --agents=typescript-pro,code-reviewer,security-auditor
```

只列出上游可安装 agents：

```bash
bash setup-codex-subagents-v1.sh --list
```

如果目标目录已有同名 `.toml`，且该文件不在脚本生成的安装清单里，脚本会停止，避免覆盖你自己的 custom agent。确认要覆盖时显式加：

```bash
bash setup-codex-subagents-v1.sh --force
```

## 手动安装

也可以完全手动执行：

```bash
git clone --depth=1 https://github.com/VoltAgent/awesome-codex-subagents.git
mkdir -p ~/.codex/agents
find awesome-codex-subagents/categories -type f -name '*.toml' -exec cp -n {} ~/.codex/agents/ \;
```

项目级安装：

```bash
git clone --depth=1 https://github.com/VoltAgent/awesome-codex-subagents.git
mkdir -p .codex/agents
find awesome-codex-subagents/categories -type f -name '*.toml' -exec cp -n {} .codex/agents/ \;
```

如果同名 agent 同时存在于全局和项目级目录，项目级目录优先生效。

## 安装后验证

全局安装后检查：

```bash
ls ~/.codex/agents | head
test -f ~/.codex/agents/.voltagent-codex-subagents-v1.txt
```

项目级安装后检查：

```bash
ls .codex/agents | head
test -f .codex/agents/.voltagent-codex-subagents-v1.txt
```

然后重启或刷新 Codex 会话。

在 Codex 中可以这样使用：

```text
用 typescript-pro 检查这个 TypeScript 类型问题。
用 frontend-developer 实现这个界面改动。
用 code-reviewer review 当前 diff。
用 security-auditor 检查认证流程。
```

Codex 不会因为安装了 custom agents 就自动派发所有任务。需要在 prompt 中明确要求使用某个 agent，或在项目规则里明确多 agent 工作流。

## 更新

预览更新：

```bash
cd docs/ClaudeCodeCli/voltagent-codex-v1
bash setup-codex-subagents-v1.sh --dry-run
```

执行更新：

```bash
cd docs/ClaudeCodeCli/voltagent-codex-v1
bash setup-codex-subagents-v1.sh
```

项目级更新：

```bash
# 在要更新 agents 的项目根目录执行
bash /path/to/setup-codex-subagents-v1.sh --project
```

脚本会对缓存仓库执行 `git pull --ff-only`，然后重新复制当前上游 `.toml` agents。安装子集时，脚本会清理上一轮 manifest 中记录、但本轮不再选择的 agents。

## 回滚

如果只想清理本套 agents，删除脚本复制到目标目录的 `.toml` 文件和 `_awesome-codex-subagents` 缓存。不要直接删除整个 `~/.codex/agents/` 或 `.codex/agents/`，除非确认里面没有自己的 custom agents。

脚本会在 agents 目录写入安装清单：

```text
.voltagent-codex-subagents-v1.txt
```

清理前可以先根据这份清单确认文件范围。
