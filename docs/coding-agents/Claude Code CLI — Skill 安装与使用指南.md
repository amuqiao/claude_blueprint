# Claude Code CLI — Skill 安装与使用指南

**文档职责**：说明如何在 Claude Code CLI（Anthropic）中安装、管理和使用 Skill。  
**适用场景**：个人开发者接入 Skill、团队共享项目级 Skill、企业统一下发规范 Skill。  
**目标读者**：使用 `claude` 命令的开发者，包括个人用户和团队管理员。  
**维护规范**：路径以 macOS/Linux 为主，Windows 路径见[附录](#附录路径速查)。

> **注意**：本文档仅适用于 **Claude Code CLI**（Anthropic 出品，命令为 `claude`）。  
> OpenAI Codex CLI 的 Skill 机制完全不同，请参考 [Codex CLI — Skill 安装与使用指南](./Codex%20CLI%20—%20Skill%20安装与使用指南.md)。

---

## Skill 是什么

Skill 是一个封装在 `SKILL.md` 文件里的指令包。与 `CLAUDE.md`（始终全量加载）不同，Skill **按需加载**——只有任务匹配或被手动调用时，才进入上下文，不占用多余 Token。

**安装目录即注册**：把 Skill 目录放到约定路径，Claude Code 在启动时自动发现，无需任何配置文件声明。这是 Claude Code Skill 机制最重要的特点。

---

## 作用域层级

放在哪里，决定对谁生效。

```
优先级（高 → 低）

  企业全局（Enterprise）  ← 管理员通过 Managed Settings 统一下发
       ↓
  用户级（Personal）      ← ~/.claude/skills/<name>/   所有项目可用
       ↓
  项目级（Project）       ← .claude/skills/<name>/     仅当前仓库
       ↓ 命名空间隔离
  插件级（Plugin）        ← plugin-name:skill-name     随插件启用/禁用
```

| 层级 | 路径 | 适合放什么 |
|------|------|-----------|
| 企业全局 | 管理员 Managed Settings 下发 | 公司规范、合规流程、安全检查 |
| 用户级 | `~/.claude/skills/<name>/` | 个人工作流，跨项目复用 |
| 项目级 | `.claude/skills/<name>/` | 项目专属规范，随仓库 git 提交共享 |
| 插件级 | 插件目录内 `skills/` | 随插件生命周期管理，命名空间 `plugin:skill` |

**覆盖规则**：同名 Skill 多层并存时，企业 > 用户 > 项目。插件级使用独立命名空间，不参与覆盖。

---

## Skill 来源

### 官方 Skill（Anthropic 官方市场）

官方市场 `claude-plugins-official` 在 Claude Code 启动时自动注册，直接使用 `/plugin` 命令安装。

```bash
# 打开插件管理界面，浏览官方插件
/plugin

# 直接安装
/plugin install github@claude-plugins-official
/plugin install figma@claude-plugins-official
/plugin install atlassian@claude-plugins-official
```

在线目录：[claude.com/plugins](https://claude.com/plugins)

官方插件三类：代码智能（LSP 接入）、外部集成（GitHub / Linear / Notion 等 MCP）、工作流（commit、PR review 等）。

### 第三方市场 / 社区 Skill

**两步流程：先添加市场源，再安装插件。**

```bash
# 添加 GitHub 仓库为市场源
/plugin marketplace add anthropics/claude-code

# 添加其他 Git 源
/plugin marketplace add https://gitlab.com/company/plugins.git

# 添加本地目录
/plugin marketplace add ./my-marketplace

# 安装具体插件
/plugin install commit-commands@anthropics-claude-code
```

通过 `/plugin` 安装时，可选三种作用域：

- **User scope**（默认）：安装给自己，所有项目可用
- **Project scope**：写入 `.claude/settings.json`，随仓库共享给团队
- **Local scope**：仅自己在当前仓库可用，不提交

常用社区来源：

| 来源 | 地址 |
|------|------|
| Anthropic 演示库 | `/plugin marketplace add anthropics/claude-code` |
| agentskills.io | [agentskills.io](https://agentskills.io) |
| agensi.io | [agensi.io](https://www.agensi.io) |

### 自定义 Skill

自己编写 `SKILL.md`，放入约定路径即生效。

---

## 安装方式

### 方式一：手动部署（自定义 Skill）

**第一步：确定作用域，创建目录**

```bash
# 用户级（个人工作流）
mkdir -p ~/.claude/skills/my-skill

# 项目级（团队共享）
mkdir -p .claude/skills/my-skill
```

**第二步：创建 `SKILL.md`**

```markdown
---
description: 一句话说明用途和触发时机。
             Use when the user asks about X or wants to do Y.
---

## 指令内容

Claude 执行时遵循的步骤。

## 动态上下文（可选）

当前改动：!`git diff HEAD`
```

文件由两部分组成：

- **YAML frontmatter**（`---` 之间）：`description` 是触发匹配的核心，Claude 靠它决定何时自动加载
- **Markdown 正文**：执行时的指令内容

**第三步（可选）：添加支撑文件**

```
my-skill/
├── SKILL.md            # 入口（必须）
├── spec.md             # 规范文档
├── examples/
│   └── sample.md       # 示例输出
└── scripts/
    └── run.sh          # 可执行脚本
```

### 方式二：通过 `/plugin` 市场安装

见[上方「第三方市场 / 社区 Skill」](#第三方市场--社区-skill)。

### 方式三：git clone 后手动复制

```bash
git clone https://github.com/<user>/<repo>.git
cp -r <repo>/skills/my-skill ~/.claude/skills/    # 用户级
cp -r <repo>/skills/my-skill ./.claude/skills/    # 项目级
```

### 方式四：通过 npx 工具安装

```bash
npx skills add <user>/<repo> --skill <skill-name>
npx skills list   # 查看已安装
```

---

## 使用与调用

**自动触发**：Claude 根据 `description` 字段匹配当前任务，自动加载 Skill。

**手动调用**：目录名即命令名，用 `/` 前缀调用。

```bash
/my-skill                         # 用户级或项目级 Skill
/commit-commands:commit           # 插件级 Skill（需加 plugin: 前缀）
```

**内置 Bundled Skills**（无需安装，开箱即用）：

| 命令 | 用途 |
|------|------|
| `/simplify` | 简化当前代码 |
| `/debug` | 调试当前问题 |
| `/batch` | 批量执行操作 |
| `/loop` | 循环执行直到满足条件 |
| `/claude-api` | 调用 Claude API |

---

## 验证与诊断

```bash
# 方式一：直接调用
/my-skill

# 方式二：运行诊断
/doctor

# 方式三：检查文件
ls ~/.claude/skills/                        # 用户级列表
ls .claude/skills/                          # 项目级列表
cat ~/.claude/skills/my-skill/SKILL.md      # 查看内容
```

`/doctor` 报告的关键信息：
- 已加载的 Skill 列表
- description 预算是否溢出（Skill 过多时，低频 Skill 的 description 会被截断）
- 受影响的具体 Skill

**热更新**：修改已有 Skill 文件，当前会话内自动生效，无需重启。  
**例外**：若 `~/.claude/skills/` 是会话启动后新建的顶级目录，需重启 Claude Code。

---

## SKILL.md 结构参考

```markdown
---
description: |
  核心用途一句话。
  Use when the user asks about X, wants to do Y, or mentions Z.
---

## 背景（可选）

给 Claude 补充领域知识。

## 动态上下文（可选）

当前分支：!`git branch --show-current`
最近提交：!`git log --oneline -5`

## 操作步骤

1. 第一步
2. 第二步
3. 输出格式

## 约束（可选）

- 不要修改 src/core/ 之外的文件
```

**description 写法要点**：用"Use when..."句式，包含关键触发词，控制在 2–3 句以内防止被预算截断。

---

## 运维操作

```bash
# 更新（替换目录）
cp -r new-version/my-skill ~/.claude/skills/my-skill

# 临时禁用（重命名）
mv ~/.claude/skills/my-skill ~/.claude/skills/_my-skill

# 恢复
mv ~/.claude/skills/_my-skill ~/.claude/skills/my-skill

# 删除
rm -rf ~/.claude/skills/my-skill

# 备份
tar -czf ~/skills-backup.tar.gz ~/.claude/skills/
```

---

## 常见问题

**Skill 没有自动触发**  
→ 检查 `description` 是否含触发场景的关键词  
→ 运行 `/doctor` 确认 description 没有被截断  
→ 先用 `/skill-name` 手动验证 Skill 本身是否正常

**`/skill-name` 未被识别**  
→ 确认目录和 `SKILL.md` 存在：`ls ~/.claude/skills/skill-name/`  
→ 新建的顶级目录需重启 Claude Code

**插件 Skill 报 `Executable not found`**  
→ 代码智能插件依赖系统已安装 language server 二进制  
→ 查看 `/plugin` Errors 标签页，安装缺失的可执行文件

---

## 附录：路径速查

| 层级 | macOS / Linux | Windows |
|------|--------------|---------|
| 用户级 | `~/.claude/skills/<name>/SKILL.md` | `%USERPROFILE%\.claude\skills\<name>\SKILL.md` |
| 项目级 | `.claude/skills/<name>/SKILL.md` | `.claude\skills\<name>\SKILL.md` |
| 企业全局 | 管理员 Managed Settings 下发 | 同左 |

**参考文档**：[code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills) · [code.claude.com/docs/en/discover-plugins](https://code.claude.com/docs/en/discover-plugins)
