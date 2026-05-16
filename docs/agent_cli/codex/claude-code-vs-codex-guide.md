# Claude Code CLI vs Codex CLI — 完整心智模型指南

> **适用对象**：团队新成员 onboarding，了解"给 AI 的指令文件"概念，但不清楚两个工具的配置体系和能力边界。
>
> **阅读目标**：读完后能独立判断"我要做 X，应该改哪个文件、放哪一层、用什么格式写"。

---

## 目录

1. [两个工具是什么](#1-两个工具是什么)
2. [统一概念词映射表](#2-统一概念词映射表)
3. [关键分工：Instructions 文件 vs 配置文件](#3-关键分工instructions-文件-vs-配置文件)
4. [作用域层级模型](#4-作用域层级模型)
5. [优先级规则](#5-优先级规则)
6. [能力详解](#6-能力详解)
   - [Instructions — CLAUDE.md vs AGENTS.md](#61-instructions)
   - [Rule — 权限与行为控制](#62-rule)
   - [Hook — 事件驱动自动化](#63-hook)
   - [Skill — 可复用工作方法](#64-skill)
   - [Command — 用户主动召唤的快捷指令](#65-command)
   - [Plugin — 打包与分发](#66-plugin)
   - [MCP — 外部工具接入](#67-mcp)
   - [Agent / Subagent — 专属角色 AI](#68-agent--subagent)
   - [Profile — 配置预设切换（Codex 独有）](#69-profile)
   - [Memory — 跨会话记忆（Claude Code 独有）](#610-memory)
7. [配置模板（可直接 fork）](#7-配置模板)
8. [决策工具](#8-决策工具)
9. [排错指南](#9-排错指南)
10. [管理员视角](#10-管理员视角)

---

## 1. 两个工具是什么

| | Claude Code CLI | Codex CLI |
|---|---|---|
| **出品方** | Anthropic | OpenAI |
| **底层模型** | Claude（Sonnet 4.6 默认） | GPT 系列（gpt-5.3-codex 等） |
| **安装** | `npm install -g @anthropic-ai/claude-code` | `npm install -g @openai/codex` |
| **配置格式** | JSON + Markdown | TOML + Markdown |
| **主配置文件** | `settings.json` | `config.toml` |
| **Instructions 文件** | `CLAUDE.md` | `AGENTS.md` |
| **独有特性** | Memory 系统、settings.local.json | Profile 系统、Trust 机制、沙盒模式 |

两个工具**功能定位高度相似**，核心差异在于配置格式、安全机制和部分独有功能。

---

## 2. 统一概念词映射表

用户通常先有一个"我要做 X"的需求，再去找对应配置方式。

| 你脑子里的概念 | 统一含义 | Claude Code 对应 | Codex 对应 |
|---|---|---|---|
| **Instructions** | 给 AI 的持久化背景知识和行为指令 | `CLAUDE.md` | `AGENTS.md` |
| **Rule** | 控制 AI 能用哪些工具、能做什么操作 | `settings.json` → `permissions` | `config.toml` → `approval_policy` + `.rules` |
| **Hook** | 特定事件发生时自动触发的脚本 | `settings.json` → `hooks` | `hooks.json` 或 `config.toml` → `[hooks]` |
| **Skill** | 教会 AI 一种可复用的工作方法（AI 自动发现） | `.agents/skills/*/SKILL.md` | `.agents/skills/*/SKILL.md`（同格式） |
| **Command** | 用户主动召唤的快捷指令（`/xxx` 触发） | `.claude/commands/*.md` | ❌ 无直接对应（用 Skill/Agent 替代） |
| **Plugin** | 将 Skill/MCP/Agent 打包分发的容器 | `settings.json` → `enabledPlugins` | `codex marketplace add <repo>` |
| **MCP** | 给 AI 接上外部工具/数据库/服务 | `~/.claude.json` / `.mcp.json` | `config.toml` → `[mcp_servers]` |
| **Agent/Subagent** | 有专属角色和限制的 AI 子实例 | `.claude/agents/*.md`（Markdown） | `.codex/agents/*.toml`（TOML） |
| **Profile** | 一套可快速切换的配置预设 | ❌ 无原生支持（用 CLI 标志替代） | `config.toml` → `[profiles.xxx]` |
| **Memory** | AI 跨会话记住的内容 | ✅ 原生支持，自动写入 `CLAUDE.md` | ❌ 无原生支持（靠 `AGENTS.md` 手动维护） |

---

## 3. 关键分工：Instructions 文件 vs 配置文件

> **最常见的新手困惑**：CLAUDE.md 和 settings.json 都能"配置 AI 行为"，有什么区别？

| | CLAUDE.md / AGENTS.md | settings.json / config.toml |
|---|---|---|
| **本质** | 给 AI 读的"上下文" | 控制工具本身的"行为边界" |
| **写什么** | 项目架构、编码规范、技术栈、常用命令、业务背景 | 权限规则、模型选择、MCP 连接、Hooks 配置 |
| **谁读** | AI 模型（注入到上下文） | 工具本身（在 AI 调用前处理） |
| **格式** | 普通 Markdown | JSON（Claude Code）/ TOML（Codex） |

**一句话总结：**
- `CLAUDE.md` / `AGENTS.md` = 告诉 AI **应该知道什么**
- `settings.json` / `config.toml` = 告诉工具 **可以做什么**

---

## 4. 作用域层级模型

### Claude Code 文件树

```
# 第1层：企业管理员（最高权限，用户无法覆盖）
managed-settings.json        # IT 强制策略
managed-mcp.json             # 强制 MCP 配置

# 第2层：用户全局（影响所有项目）
~/.claude/
├── settings.json            # 全局行为配置
├── CLAUDE.md                # 全局 AI 指令
├── commands/                # 全局自定义命令
│   └── security.md
└── agents/                  # 全局 Agent
~/.claude.json               # 全局 MCP（注意：在 ~/.claude/ 外面！）

# 第3层：项目（仅当前 repo）
.claude/
├── settings.json            # 项目行为配置（提交 git）
├── settings.local.json      # 个人本地覆盖（加入 .gitignore）
├── commands/                # 项目自定义命令
└── agents/                  # 项目 Agent
CLAUDE.md                    # 项目 AI 指令（提交 git）
.mcp.json                    # 项目 MCP（提交 git）

# 第4层：子目录（精细化控制）
src/CLAUDE.md                # 仅对 src/ 目录生效
```

### Codex 文件树

```
# 第1层：组织管理员
requirements.toml            # 强制约束（如禁止 approval_policy = "never"）

# 第2层：用户全局
~/.codex/
├── config.toml              # 全局配置
├── AGENTS.md                # 全局 AI 指令
├── agents/                  # 全局 Agent
│   └── reviewer.toml
└── hooks.json               # 全局 Hooks

# 第3层：项目（⚠ 需要信任才加载！）
.codex/
├── config.toml              # 项目配置（提交 git）
├── hooks.json               # 项目 Hooks（提交 git）
└── agents/                  # 项目 Agent
AGENTS.md                    # 项目 AI 指令（提交 git）
AGENTS.override.md           # 最高优先指令（可选）

# 第4层：子目录
src/AGENTS.md                # 仅对 src/ 目录生效
```

### ⚠ Codex Trust 机制（踩坑高发区）

Codex 的项目级配置（`.codex/` 目录）**默认不生效**，必须显式信任才加载。

**为什么？** `.codex/config.toml` 可能来自陌生仓库，防止恶意 Hook 或危险的 `approval_policy = "never"` 自动生效。

**怎么信任？** 在项目目录启动 Codex 时，确认信任提示。或在 `config.toml` 中设 `trust = "trusted"`。

**Claude Code 没有此机制**，项目配置始终自动加载。

---

## 5. 优先级规则

### Claude Code（高→低）

1. **管理员策略**（managed-settings.json）— 用户无法覆盖
2. **本地覆盖**（.claude/settings.local.json）— 不提交 git
3. **项目配置**（.claude/settings.json）— 团队共享
4. **用户全局**（~/.claude/settings.json）— 个人默认
5. **内置默认值**

> ⚡ **权限数组合并（重要）**：`permissions.allow/deny` 数组在所有层之间是**合并**而非覆盖。全局允许 `git status`，项目允许 `npm lint`，两者同时有效。

### Codex（高→低）

1. **CLI 标志**（`-c key=value` / `--profile`）— 单次运行
2. **Profile 选中值**（config.toml `[profiles.xxx]`）
3. **项目配置**（.codex/config.toml）— 仅信任项目有效
4. **用户全局**（~/.codex/config.toml）
5. **内置默认值**

> ⚡ **同级先找到者优先**：同一层内，先匹配到的配置生效，不做合并。与 Claude Code 不同。

### Instructions 文件叠加行为

CLAUDE.md / AGENTS.md **全部读取并叠加**（不是覆盖）：

- Claude Code：`~/.claude/CLAUDE.md` → 项目根 `CLAUDE.md` → 子目录 `CLAUDE.md`
- Codex：优先读 `AGENTS.override.md` → `AGENTS.md` → 子目录，**合计不超过 32KB**

---

## 6. 能力详解

### 6.1 Instructions

#### Claude Code — CLAUDE.md 完整模板

```markdown
# 项目名称：MyApp

## 项目概述
MyApp 是一个 TypeScript + React 全栈应用，
后端使用 Node.js + Express，数据库为 PostgreSQL。

## 技术栈
- 前端：React 18, TypeScript, Tailwind CSS
- 后端：Node.js 20, Express, Prisma ORM
- 数据库：PostgreSQL 15
- 测试：Jest + React Testing Library

## 目录结构
packages/
├── ui/          # React 前端
├── api/         # Node.js 后端
└── shared/      # 共享类型定义

## 常用命令
- `npm test`           — 运行全部测试
- `npm run lint`       — ESLint 检查
- `npm run build`      — 生产构建
- `npm run dev`        — 启动开发服务器
- `npm run db:migrate` — 执行数据库迁移

## 编码规范
- 使用 TypeScript 严格模式，禁止 `any`
- 所有公共函数必须有 JSDoc 注释
- 新功能必须附带单元测试
- 禁止默认导出（使用命名导出）
- API 端点使用 Zod 做请求/响应校验

## 架构约定
- API 路由放在 packages/api/src/routes/
- React 组件放在 packages/ui/src/components/
- 禁止在组件中直接调用 fetch，统一通过 React Query

## AI 行为偏好
- 修改前先解释你的思路
- 代码注释使用中文
- 遇到不确定的需求，先问清楚再动手
```

#### Codex — AGENTS.md 完整模板

```markdown
# MyApp — Codex 项目指南
## 最重要的内容放最前面（防截断，32KB 限制）

## 关键约束（必须遵守）
- 不要直接推送到 main 分支
- 数据库迁移必须经过人工审查
- 生产环境变量永远不要写入代码

## 项目技术栈
TypeScript + React 前端，Node.js + Express 后端，PostgreSQL 数据库。

## 常用命令
- `npm test`           — 运行测试
- `npm run lint:fix`   — 自动修复 lint
- `npm run db:migrate` — 执行迁移

## 编码规范
- TypeScript 严格模式
- 使用命名导出
- API 层用 Zod 校验
```

---

### 6.2 Rule

Rule 控制"AI 被允许做什么操作"，是工具本身的执行策略，不是 AI 读的知识。

**Rule vs Hook 的区别：**
- **Rule（permissions）**：静态声明，在工具启动前确定"能做什么"
- **Hook**：动态响应，特定事件发生时执行脚本

#### Claude Code — settings.json permissions 模板

```json
// .claude/settings.json
{
  "permissions": {
    "allow": [
      // Git 操作：允许常用命令，无需确认
      "Bash(git status:*)",
      "Bash(git add:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git branch:*)",
      "Bash(git checkout:*)",

      // 包管理
      "Bash(npm install:*)",
      "Bash(npm run:*)",
      "Bash(npm test:*)",

      // 文件读写
      "Read",
      "Write",
      "Edit"
    ],
    "deny": [
      // 严格禁止危险操作
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(curl * | bash:*)",

      // 禁止直接推送 main
      "Bash(git push * main:*)"
    ],
    "ask": [
      // 每次询问：commit 和 push 需要人工确认
      "Bash(git commit:*)",
      "Bash(git push:*)"
    ]
  }
}
```

#### Codex — config.toml 权限模板

```toml
# .codex/config.toml

# 审批策略：每次询问（推荐团队项目）
approval_policy = "on-request"

# 沙盒模式：只允许写工作目录
sandbox_mode = "workspace-write"

# CI 环境 Profile（全自动）
[profiles.ci]
approval_policy = "never"
sandbox_mode    = "workspace-write"

# 安全审查 Profile（只读）
[profiles.audit]
approval_policy = "untrusted"
sandbox_mode    = "read-only"
```

---

### 6.3 Hook

Hook 是"当某件事发生时，自动执行某段脚本"。

| 事件 | Claude Code | Codex |
|---|---|---|
| 工具调用前 | `PreToolUse` | `PreToolUse` |
| 工具调用后 | `PostToolUse` | `PostToolUse` |
| AI 完成响应 | `Stop` | — |
| 会话结束 | `SessionEnd` | — |
| 通知 | `Notification` | — |

#### Claude Code — hooks 模板

```json
// .claude/settings.json
{
  "hooks": {
    "PreToolUse": [
      {
        // bash 命令执行前，运行安全检查
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": ".claude/hooks/pre_bash_check.sh",
          "timeout": 10
        }]
      }
    ],
    "PostToolUse": [
      {
        // 写文件后自动 lint
        "matcher": "Write",
        "hooks": [{
          "type": "command",
          "command": "npm run lint --silent",
          "timeout": 30
        }]
      }
    ],
    "Stop": [
      {
        // 任务完成后发桌面通知（macOS）
        "hooks": [{
          "type": "command",
          "command": "osascript -e 'display notification \"任务完成\" with title \"Claude Code\"'"
        }]
      }
    ]
  }
}
```

#### Codex — hooks.json 模板

```json
// .codex/hooks.json
{
  "PreToolUse": [
    {
      "matcher": "^Bash$",
      "hooks": [{
        "type": "command",
        "command": ".codex/hooks/pre_tool_check.py",
        "timeout": 15,
        "statusMessage": "正在检查命令安全性..."
      }]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "^Write$",
      "hooks": [{
        "type": "command",
        "command": "npm run lint --silent",
        "timeout": 30
      }]
    }
  ]
}
```

---

### 6.4 Skill

Skill 是"教会 AI 一种工作方法"的能力包，AI 根据任务**自动发现并调用**。

**Skill vs Command 的核心区别：**
- **Skill**：AI 主动发现，自然语言触发，适合"教 AI 怎么做某类工作"
- **Command**：用户主动召唤（`/commandname`），适合"我要触发一个固定操作"

#### 发现路径（两工具格式相同）

```
.agents/skills/           ← 当前目录（最高优先）
../.agents/skills/        ← 父目录
$REPO_ROOT/.agents/skills/← 仓库根
~/.agents/skills/         ← 用户全局
/etc/codex/skills/        ← 系统级（Codex 专有）
内置 Skill
```

#### SKILL.md 完整模板（两工具通用）

```markdown
---
name: api-scaffold
description: >
  当用户要求创建新的 API 端点时，按照项目规范
  自动生成路由、Controller、Zod schema 和测试文件。
  触发词：create endpoint、新增接口、添加路由。
---

# API 脚手架 Skill

## 使用场景
用户请求创建新的 REST API 端点时自动激活。

## 执行步骤

### 1. 理解需求
- 确认端点路径（如 `/api/users/:id`）
- 确认 HTTP 方法（GET/POST/PUT/DELETE）
- 确认请求/响应数据结构

### 2. 生成文件

**路由文件**（packages/api/src/routes/）：
```typescript
import { Router } from 'express';
const router = Router();
router.get('/xxx', handler);
export default router;
```

**Zod Schema**（packages/api/src/schemas/）：
```typescript
import { z } from 'zod';
export const XxxRequestSchema = z.object({
  // 根据需求填写
});
```

### 3. 验证
生成后运行 `npm run lint` 和 `npm test` 确认无报错。
```

---

### 6.5 Command

Command 是 Claude Code 独有功能，用 `/commandname` 触发。

**存放位置：**
- 项目级：`.claude/commands/*.md`（提交 git，团队共享）
- 全局级：`~/.claude/commands/*.md`（个人专用）

#### 规范 commit message 命令

```markdown
<!-- .claude/commands/commit.md -->
---
description: "生成规范的 Git commit message（遵循 Conventional Commits）"
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*)
argument-hint: "[可选：额外说明]"
model: claude-sonnet-4-6
---

## 当前状态
- 当前分支：!`git branch --show-current`
- 改动文件：!`git status --short`
- 详细 diff：!`git diff HEAD`

## 任务
根据以上改动，生成符合 Conventional Commits 规范的 commit message：
- 格式：`type(scope): description`
- type：feat / fix / docs / style / refactor / test / chore
- description 使用中文，简洁明了
- 额外说明：$ARGUMENTS

生成后询问确认，确认后执行 `git commit`。
```

#### 代码审查命令

```markdown
<!-- .claude/commands/review.md -->
---
description: "对当前改动进行代码审查"
allowed-tools: Read, Bash(git diff:*)
model: claude-opus-4-6
---

请对以下改动进行代码审查：

**改动内容：**
!`git diff HEAD`

**审查重点：**
1. 安全漏洞（SQL 注入、XSS）
2. 性能问题（N+1 查询）
3. 错误处理完整性
4. 是否符合项目规范

按严重程度（🔴 高 / 🟡 中 / 🟢 低）列出问题。
```

---

### 6.6 Plugin

Plugin 将 Skill、MCP、Agent、Hook 打包在一起分发。

| | Claude Code | Codex |
|---|---|---|
| **安装方式** | `settings.json` → `enabledPlugins` | `codex marketplace add <git-repo>` |
| **可打包内容** | Skills + MCP | Skills + MCP + Agents + Hooks |
| **安装策略** | 基础 | INSTALLED_BY_DEFAULT / AVAILABLE / INSTALLED |
| **成熟度** | 基础，发展中 | 较完整 |

#### Codex Plugin manifest 模板

```json
// plugin.json
{
  "name": "my-team-toolkit",
  "version": "1.0.0",
  "description": "团队工具包：API 脚手架、代码审查、MCP 配置",
  "components": {
    "skills": [
      "skills/api-scaffold",
      "skills/code-review"
    ],
    "mcp_servers": [
      "mcp/github-server.json"
    ],
    "agents": [
      "agents/security-reviewer.toml"
    ]
  },
  "install_policy": "AVAILABLE"
}
```

---

### 6.7 MCP

MCP（Model Context Protocol）是 AI 接入外部服务的标准协议。

> ⚠ **Claude Code 踩坑**：用户级 MCP 文件是 `~/.claude.json`，**不是** `~/.claude/mcp.json`，位置特殊。

#### Claude Code — .mcp.json 模板

```json
// .mcp.json（项目根，提交 git）
{
  "mcpServers": {
    // GitHub MCP
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    // PostgreSQL MCP
    "database": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        // 用环境变量，不要硬编码密码
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

#### Codex — config.toml MCP 配置

```toml
# .codex/config.toml

[mcp_servers.github]
command = "npx"
args    = ["-y", "@github/mcp-server"]
env     = { GITHUB_TOKEN = "env:GITHUB_TOKEN" }
# env:GITHUB_TOKEN 表示从环境变量读取

[mcp_servers.database]
command      = "npx"
args         = ["-y", "@modelcontextprotocol/server-postgres"]
env          = { DATABASE_URL = "env:DATABASE_URL" }
timeout_secs = 30
```

---

### 6.8 Agent / Subagent

Agent 是有专属角色、工具权限和指令的子 AI 实例。

| | Claude Code | Codex |
|---|---|---|
| **文件格式** | Markdown | TOML |
| **项目路径** | `.claude/agents/*.md` | `.codex/agents/*.toml` |
| **全局路径** | `~/.claude/agents/*.md` | `~/.codex/agents/*.toml` |
| **内置角色** | 无 | default / worker / explorer |

#### Codex — Agent TOML 模板

```toml
# .codex/agents/security-reviewer.toml

# 基本信息
name        = "security-reviewer"
description = "专注安全漏洞审查，只读模式"

# AI 行为指令
developer_instructions = """
你是资深安全工程师，专注代码安全审查。
审查范围：SQL 注入、XSS、CSRF、敏感数据暴露、不安全依赖。
输出格式：按严重程度（高/中/低）列出问题，附文件行号和修复建议。
"""

# 使用更强的模型做安全审查
model                  = "gpt-5.4"
model_reasoning_effort = "high"

# 只读沙盒：不允许修改任何文件
sandbox_mode = "read-only"

# 可选昵称
nickname_candidates = ["SecBot", "Guardian"]
```

---

### 6.9 Profile

> **Codex 独有功能**，Claude Code 没有原生对应。

Profile 是一套命名的配置预设，用于快速切换工作场景。

#### Codex — Profile 完整模板

```toml
# ~/.codex/config.toml

# 默认使用 dev profile
profile = "dev"

# 日常开发
[profiles.dev]
model                  = "gpt-5.3-codex"
approval_policy        = "on-request"
sandbox_mode           = "workspace-write"
model_reasoning_effort = "medium"

# CI/CD 自动化（全自动，不交互）
[profiles.ci]
approval_policy        = "never"
sandbox_mode           = "workspace-write"
model_reasoning_effort = "low"
model_verbosity        = "low"

# 深度调试（强推理）
[profiles.debug]
model                  = "gpt-5.4"
approval_policy        = "on-request"
model_reasoning_effort = "high"
model_verbosity        = "high"

# 安全审查（只读）
[profiles.audit]
approval_policy = "untrusted"
sandbox_mode    = "read-only"
```

```bash
# 使用方式
codex --profile ci "运行所有测试"
codex --profile debug "分析这个并发问题"
codex --profile audit "检查安全漏洞"
```

**Claude Code 替代方案：**
```bash
# 用 CLI 标志临时覆盖（不如 Profile 方便）
claude --model claude-opus-4-6 "复杂任务"
claude --system-prompt "你是安全专家..." "审查代码"
```

---

### 6.10 Memory

> **Claude Code 独有功能**，Codex 没有原生对应。

Claude Code 可以将会话中学到的信息自动写入 CLAUDE.md，实现跨会话持久化。

```markdown
<!-- CLAUDE.md — 记忆管理示例 -->

## 用户偏好（Claude 自动写入）

### 代码风格
- 变量命名使用 camelCase
- 注释使用中文
- 函数体超过 20 行必须拆分

### 工作流偏好
- 修改前先说明方案，等确认再动手
- 每次 commit 前运行测试

### 已知的项目特殊情况
- legacy/ 目录下的代码只读，不要改
- 数据库迁移必须手动执行
```

---

## 7. 配置模板

### Claude Code — 全局配置

```json
// ~/.claude/settings.json — 完整全局配置模板
{
  // ── 模型设置 ──────────────────────────────────
  "model": "claude-sonnet-4-6",
  // 可选：claude-opus-4-6（更强）claude-haiku-4-5（更快）

  // ── 权限控制 ───────────────────────────────────
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git add:*)",
      "Bash(git branch:*)",
      "Bash(git checkout:*)",
      "Bash(npm install:*)",
      "Bash(npm run:*)",
      "Bash(npm test:*)",
      "Bash(npx:*)",
      "Read",
      "Write",
      "Edit"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(curl * | bash:*)"
    ],
    "ask": [
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(git merge:*)"
    ]
  },

  // ── Hooks ──────────────────────────────────────
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        // 任务完成后发桌面通知（macOS）
        "command": "osascript -e 'display notification \"任务完成\" with title \"Claude Code\"'"
      }]
    }]
  },

  // ── 环境变量 ───────────────────────────────────
  "env": {
    "CLAUDE_CODE_DISABLE_TELEMETRY": "1"
  }
}
```

### Claude Code — 项目配置

```json
// .claude/settings.json — 团队项目配置
{
  "model": "claude-sonnet-4-6",

  "permissions": {
    "allow": [
      "Bash(npm run test:*)",
      "Bash(npm run lint:*)",
      "Bash(npm run build:*)"
    ],
    "deny": [
      "Bash(git push * main:*)",
      "Bash(git push --force:*)",
      "Write(config/prod.*)"
    ]
  },

  "hooks": {
    "PostToolUse": [{
      "matcher": "Write",
      "hooks": [{
        "type": "command",
        "command": "npm run lint --silent 2>&1 | head -20",
        "timeout": 30
      }]
    }]
  }
}
```

```json
// .claude/settings.local.json — 个人覆盖（加入 .gitignore）
{
  // 个人使用更强的模型
  "model": "claude-opus-4-6",

  "permissions": {
    "allow": [
      // 个人允许自动 commit
      "Bash(git commit:*)"
    ]
  }
}
```

### Codex — 全局配置

```toml
# ~/.codex/config.toml — 完整全局配置模板

# ── 基础设置 ────────────────────────────────────
model                  = "gpt-5.3-codex"
model_reasoning_effort = "medium"  # high / medium / low
model_verbosity        = "medium"  # high / medium / low

# ── 安全设置 ────────────────────────────────────
approval_policy = "on-request"    # on-request / never / untrusted
sandbox_mode    = "workspace-write"

# ── 网络搜索 ────────────────────────────────────
web_search = "cached"             # cached / live / disabled

# ── 默认 Profile ─────────────────────────────────
profile = "dev"

# ── Profile 定义 ─────────────────────────────────
[profiles.dev]
approval_policy        = "on-request"
sandbox_mode           = "workspace-write"
model_reasoning_effort = "medium"

[profiles.ci]
approval_policy        = "never"
sandbox_mode           = "workspace-write"
model_reasoning_effort = "low"
model_verbosity        = "low"

[profiles.debug]
model                  = "gpt-5.4"
approval_policy        = "on-request"
model_reasoning_effort = "high"
model_verbosity        = "high"

[profiles.audit]
approval_policy = "untrusted"
sandbox_mode    = "read-only"

# ── 功能开关 ─────────────────────────────────────
[features]
multi_agent    = true   # 启用多 Agent 并行
shell_tool     = true   # 启用 shell 工具
shell_snapshot = true   # 加速重复命令

# ── 全局 MCP ──────────────────────────────────────
[mcp_servers.github]
command = "npx"
args    = ["-y", "@github/mcp-server"]
env     = { GITHUB_TOKEN = "env:GITHUB_TOKEN" }
```

### Codex — 项目配置

```toml
# .codex/config.toml — 团队项目配置

# ── 基础设置 ─────────────────────────────────────
model           = "gpt-5.3-codex"
approval_policy = "on-request"
sandbox_mode    = "workspace-write"

# ── 文档设置 ─────────────────────────────────────
project_doc_max_bytes          = 32768  # 32KB 默认值
project_doc_fallback_filenames = ["TEAM_GUIDE.md"]

# ── 项目 MCP ──────────────────────────────────────
[mcp_servers.jira]
command      = "npx"
args         = ["-y", "@modelcontextprotocol/jira-server"]
env          = { JIRA_URL = "env:JIRA_URL", JIRA_TOKEN = "env:JIRA_TOKEN" }
timeout_secs = 30

# ── Agent 并发控制 ───────────────────────────────
[agents]
max_threads             = 4    # 最多 4 个并发 Agent
max_depth               = 1    # 最多 1 层嵌套
job_max_runtime_seconds = 300  # 每个 Agent 最长 5 分钟
```

---

## 8. 决策工具

### 决策1：我要配置什么能力？

```
我想做的事                                    → 用什么
─────────────────────────────────────────────────────────
给 AI 注入项目背景/规范/约定                  → Instructions（CLAUDE.md / AGENTS.md）
控制 AI 能执行哪些命令                         → Rule（permissions / approval_policy）
某件事发生时自动执行脚本                       → Hook（hooks / hooks.json）
教会 AI 一种固定工作方法（AI 自动选用）        → Skill（.agents/skills/*/SKILL.md）
我要主动触发一个固定操作（/xxx 召唤）          → Command（Claude Code 专有）
接入外部服务（GitHub/数据库/Slack）            → MCP
创建有专属角色和限制的 AI 助手                 → Agent
快速切换工作场景（开发/CI/审查）               → Profile（Codex 专有）
打包分发上述所有配置给团队                     → Plugin
```

### 决策2：这个配置放哪一层？

```
影响范围                              → 放哪里
─────────────────────────────────────────────────
我所有项目都要用（个人偏好）           → 用户全局层（~/.claude/ 或 ~/.codex/）
团队共享，提交 git                    → 项目层（.claude/ 或 .codex/）
个人覆盖，不提交 git                   → .claude/settings.local.json 或 -c 标志
只在这次运行生效                       → CLI 标志（claude --model 或 codex -c）
```

### 决策3：Rule 还是 Hook？

```
场景                                   → 用什么
─────────────────────────────────────────────────
"某类操作永远不允许"（静态边界）        → Rule（permissions.deny）
某事件发生时，额外执行脚本             → Hook（PreToolUse/PostToolUse）
动态检查命令内容后决定是否允许         → Hook（PreToolUse + 检查脚本）
写文件后自动跑测试                     → Hook（PostToolUse，matcher: "Write"）
```

### 决策4：Skill 还是 Command？

```
场景                                   → 用什么
─────────────────────────────────────────────────
AI 在合适时机自动用到这个方法          → Skill
我要在特定时刻主动 /xxx 触发           → Command（Claude Code）或 codex exec（Codex）
需要动态获取 git 状态等上下文          → Command（支持 !`shell命令`）
要打包给其他团队用                     → Skill → Plugin
```

---

## 9. 排错指南

### 问题1：Codex 项目配置没生效

**原因**：项目未被信任，`.codex/` 被跳过。
**解决**：启动 Codex 时确认信任提示，或检查是否误配置了 `trust = "untrusted"`。

### 问题2：Claude Code MCP 连接失败

**常见原因**：
1. 路径错误：用户级 MCP 是 `~/.claude.json`，不是 `~/.claude/mcp.json`
2. 格式错误：字段名是 `mcpServers`（camelCase），不是 `mcp_servers`
3. 环境变量未设置

### 问题3：AI 不遵守项目规范

**排查**：
1. 确认 CLAUDE.md 在项目根目录（不是 `.claude/` 里）
2. Codex：检查文件是否超过 32KB，超出内容被截断
3. 规范写得太模糊，改用具体可执行的描述

### 问题4：Hook 没有被触发

**排查清单**：
- Codex：项目是否已信任？
- `matcher` 大小写是否正确（区分大小写）？
- 脚本是否有执行权限？（`chmod +x xxx.sh`）
- Codex：`hooks.json` 和 `[hooks]` 表只能二选一

### 问题5：Skill 没有被 AI 自动调用

**原因**：`description` 字段太模糊，AI 不知道在什么场景使用。
**解决**：在 description 里加入具体的触发词和使用场景。

### 问题6：AGENTS.md 内容被截断（Codex）

**原因**：所有层 AGENTS.md 合计超过 32KB。
**解决**：最重要内容放最前面；详细参考资料移到 Skill 文件中。

### 问题7：敏感信息泄露

**绝对禁止**：把 API Key 写死在配置文件里，特别是提交 git 的文件。

```bash
# 正确做法：在 shell profile 里设置环境变量
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# Claude Code .mcp.json 引用
"GITHUB_TOKEN": "${GITHUB_TOKEN}"

# Codex config.toml 引用
env = { GITHUB_TOKEN = "env:GITHUB_TOKEN" }
```

### 问题8：团队成员配置行为不一致

**排查**：
- 各人全局配置是否不同，覆盖了项目配置？
- Codex：每个人是否都信任了项目？
- `settings.local.json` 是否被误提交 git？

**预防**：
- `.gitignore` 加入 `.claude/settings.local.json`
- README 写明：clone 后的初始化步骤（含 Codex 信任确认）

---

## 10. 管理员视角

### 个人开发者作为自己的"管理员"

设置全局默认值，让所有项目继承：

```bash
# Claude Code：编辑全局配置
~/.claude/settings.json    ← 全局权限和行为
~/.claude/CLAUDE.md        ← 跨项目通用指令（如个人编码风格）
~/.claude.json             ← 全局 MCP 服务器

# Codex：编辑全局配置
~/.codex/config.toml       ← 全局设置 + Profile 定义
~/.codex/AGENTS.md         ← 跨项目通用指令
```

### Tech Lead（设置团队项目规范）

```
项目里提交 git 的文件：
├── CLAUDE.md / AGENTS.md     ← 团队约定的 AI 指令
├── .claude/settings.json     ← 团队权限规则
├── .codex/config.toml        ← 团队 Codex 配置
├── .claude/commands/         ← 团队共享命令
├── .agents/skills/           ← 团队共享 Skill
└── .mcp.json / config.toml   ← 团队 MCP 服务器

不提交 git 的文件（加入 .gitignore）：
└── .claude/settings.local.json  ← 个人覆盖
```

**团队 README 中应包含的内容：**
```markdown
## AI 工具初始化

### Claude Code 用户
1. 安装：`npm install -g @anthropic-ai/claude-code`
2. 配置 API Key：`export ANTHROPIC_API_KEY="xxx"`
3. 设置环境变量：见 `.env.example`

### Codex 用户  
1. 安装：`npm install -g @openai/codex`
2. 配置 API Key：`export OPENAI_API_KEY="xxx"`
3. **信任项目**：首次运行时确认信任提示（必须，否则项目配置不生效）
4. 设置环境变量：见 `.env.example`
```

---

*最后更新：2026 年 5 月*
*工具版本：Claude Code v2.x，Codex CLI v0.130.x*
