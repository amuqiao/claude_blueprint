# Claude Code Agent 可观测性

> 解决一个问题：多 agent 任务跑起来之后，怎么知道它在做什么、有没有卡住？

---

## 核心限制

Subagent 执行期间，`/agents` 命令**无法触发**——它只在 Claude 空闲等待输入时生效。执行中输入 `/agents` 会进入消息队列，而非打开管理界面。

```
Claude 执行中（✢ Forging…）
  └─ 输入 /agents → 排队等待，不触发界面    ← 常见误区

Claude 空闲，等待输入
  └─ 输入 /agents → 正常打开管理界面        ← 正确时机
```

解决方案：在任务开始**之前**装好可观测工具。

---

## 两种工具，两个视角

```
Claude HUD（Plugin）                  monitor-subagents（Skill）
给「你」看                              给「Claude」用
─────────────────────────────          ─────────────────────────────
终端底部状态栏常驻显示                   让 Claude 自己感知 agent 健康
• 上下文用量                            • 检测 agent 接近上下文上限
• 当前工具调用                          • 发现 agent 卡住或停滞
• 运行中 agent 名称 + 耗时              • 主动预警，触发干预决策
• todo 进度                            • 输出 JSON，可与 jq 配合
~300ms 刷新，执行中全程可见              Claude 按需调用，不自动常驻
```

---

## 一、Claude HUD

### 安装

前置：需要 Node.js 18+。

```bash
node --version      # 检查是否已有
brew install node   # 没有则安装
```

在 Claude Code 会话中依次执行：

```
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/reload-plugins
/claude-hud:setup
```

完成后**重启 Claude Code**，HUD 出现在输入框下方。

### 效果

```
┌─────────────────────────────────────────────────────────────────┐
│  对话内容...                                                      │
│  ❯ 输入框                                                         │
├─────────────────────────────────────────────────────────────────┤
│ [████████░░ 78%] ctx │ ✎ Edit src/auth.ts │ ⚡ code-reviewer 2m │
└─────────────────────────────────────────────────────────────────┘
       上下文用量          当前工具调用        agent 名称 + 耗时
```

多个 agent 并行时：

```
│ [██████░░░░ 61%] │ ⚡ typescript-pro 1m24s │ ⚡ security-auditor 3m07s │
```

**判断信号**：单个 agent 耗时超过 5 分钟，通常意味着卡住，可中断重试。

### 卸载

```bash
claude plugin uninstall claude-hud
```

---

## 二、monitor-subagents

### 安装

```bash
mkdir -p ~/.claude/skills
curl -L https://raw.githubusercontent.com/cowwoc/cat/main/skills/monitor-subagents/SKILL.md \
     -o ~/.claude/skills/monitor-subagents.md
```

> 如果 curl 路径报 404，去 [github.com/cowwoc/cat](https://github.com/cowwoc/cat) 手动下载 SKILL.md 放入 `~/.claude/skills/`。

安装后 Claude 会话启动时自动加载，无需额外激活。

### 使用

在对话中用自然语言触发：

```
执行过程中定期检查所有 subagent 的 token 用量，有接近上限的提前告诉我

当前所有 subagent 的状态如何？有没有卡住的？
```

Claude 输出示例：

```json
{
  "agents": [
    { "name": "typescript-pro",   "status": "active",   "tokens_used": 45230,  "limit": 200000 },
    { "name": "security-auditor", "status": "stalled",  "tokens_used": 187400, "limit": 200000 },
    { "name": "code-reviewer",    "status": "complete", "tokens_used": 23100,  "limit": 200000 }
  ]
}
```

`security-auditor` 状态 `stalled` 且 token 接近上限 → 需要干预。

### 卸载

```bash
rm ~/.claude/skills/monitor-subagents.md
```

---

## 选择参考

```
                    执行中可用   给谁用    安装方式    适合场景
────────────────────────────────────────────────────────────────
Claude HUD          ✓ 全程常驻   你        Plugin      实时感知进度，发现耗时异常
monitor-subagents   ✓ 按需调用   Claude    Skill       让 Claude 自主发现 agent 卡住/超限
/agents             ✗ 仅空闲时   你        内置命令    空闲时管理、停止子代理
claude agents       ✓ 独立终端   你        内置命令    管理后台 Background Agent
```

**推荐组合：**

```
Claude HUD          必装，零操作成本，执行中全程可见
monitor-subagents   复杂多 agent 任务时追加，让 Claude 具备自主感知
/agents             任务完成后空闲时，查看详情或做清理
```
