# VoltAgent Codex 多 Agent 快速开始

> 本文只解决 Codex 怎么安装、验证、使用和卸载 VoltAgent 多 agent。Codex 路线使用 `.toml custom agents + AGENTS.md`，不使用 Claude Code 的 `/plugin install voltagent-*` 命令。

## 什么时候读这份

你正在使用 Codex CLI，并希望获得与 VoltAgent Claude Code 三个插件包对齐的专项 agents。

如果你用的是 Claude Code CLI，改看 `voltagent-claude-code-快速开始.md`。

## 关键区别

Claude Code 路线安装的是 plugin 包：

```text
/plugin install voltagent-core-dev@voltagent-subagents
```

Codex 路线安装的是 Codex 原生 custom agents：

```text
~/.codex/agents/*.toml
~/.codex/AGENTS.md
```

所以不要把 Claude Code 的 `/plugin` 命令复制到 Codex 里用。本文以 `setup-codex-multiagent.sh` 为准。

## 推荐安装

先预览：

```bash
bash setup-codex-multiagent.sh --dry-run
```

全局安装：

```bash
bash setup-codex-multiagent.sh
```

项目级安装：

```bash
bash setup-codex-multiagent.sh --project
```

注意：`--project` 安装到脚本解析到的 Git 项目根目录，也就是脚本所在仓库的 project root。要安装到另一个项目，请把脚本放到那个项目里运行，或先确认脚本解析出的项目根就是目标项目。

脚本会做三件事：

1. clone 或更新 `VoltAgent/awesome-codex-subagents`。
2. 安装 57 个 `.toml` agents 到 `~/.codex/agents/` 或项目 `.codex/agents/`。`design-bridge` 没有 Codex 版本，所以比 Claude Code 少 1 个 core agent。
3. 备份并覆盖写入整份 `~/.codex/AGENTS.md` 或项目 `AGENTS.md`，加入 Codex 多 agent 工作流规则。

如果你原来已有自定义 `AGENTS.md`，安装后需要从备份里手动合并旧内容；脚本不会做内容级 merge。

## 安装后验证

全局安装后检查：

```bash
ls ~/.codex/agents | head
test -f ~/.codex/AGENTS.md
```

项目级安装后检查。先进入脚本实际安装到的项目根目录，再执行：

```bash
ls .codex/agents | head
test -f AGENTS.md
```

然后重启 Codex，发一个代码任务。脚本写入的 `AGENTS.md` 会要求先选择工作流：

```text
1. plan -> subagent -> review -> verify
2. Just do it
```

选 `1` 后，Codex 可以按任务需要使用 `typescript-pro`、`frontend-developer`、`code-reviewer` 等 custom agents。

执行中需要查看 subagents 时，用 Codex 的：

```text
/agent
```

不要用 Claude Code 的 `/agents` 或 `claude agents`。

## 日常怎么用

正常描述任务即可，也可以点名 agent：

```text
用 typescript-pro 检查类型问题。
用 frontend-developer 实现这个界面改动。
用 code-reviewer review 当前 diff。
用 security-auditor 检查认证流程。
```

Codex 版本没有 `voltagent-lang:`、`voltagent-core-dev:`、`voltagent-qa-sec:` 命名空间。直接使用 agent 名称。

## 常用 agent 速查

这里只列最常用的几个。完整选择规则会写入 `AGENTS.md`。

| 场景 | 推荐 agent |
|---|---|
| TypeScript / 类型问题 | `typescript-pro` |
| 后端 API | `backend-developer` |
| 代码质量 review | `code-reviewer` |
| 安全 review | `security-auditor` |
| 架构 review | `architect-reviewer` |

## 更新

更新前建议先预览：

```bash
bash setup-codex-multiagent.sh --dry-run
```

然后重新运行安装脚本：

```bash
bash setup-codex-multiagent.sh
```

项目级安装则加：

```bash
bash setup-codex-multiagent.sh --project
```

脚本会 pull 最新 agents，并在覆盖整份 `AGENTS.md` 前生成备份。更新前如果你改过 `AGENTS.md`，先保留自己的改动。

## 卸载与回滚

脚本目前没有独立卸载命令。卸载时按安装范围清理。

全局安装的主要文件：

```text
~/.codex/agents/*.toml
~/.codex/_awesome-subagents/
~/.codex/AGENTS.md
~/.codex/AGENTS.md.backup.<时间戳>
```

项目级安装的主要文件。这里的“项目”是脚本解析到的项目根目录：

```text
.codex/agents/*.toml
.codex/_awesome-subagents/
AGENTS.md
AGENTS.md.backup.<时间戳>
```

如果这些目录只用于本套 VoltAgent agents，可以删除对应 `.toml` agents 和 `_awesome-subagents` 缓存。不要直接删除整个 `~/.codex/agents/`，除非你确认里面没有自己的 custom agents。

回滚 `AGENTS.md`：

```bash
ls ~/.codex/AGENTS.md.backup.*
cp ~/.codex/AGENTS.md.backup.<时间戳> ~/.codex/AGENTS.md
```

项目级安装则恢复项目里的 `AGENTS.md.backup.<时间戳>`。

如果第一次安装前没有 `AGENTS.md`，就不会有备份；确认不再需要脚本生成的规则后，删除对应的 `~/.codex/AGENTS.md` 或项目 `AGENTS.md`。
