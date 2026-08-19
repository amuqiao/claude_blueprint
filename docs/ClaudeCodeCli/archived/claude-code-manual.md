# Claude Code 多 Agent 使用手册

> 本手册聚焦 Claude Code CLI 的多 Agent 使用方式，回答两个问题：Claude 如何派发 Agent（运行模式），以及哪些角色可以被派发（Plugin 扩展）。

---

## 心智模型

使用 Claude Code 的多 Agent 能力，有三个正交维度：

```
运行模式（怎么跑）      ×      执行角色（谁来跑）      →      触发规则（什么时候跑）
  CLI 原生三种模式            Plugin 注入的专项角色            CLAUDE.md 工作流配置
```

**三个维度各自独立，可以自由组合：**

- **运行模式**：控制任务如何在 Claude 会话中运行——是在当前对话里派发子任务，还是独立后台跑，还是多个 Agent 协同
- **执行角色**：控制由哪种专项角色完成任务——语言专家、后端专家、安全审计员……Plugin 注入这些角色
- **触发规则**：控制何时、以哪种组合触发上述能力——由 `CLAUDE.md` 的工作流配置决定

---

## 一、两条路

扩展 Claude Code 多 Agent 能力有两条路，适合不同使用场景：

```
路线 A：Plugin 傻瓜方式
  安装 VoltAgent 插件包  →  获得一批预定义专项角色  →  直接在对话中点名调用
  优点：开箱即用，安装一次，所有项目可用

路线 B：CLI 原生方式
  自己写 .md 文件定义子代理  →  放入 ~/.claude/agents/  →  直接控制角色行为
  优点：完全自定义，精确控制工具权限、模型和描述
```

两条路可以混用。**Plugin 提供的角色和自定义子代理，都跑在 CLI 原生的三种运行模式上。**

---

## 二、CLI 原生运行模式

Claude Code CLI 内置三种 Agent 运行模式：

```
Subagent       在当前会话内派发子任务，隔离中间输出，只把摘要返回主线
Background     完全独立的后台会话，关闭终端仍持续运行
Agent Team     多会话成员间可直接通信协同（实验性）
```

### 2.1 Subagent（会话内子代理）

Subagent 在**独立上下文窗口**里工作，不污染主会话，只把结论摘要返回。适合需要大量中间步骤（代码搜索、日志分析）但你只关心结论的任务。

**触发方式：**

```bash
# 自然语言触发（Claude 自动判断是否派发子代理）
用 code-reviewer 审查 src/auth/ 目录

# 显式指定角色
Use the voltagent-qa-sec:architect-reviewer agent to review the API design
```

**内置子代理角色：**

| 角色 | 模型 | 工具权限 | 典型用途 |
|------|------|---------|---------|
| Explore | Haiku | 只读 | 快速搜索代码库 |
| Plan | 继承主会话 | 只读 | 规划前的信息收集 |
| general-purpose | 继承主会话 | 全部 | 复杂多步任务 |

**自定义子代理：**

```bash
mkdir -p ~/.claude/agents
cat > ~/.claude/agents/my-reviewer.md << 'EOF'
---
name: my-reviewer
description: 审查代码质量、安全性和最佳实践。代码变更后主动调用。
model: sonnet
tools: Read, Glob, Grep
---

你是一位资深代码审查员。针对每个问题给出：
当前代码 → 改进建议 → 改进后示例。
EOF
```

关键前置字段：

| 字段 | 作用 |
|------|------|
| `name` | 唯一标识，Claude 用此识别角色 |
| `description` | 何时自动派发——Claude 据此判断 |
| `model` | `haiku` 省钱 / `sonnet` 均衡 / `opus` 最强 |
| `tools` | 工具权限，只读场景用 `Read, Glob, Grep` |
| `isolation` | `worktree` = 独立 git 副本，避免并行冲突 |

管理界面：

```bash
/agents          # 打开管理界面（Running / Library 两个标签）
```

---

### 2.2 Background Agent（后台独立会话）

后台 Agent 是**完全独立的 Claude Code 会话**，关闭终端后仍持续运行。`claude agents` 打开 Agent View 统一查看所有后台任务。

**启动方式：**

```bash
# 基本用法
claude --bg "分析 src/ 下所有 TypeScript 类型错误并生成报告"

# 指定角色（VoltAgent 插件角色或自定义子代理均可）
claude --agent voltagent-qa-sec:security-auditor \
       --bg "审查 PR #42 的所有变更，重点关注安全问题"

# 命名会话（便于在 Agent View 识别）
claude --bg --name "auth-refactor" \
       "重构 src/auth/ 模块，提取公共逻辑，补全单元测试"
```

**并行启动多任务：**

```bash
claude --bg --name "fix-login"   "修复 issue#234 登录超时，运行相关测试确认"
claude --bg --name "update-deps" "升级所有 npm 依赖到最新稳定版，确保测试通过"
claude --bg --name "api-docs"    "为 src/api/ 所有路由生成 OpenAPI 注释"

claude agents   # 统一查看进度
```

**Agent View 操作：**

| 快捷键 | 操作 |
|--------|------|
| `Space` | 预览面板（查看最新输出 / 回复） |
| `Enter` / `→` | 进入完整会话 |
| `←`（空提示时） | 退出当前会话，返回列表 |
| `/bg`（会话内） | 将当前会话转为后台 |

**状态图标：**

```
✽ 动画  Working    ●  黄色  Needs input
∙ 暗色  Idle       ✓  绿色  Completed    ✗  红色  Failed
```

---

### 2.3 Agent Team（多代理团队，实验性）

> ⚠️ 默认关闭，已知存在 session 恢复、任务协调等 bug，需要 v2.1.32+。

与 Subagent 的关键区别：

```
Subagent：主代理统一调度，子代理只汇报结果，互相不可见

Agent Team：成员间可直接通信、共享任务列表、自主认领
  Lead ←→ Teammate A
  Lead ←→ Teammate B
  Teammate A ←→ Teammate B   ← Subagent 做不到这点
```

**开启：**

```json
// ~/.claude/settings.json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

**适合场景：**

- 多角度研究同一问题（UX / 技术 / 风险各一个成员，互相挑战）
- 跨层并行开发（frontend / backend / test 各自独立推进）
- 并行验证多个假设

**基本用法：**

```bash
# 在 Claude 对话中直接描述
创建一个 agent team：一个负责前端重构，一个负责后端 API 改造，
一个负责补全测试，完成后汇总。

# 清理（必须让 Lead 执行）
让 Lead 关闭所有成员并清理资源
```

---

### 2.4 选择哪种模式

```
任务量小，当前对话就能处理
└─ 直接对话，不需要 Agent

需要隔离中间输出（大量搜索 / 分析 / 文件读取）
└─ Subagent（不污染主线上下文，结论摘要返回）

需要并行 + 去做别的事
└─ Background Agent（后台运行，Agent View 统一查看进度）

需要多方互相讨论 / 挑战 / 协调
└─ Agent Team（实验性，谨慎用于生产）
```

---

## 三、Plugin 扩展：角色层

Plugin 向 Claude 注入**专项执行角色**，回答的是"谁来跑"这个问题。CLI 原生模式解决的是"怎么跑"。两者正交，可自由组合。

### 3.1 安装 VoltAgent 插件

```bash
# 第一步：注册商店目录
/plugin marketplace add VoltAgent/awesome-claude-code-subagents

# 第二步：安装三个插件包
/plugin install voltagent-core-dev@voltagent-subagents    # 功能职责角色
/plugin install voltagent-lang@voltagent-subagents         # 语言专项角色
/plugin install voltagent-qa-sec@voltagent-subagents       # 质量与安全角色

# 第三步：激活
/reload-plugins
```

### 3.2 可用角色一览

```
voltagent-core-dev:*          功能职责角色
├── frontend-developer        前端开发
├── backend-developer         后端开发
├── fullstack-developer       全栈开发
├── api-designer              API 设计
└── ui-designer               UI 设计

voltagent-lang:*              语言专项角色
├── typescript-pro            TypeScript / Node.js
├── react-specialist          React
├── python-pro                Python
└── rust-engineer             Rust

voltagent-qa-sec:*            质量与安全角色
├── code-reviewer             代码质量评审
├── security-auditor          安全审计
├── performance-engineer      性能分析
└── architect-reviewer        架构评审
```

### 3.3 Plugin 日常管理

```bash
# Marketplace
/plugin marketplace list                    # 查看已添加的商店
/plugin marketplace update <name>           # 更新商店目录
/plugin marketplace remove <name>           # 移除商店

# Plugin
/plugin                                     # 打开图形管理界面
/plugin install <name>@<marketplace>        # 安装
/plugin enable  <name>                      # 启用
/plugin disable <name>                      # 禁用
claude plugin uninstall <name>              # 卸载（CLI 方式，TUI 有已知 bug）
claude plugin uninstall <name> --prune      # 卸载并清理依赖（需 v2.1.121+）
```

**安装作用域：**

| 作用域 | 参数 | 生效范围 |
|--------|------|---------|
| 用户级（默认） | `--scope user` | 你的所有项目 |
| 项目级 | `--scope project` | 当前 repo，可提交团队共享 |
| 本地级 | `--scope local` | 当前 repo，仅本地生效 |

---

## 四、CLAUDE.md 工作流配置

CLAUDE.md 是写给 Claude 看的**会话级行为规则**，控制 Claude 何时、以哪种组合触发上面的 Agent 能力。每次启动时自动加载。

```
加载优先级（从高到低）
├── ~/.claude/CLAUDE.md          全局：对你所有项目生效
├── <project>/.claude/CLAUDE.md  项目级：当前项目生效
└── <project>/CLAUDE.md          项目根目录级
```

### 4.1 典型工作流规则

CLAUDE.md 可以定义代码任务的触发规则和执行路径：

```markdown
## Workflow Preference

代码任务开始前，必须先问用户选哪种工作流：

1. **plan → subagent → review → verify**
   - Plan：architect-reviewer 规划方案
   - Subagent：按技术栈派发专项角色执行（voltagent-lang:* / voltagent-core-dev:*）
   - Review：code-reviewer / security-auditor 并行评审
   - Verify：运行测试/构建/lint，必须有通过证据

2. **Just do it**
   - 直接执行，跳过完整流程
   - 完成后必须验证
```

### 4.2 决策结构

```
收到任务
   │
   ├─ 非代码任务（问答 / 读代码 / 运行命令）→ 直接执行
   │
   └─ 代码任务
       └─ 先选工作流
           ├─ Plan → Subagent → Review → Verify
           │   ├─ 按任务选合适的 Plugin 角色执行
           │   ├─ 并行多维度评审
           │   └─ 有通过证据才算完成
           └─ Just Do It → 执行 → 必须验证
```

---

## 附录：快速参考

```bash
# 查看 / 管理
/agents                                    # 子代理管理界面
claude agents                              # Agent View（查看后台任务）
claude agents --cwd ~/your-project        # 只看当前项目的后台任务

# 后台启动
claude --bg "任务描述"
claude --agent <role> --bg "任务描述"
claude --bg --name "session-name" "任务描述"

# Plugin
/plugin marketplace add VoltAgent/awesome-claude-code-subagents
/plugin install voltagent-core-dev@voltagent-subagents
/plugin install voltagent-lang@voltagent-subagents
/plugin install voltagent-qa-sec@voltagent-subagents
/reload-plugins
claude plugin uninstall <name>

# CLAUDE.md
mkdir -p ~/.claude && vim ~/.claude/CLAUDE.md

# 组合示例
# Subagent + Plugin 角色
Use voltagent-qa-sec:code-reviewer to review src/auth/

# Background + Plugin 角色
claude --agent voltagent-lang:python-pro --bg "重写 utils/parser.py，补全类型注解"
```
