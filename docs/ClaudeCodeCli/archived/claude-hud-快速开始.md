# Claude HUD 快速开始

> 本文只解决 Claude HUD 怎么安装、验证、使用和卸载。完整的多 agent 可观测性对比见 `claude-code-observability.md`。

## 什么时候装

你在 Claude Code CLI 里跑 subagent、多 agent 或长任务时，想在执行过程中直接看到：

- 当前上下文用量
- 当前工具调用
- 正在运行的 agent 名称
- agent 已运行多久
- todo 进度

Claude HUD 是给“人”看的终端状态栏。它不替代 `/agents`，而是解决 `/agents` 只能在 Claude 空闲时打开的问题。

## 前置要求

需要 Node.js 18+：

```bash
node --version
```

如果没有 Node.js，macOS 可以先装：

```bash
brew install node
```

## 安装

在 Claude Code 会话中依次执行：

```text
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/reload-plugins
/claude-hud:setup
```

完成后重启 Claude Code。重启后 HUD 会显示在输入框下方。

## 安装后验证

重启 Claude Code 后，底部应该出现类似状态栏：

```text
[██████░░░░ 61%] ctx | Edit src/auth.ts | code-reviewer 1m24s
```

可以用一个只读任务验证：

```text
用 code-reviewer review 当前 diff，只报告问题，不修改文件。
```

如果任务执行时底部能看到 agent 名称和耗时，说明 HUD 已生效。

## 日常怎么看

常见信号：

| HUD 信息 | 说明 |
|---|---|
| `ctx` 百分比 | 当前上下文使用量 |
| 工具名或文件名 | Claude 正在执行的工具调用 |
| agent 名称 | 当前运行中的 subagent |
| agent 耗时 | 判断任务是否卡住的第一信号 |
| todo 进度 | 当前任务拆分和完成情况 |

经验判断：单个 agent 持续运行超过 5 分钟且没有明显输出时，通常需要检查是否卡住。

## 更新

在 Claude Code 中更新 marketplace 后重载插件：

```text
/plugin marketplace update claude-hud
/reload-plugins
```

如果 HUD 行为异常，重新运行 setup：

```text
/claude-hud:setup
```

然后重启 Claude Code。

## 卸载

卸载插件：

```bash
claude plugin uninstall claude-hud
```

卸载后重启 Claude Code，确认底部 HUD 消失。

如果只是临时不用，在 Claude Code 中打开：

```text
/plugin
```

然后 disable `claude-hud`。

## 常见问题

**执行中输入 `/agents` 没反应？**

这是 Claude Code 的正常限制：执行中输入的 `/agents` 会排队，只有 Claude 空闲时才会打开管理界面。HUD 的价值就是执行中也能持续显示状态。

**安装后没有状态栏？**

按顺序检查：

1. 是否已重启 Claude Code。
2. 是否运行过 `/claude-hud:setup`。
3. Node.js 是否可用。
4. `/plugin` 中 `claude-hud` 是否已启用。

**HUD 和 monitor-subagents 选哪个？**

先装 HUD。HUD 给你看，常驻、低操作成本；`monitor-subagents` 是给 Claude 自己按需检查 agent 健康，用于更复杂的多 agent 任务。

## 资料来源

- zread 快速开始：`https://zread.ai/jarrodwatts/claude-hud/2-quick-start`
- 本仓库可观测性说明：`claude-code-observability.md`
