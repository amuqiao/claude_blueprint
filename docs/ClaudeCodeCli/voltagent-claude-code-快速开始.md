# VoltAgent Claude Code 多 Agent 快速开始

> 本文只解决 Claude Code CLI 怎么安装、验证、使用和卸载 VoltAgent 多 agent。更完整的运行模式说明见 `claude-code-manual.md`。

## 什么时候读这份

你正在使用 Claude Code CLI，并希望通过 VoltAgent 的 Claude Code plugin 包获得一批专项 subagents。

如果你用的是 Codex，不走这份文档，改看 `voltagent-codex-快速开始.md`。两者安装方式不同。

## 推荐方式

优先用 plugin 方式。它支持 Claude Code 的插件管理、启用/禁用和更新。

先预览：

```bash
bash setup-claude-multiagent.sh --dry-run
```

确认后安装：

```bash
bash setup-claude-multiagent.sh --plugin
```

脚本会做两件事：

1. 注册 VoltAgent marketplace 并安装 3 个插件包。
2. 备份并覆盖写入整份 `~/.claude/CLAUDE.md`，加入多 agent 工作流规则。

如果你原来已有自定义 `~/.claude/CLAUDE.md`，安装后需要从备份里手动合并旧内容；脚本不会做内容级 merge。

## 手动安装命令

如果不跑脚本，也可以在 Claude Code 中依次执行：

```text
/plugin marketplace add VoltAgent/awesome-claude-code-subagents
/plugin install voltagent-core-dev@voltagent-subagents
/plugin install voltagent-lang@voltagent-subagents
/plugin install voltagent-qa-sec@voltagent-subagents
/reload-plugins
```

如果不能使用 plugin，可以走脚本的手动复制方式：

```bash
bash setup-claude-multiagent.sh --manual
```

项目级手动安装：

```bash
bash setup-claude-multiagent.sh --manual --project
```

注意：`--project` 只影响 agent `.md` 文件安装到当前项目 `.claude/agents/`；脚本仍会写入全局 `~/.claude/CLAUDE.md`。

三个包分别提供：

| 包 | 作用 |
|---|---|
| `voltagent-core-dev` | 前端、后端、全栈、API、UI、Electron、移动端等功能角色 |
| `voltagent-lang` | TypeScript、React、Python、Go、Rust、Java 等语言角色 |
| `voltagent-qa-sec` | code review、安全、性能、架构、QA、测试等评审角色 |

## 安装后验证

在 Claude Code 中打开：

```text
/plugin
```

确认 3 个包已安装并启用。然后重启 Claude Code，或运行：

```text
/reload-plugins
```

再试一个只读任务：

```text
Use voltagent-qa-sec:code-reviewer to review the current diff.
```

如果 Claude 能识别这个 agent 名称，说明插件角色已加载。

如果用的是 `--manual` 方式，agent 名称不带 `voltagent-xxx:` 命名空间。可以检查：

```bash
ls ~/.claude/agents | head
test -f ~/.claude/CLAUDE.md
```

## 日常怎么用

Plugin 方式直接在任务里点名 agent：

```text
Use voltagent-lang:typescript-pro to inspect the type errors.
Use voltagent-core-dev:frontend-developer to implement the UI change.
Use voltagent-qa-sec:security-auditor to review the auth flow.
```

Manual 方式使用不带命名空间的 agent 名：

```text
Use typescript-pro to inspect the type errors.
Use frontend-developer to implement the UI change.
Use security-auditor to review the auth flow.
```

如果使用脚本写入的 `~/.claude/CLAUDE.md`，代码任务开始前 Claude 会先问：

```text
1. plan -> subagent -> review -> verify
2. Just do it
```

选 `1` 时走完整多 agent 流程；选 `2` 时直接做，但最后仍要验证。

## 常用 agent 速查

这里只列最常用的几个。完整角色和运行模式见 `claude-code-manual.md`。

| 场景 | Plugin 方式 | Manual 方式 |
|---|---|---|
| TypeScript | `voltagent-lang:typescript-pro` | `typescript-pro` |
| 前端实现 | `voltagent-core-dev:frontend-developer` | `frontend-developer` |
| 后端 API | `voltagent-core-dev:backend-developer` | `backend-developer` |
| 代码 review | `voltagent-qa-sec:code-reviewer` | `code-reviewer` |
| 安全 review | `voltagent-qa-sec:security-auditor` | `security-auditor` |

## 更新

更新前建议先预览：

```bash
bash setup-claude-multiagent.sh --dry-run
```

Plugin 方式可以更新 marketplace：

```text
/plugin marketplace update voltagent-subagents
/reload-plugins
```

也可以重新运行：

```bash
bash setup-claude-multiagent.sh --plugin
```

脚本会再次覆盖整份 `~/.claude/CLAUDE.md`，已有文件会先备份。更新前如果你改过 `CLAUDE.md`，先保留自己的改动。

Manual 方式重新运行：

```bash
bash setup-claude-multiagent.sh --manual
```

## 卸载与回滚

脚本没有 `--uninstall`。卸载需要分别处理 plugin/agent 文件和 `~/.claude/CLAUDE.md`。

卸载插件：

```bash
claude plugin uninstall voltagent-core-dev
claude plugin uninstall voltagent-lang
claude plugin uninstall voltagent-qa-sec
```

如果需要撤回脚本写入的全局规则，恢复 `~/.claude/CLAUDE.md.backup.<时间戳>`：

```bash
ls ~/.claude/CLAUDE.md.backup.*
cp ~/.claude/CLAUDE.md.backup.<时间戳> ~/.claude/CLAUDE.md
```

如果第一次安装前没有 `~/.claude/CLAUDE.md`，就不会有备份；确认不再需要脚本生成的规则后，删除 `~/.claude/CLAUDE.md`。

如果不想卸载，只是临时停用插件，在 Claude Code 中用 `/plugin` 打开管理界面后 disable 对应包。

Manual 方式卸载时，只删除脚本复制的那些 agent `.md`：

| 安装方式 | agent 目录 |
|---|---|
| `--manual` | `~/.claude/agents/` |
| `--manual --project` | 当前项目 `.claude/agents/` |

不要直接删除整个 `~/.claude/agents/` 或项目 `.claude/agents/`，除非你确认里面没有自己的自定义 agents。
