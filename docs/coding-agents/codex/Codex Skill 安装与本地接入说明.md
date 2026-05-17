# Codex Skill 安装与本地接入说明

**文档职责**：说明如何在 Claude Code / Codex CLI 中安装、接入和使用 Skill，覆盖三个作用域层级与三类来源。  
**适用场景**：首次接入 Skill、团队统一接入规范、自定义 Skill 开发。  
**目标读者**：使用 Claude Code 或 Codex CLI 的开发者，包括个人开发者和团队管理员。  
**维护规范**：路径示例以 macOS/Linux 为主，Windows 路径见[附录](#附录路径速查)；内容随官方文档更新同步修订。

---

## 理解 Skill 的心智模型

在看具体操作之前，先建立整体认知。

**Skill 是什么：** 一个封装在 `SKILL.md` 文件里的指令包，给 AI Agent 提供专项知识或工作流。它和 `CLAUDE.md` 的根本区别是**加载时机**：

```
CLAUDE.md    → 每次会话启动时全量加载，始终占用上下文
Skill        → 按需加载，只有被触发时才进入上下文
```

这意味着你可以安装几十个 Skill，但 Claude 的上下文里只会出现当前任务需要的那几个。

**三个核心维度：**

```
来源维度        官方（Anthropic）→ 第三方市场 → 自定义
作用域维度      企业全局 → 用户级 → 项目级 → 插件级
安装方式维度    /plugin 命令 → npx 工具 → git clone → 手动文件
```

这三个维度相互独立、可以自由组合。比如你可以"用 git clone 安装一个第三方市场的 Skill，并部署在项目级作用域"。

---

## 作用域层级

作用域决定了 **Skill 对谁生效**，这是安装前最需要想清楚的问题。

```
优先级（高 → 低）

  企业全局（Enterprise）   ← 管理员统一下发，所有用户/所有项目
       ↓ 被覆盖
  用户级（Personal）       ← ~/.claude/skills/  所有项目可用
       ↓ 被覆盖
  项目级（Project）        ← .claude/skills/    仅当前仓库
       ↓ 命名空间隔离
  插件级（Plugin）         ← 插件内置，plugin-name:skill-name 命名，不参与覆盖
```

**覆盖规则：** 同名 Skill 在多个层级都存在时，高层级覆盖低层级。插件级 Skill 使用 `plugin-name:skill-name` 命名空间，不会与其他层级冲突。

| 层级 | 路径 | 适合放什么 |
|------|------|-----------|
| 企业全局 | 管理员 Managed Settings 下发 | 公司代码规范、安全检查、合规流程 |
| 用户级 | `~/.claude/skills/<skill-name>/` | 个人习惯性工作流，如 commit 模板、代码审查 |
| 项目级 | `.claude/skills/<skill-name>/` | 项目专属规范，随仓库版本控制共享给团队 |
| 插件级 | 插件目录内 `skills/` | 插件自带，随插件启用/禁用 |

---

## Skill 来源分类

来源决定了**信任程度**和**获取方式**，分三类。

### 官方 Skill（Anthropic 官方市场）

官方市场 `claude-plugins-official` 在 Claude Code 启动时自动注册，无需手动添加。

```bash
# 浏览官方插件（交互界面）
/plugin

# 直接安装官方插件（插件内含 Skill）
/plugin install github@claude-plugins-official
/plugin install figma@claude-plugins-official
/plugin install atlassian@claude-plugins-official
```

在线目录：[claude.com/plugins](https://claude.com/plugins)

官方市场包含三类内容：

- **代码智能插件**：接入 LSP，提供跳转定义、类型检查、错误实时反馈（pyright、rust-analyzer、typescript-language-server 等）
- **外部集成插件**：预配置好的 MCP Server（GitHub、Linear、Notion、Figma、Sentry 等）
- **工作流插件**：git commit 工作流、PR Review、插件开发工具包等

### 第三方市场 / 社区 Skill

来自 GitHub 或其他 Git 仓库的公开 Skill 集合，使用前建议 review 文件内容。

**添加市场源（两步流程：先注册市场，再安装插件）：**

```bash
# 添加 GitHub 仓库作为市场源（owner/repo 格式）
/plugin marketplace add anthropics/claude-code

# 添加其他 Git 地址
/plugin marketplace add https://gitlab.com/company/plugins.git

# 添加本地目录
/plugin marketplace add ./my-marketplace

# 查看已添加的市场源
/plugin   # → Marketplaces 标签页
```

常用社区资源：

| 资源 | 地址 | 说明 |
|------|------|------|
| Anthropic 官方示例库 | `anthropics/claude-code` | 演示用，含 commit-commands、pr-review-toolkit 等 |
| agentskills.io | [agentskills.io](https://agentskills.io) | 跨平台 Skill 开放标准与目录 |
| agensi.io | [agensi.io](https://www.agensi.io) | 付费/免费 Skill 商店，支持 ZIP 下载 |
| aitmpl.com/skills | [aitmpl.com/skills](https://www.aitmpl.com/skills) | 社区聚合目录 |

**通过 npx 批量安装社区 Skill：**

```bash
# 安装单个 Skill
npx skills add <github-user>/<repo> --skill <skill-name>

# 查看已安装列表
npx skills list
```

### 自定义 Skill

自己编写，完全掌控。核心是一个 `SKILL.md` 文件，可附带支撑文件。

创建流程见下一节「[安装方式 → 手动文件部署](#手动文件部署创建自定义-skill)」。

---

## 安装方式

### 手动文件部署（创建自定义 Skill）

这是最直接的方式，也是理解 Skill 工作原理的最佳入口。

**第一步：确定作用域，创建目录**

```bash
# 用户级（推荐用于个人工作流）
mkdir -p ~/.claude/skills/my-skill

# 项目级（推荐用于团队共享）
mkdir -p .claude/skills/my-skill
```

**第二步：创建 `SKILL.md`**

```markdown
---
description: 用一句话描述这个 Skill 的用途和触发时机，
             Claude 用这段描述判断何时自动加载。
---

## 主要指令

在这里写 Claude 应该执行的操作步骤。

## 动态上下文注入（可选）

当前 Git 状态：
!`git status --short`

## 支撑文件引用（可选）

详细规范见 [规范文档](./spec.md)。
```

`SKILL.md` 由两部分组成：

- **YAML frontmatter**（`---` 之间）：`description` 字段告诉 Claude 何时自动激活此 Skill
- **Markdown 正文**：Claude 执行 Skill 时遵循的指令内容

**第三步：可附带支撑文件**

```
my-skill/
├── SKILL.md          # 入口（必须）
├── spec.md           # 规范参考文档
├── examples/
│   └── sample.md     # 示例输出
└── scripts/
    └── validate.sh   # 可被 Claude 执行的脚本
```

### 通过 `/plugin` 市场安装

```bash
# 安装官方插件（默认安装到用户级）
/plugin install github@claude-plugins-official

# 安装社区市场插件（需先添加市场源）
/plugin marketplace add anthropics/claude-code
/plugin install commit-commands@anthropics-claude-code

# 选择安装作用域（交互界面）
/plugin   # → Discover → 选插件 → 选 User / Project / Local scope
```

安装作用域说明：

- **User scope**（默认）：安装给自己，所有项目可用
- **Project scope**：写入 `.claude/settings.json`，团队协作者共享
- **Local scope**：仅自己在当前仓库可用，不提交到版本控制

### 通过 npx 工具安装

```bash
# 安装单个 Skill
npx skills add <user>/<repo> --skill <skill-name>

# 安装到指定平台路径
npx agent-skills-cli add <user>/<repo> --agent codex

# 试运行（不实际安装）
npx agent-skills-cli add <user>/<repo> --dry-run
```

### Git Clone 安装

```bash
git clone https://github.com/<user>/<repo>.git
cd <repo>

# 复制到用户级
cp -r ./skills/my-skill ~/.claude/skills/

# 或复制到项目级
cp -r ./skills/my-skill ./.claude/skills/
```

### 符号链接跨平台共享

如果你同时使用 Claude Code 和 Codex CLI，可以用符号链接保持单一来源：

```bash
# 以 ~/.claude/skills 为主，其他工具指向它
ln -s ~/.claude/skills ~/.codex/skills
ln -s ~/.claude/skills ~/.openclaw/skills
```

---

## 使用与调用

Skill 有两种触发方式：

**自动触发**：Claude 根据 `SKILL.md` 里的 `description` 字段判断当前任务是否匹配，自动加载并应用。

```
用户：帮我看看我改了什么
Claude：（自动识别匹配 summarize-changes Skill，加载并执行）
```

**手动调用**：用 `/skill-name` 显式调用，目录名即命令名。

```bash
/summarize-changes
/my-skill
/commit-commands:commit    # 插件级 Skill，需加插件命名空间前缀
```

**内置 Bundled Skills**（Claude Code 自带，无需安装）：

| 命令 | 用途 |
|------|------|
| `/simplify` | 简化当前代码 |
| `/debug` | 调试当前问题 |
| `/batch` | 批量执行操作 |
| `/loop` | 循环执行直到满足条件 |
| `/claude-api` | 调用 Claude API |

---

## 验证与诊断

**验证 Skill 已加载：**

```bash
# 方式一：直接调用
/my-skill

# 方式二：问 Claude
"你有哪些可用的 Skill？"

# 方式三：运行诊断
/doctor
```

`/doctor` 会报告：

- 当前已加载的 Skill 列表
- description 预算是否溢出（Skill 太多时部分 description 会被截断）
- 哪些 Skill 因使用频率低而被降级

**热更新（无需重启）：**

修改已有 Skill 文件后，Claude Code 在当前会话内自动检测变更并生效。  
**例外**：如果 `~/.claude/skills/` 目录是本次会话启动后新建的，需要重启 Claude Code 才能被监听。

**手动检查文件：**

```bash
ls ~/.claude/skills/                         # 查看用户级已安装列表
ls .claude/skills/                           # 查看项目级已安装列表
cat ~/.claude/skills/my-skill/SKILL.md       # 确认文件内容
```

---

## SKILL.md 文件结构参考

```markdown
---
description: |
  一句话描述核心用途。
  触发条件：当用户询问 X、想做 Y 或提到 Z 时使用。
---

## 背景 / 上下文（可选）

给 Claude 补充必要的领域背景。

## 动态上下文注入（可选）

当前分支：!`git branch --show-current`
最近提交：!`git log --oneline -5`

## 操作步骤

1. 第一步做什么
2. 第二步做什么
3. 输出格式要求

## 约束 / 禁止行为（可选）

- 不要修改 src/core/ 以外的文件
- 不要删除测试文件
```

**`description` 写法建议：**

- 包含触发场景关键词，Claude 靠它做自动匹配
- 控制在 2–3 句以内，过长会被上下文预算截断
- 用"当用户…时使用"句式明确触发时机

---

## 多平台兼容说明

Skill 遵循 Agent Skills 开放标准，同一份 `SKILL.md` 可直接跨平台复用。

| 平台 | Skill 路径 | 调用方式 |
|------|-----------|---------|
| Claude Code | `~/.claude/skills/<name>/` | `/name` 或自动触发 |
| Codex CLI | `~/.codex/skills/<name>/` | 通过 `AGENTS.md` 指示 |
| Gemini CLI | `~/.gemini/skills/<name>/` | `activate_skill(name="name")` |
| Cursor / Aider | 项目级 `.claude/skills/` | 工具自身触发机制 |

Claude Code 特有功能（invocation control、subagent execution、动态上下文注入 `!`command``）在其他平台可能不支持，自定义 Skill 时注意平台差异。跨平台共享推荐用符号链接方案，见[安装方式 → 符号链接](#符号链接跨平台共享)。

---

## 运维：更新、禁用、删除

```bash
# 更新（替换文件）
cp -r new-version/my-skill ~/.claude/skills/my-skill

# 临时禁用（重命名，不删除）
mv ~/.claude/skills/my-skill ~/.claude/skills/_my-skill

# 恢复
mv ~/.claude/skills/_my-skill ~/.claude/skills/my-skill

# 删除
rm -rf ~/.claude/skills/my-skill

# 备份全部用户级 Skill
tar -czf ~/skills-backup.tar.gz ~/.claude/skills/

# 通过插件管理器更新
/plugin   # → Installed 标签页 → 选插件 → Update
```

---

## 常见问题排查

**Skill 没有被自动触发**  
→ 检查 `description` 字段是否清晰描述了触发场景  
→ 运行 `/doctor`，确认 description 没有因预算溢出被截断  
→ 改用手动调用 `/skill-name` 验证 Skill 本身是否正常工作

**`/skill-name` 命令未识别**  
→ 确认目录名和 `SKILL.md` 存在：`ls ~/.claude/skills/skill-name/`  
→ 如果是新建的顶级目录，重启 Claude Code

**插件 Skill 报 `Executable not found`**  
→ 代码智能插件需要系统已安装对应的 language server 二进制文件  
→ 查看 `/plugin` 的 Errors 标签页，按提示安装缺失的可执行文件

**Skill 在项目中不生效但用户级可以**  
→ 检查项目 `.claude/skills/` 路径是否拼写正确  
→ 用户级同名 Skill 会覆盖项目级，确认没有命名冲突

---

## 附录：路径速查

| 层级 | macOS / Linux | Windows |
|------|--------------|---------|
| 用户级 | `~/.claude/skills/<name>/SKILL.md` | `%USERPROFILE%\.claude\skills\<name>\SKILL.md` |
| 项目级 | `.claude/skills/<name>/SKILL.md` | `.claude\skills\<name>\SKILL.md` |
| Codex 用户级 | `~/.codex/skills/<name>/SKILL.md` | `%USERPROFILE%\.codex\skills\<name>\SKILL.md` |
| 企业全局 | 由管理员通过 Managed Settings 下发 | 同左 |

**相关文档：**

- [官方 Skills 文档](https://code.claude.com/docs/en/skills)
- [插件市场文档](https://code.claude.com/docs/en/discover-plugins)
- [Agent Skills 开放标准](https://agentskills.io)
- [claude.com/plugins — 官方插件目录](https://claude.com/plugins)