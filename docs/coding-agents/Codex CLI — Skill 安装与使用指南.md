# Codex CLI — Skill 安装与使用指南

**文档职责**：说明如何在 Codex CLI（OpenAI）中安装、配置和使用 Skill。  
**适用场景**：个人开发者接入 Skill、团队通过仓库共享 Skill、企业管理员统一下发 Skill。  
**目标读者**：使用 `codex` 命令的开发者，包括个人用户和团队管理员。  
**维护规范**：路径以 macOS/Linux 为主，Windows 路径见[附录](#附录路径速查)。

> **注意**：本文档仅适用于 **Codex CLI**（OpenAI 出品，命令为 `codex`）。  
> Anthropic Claude Code CLI 的 Skill 机制完全不同，请参考 [Claude Code CLI — Skill 安装与使用指南](./Claude%20Code%20CLI%20—%20Skill%20安装与使用指南.md)。

---

## Skill 是什么

Skill 是一个包含 `SKILL.md` 文件的目录，给 Codex 注入专项知识或工作流。Codex 在启动时扫描约定路径，将所有发现的 Skill 的名称和 description 加入系统提示，在任务匹配时自动加载完整内容。

**与 Claude Code 的核心差异**：Codex Skill 不仅依赖目录约定，还可以通过 `config.toml` 显式注册任意路径的 Skill，并支持独立的 `agents/openai.yaml` 文件声明调用策略和 MCP 依赖。调用语法也不同，Codex 用 `$skill-name` 而非 `/skill-name`。

---

## 作用域层级

Codex 从五个位置扫描 Skill，优先级如下：

```
优先级（高 → 低）

  REPO（项目级）    ← .agents/skills/<name>/   仅当前仓库，随 git 提交
       ↓
  USER（用户级）    ← ~/.codex/skills/<name>/  所有项目可用
       ↓
  ADMIN（管理级）   ← 企业管理员统一部署，不可被用户覆盖
       ↓
  SYSTEM（系统级）  ← Codex 内置系统 Skill（~/.codex/skills/.system/）
       ↓
  PLUGIN（插件级）  ← 随插件分发，通过插件管理器安装
```

| 层级 | 路径 | 适合放什么 |
|------|------|-----------|
| REPO | `.agents/skills/<name>/` | 项目专属规范，团队共享 |
| USER | `~/.codex/skills/<name>/` | 个人工作流，跨项目复用 |
| ADMIN | 企业管理员统一部署 | 公司规范、安全检查、合规流程 |
| SYSTEM | `~/.codex/skills/.system/`（内置） | Codex 自带，不建议手动修改 |
| PLUGIN | 插件目录内 | 随插件生命周期管理 |

**覆盖规则**：REPO > USER > ADMIN > SYSTEM。同名 Skill 多层并存时，优先级高的生效；但不同于 Claude Code，**两个同名 Skill 不会合并，都会出现在 Skill 选择器中**。

---

## Skill 来源

### 官方 Skill（OpenAI 官方）

OpenAI 在 [github.com/openai/skills](https://github.com/openai/skills) 维护官方 Skill 目录，通过内置的 `$skill-installer` 安装。

```bash
# 使用内置 skill-installer 安装官方 Skill
$skill-installer install https://github.com/openai/skills/tree/main/skills/<skill-name>

# 安装后重启 Codex 使其生效
```

也可以通过 `/plugins` 管理 OpenAI 官方插件（插件内含 Skill）：

```bash
/plugins   # 打开插件管理器，浏览官方插件
```

### 第三方市场 / 社区 Skill

Codex 的 Skill 分发通过**插件（Plugin）**机制进行，插件可以打包一个或多个 Skill 连同 MCP 配置一起分发。

```bash
# 添加 GitHub 插件市场源
codex plugin marketplace add <owner>/<repo>

# 通过插件安装 Skill 集合
/plugins   # 浏览并安装
```

常用社区来源：

| 来源 | 说明 |
|------|------|
| [github.com/openai/skills](https://github.com/openai/skills) | OpenAI 官方 Skill 目录 |
| [agentskills.io](https://agentskills.io) | 跨平台 Skill 开放标准与目录 |
| [agensi.io](https://www.agensi.io) | 付费/免费 Skill 商店 |

### 自定义 Skill

自己编写 `SKILL.md`，放入约定路径或通过 `config.toml` 注册。也可以使用内置的 `$skill-creator` 辅助创建。

---

## 安装方式

### 方式一：手动部署到约定目录

**第一步：确定作用域，创建目录**

```bash
# 用户级（个人工作流）
mkdir -p ~/.codex/skills/my-skill

# 项目级（团队共享，推荐 REPO 路径）
mkdir -p .agents/skills/my-skill
```

**第二步：创建 `SKILL.md`**

```markdown
---
name: my-skill
description: |
  一句话说明用途和触发时机。
  触发条件：当用户需要做 X 或提到 Y 时使用。
  不应触发：当用户做 Z 时不使用本 Skill。
---

## 指令内容

Codex 执行时遵循的步骤。

## 参考文件（可选）

详细规范见 [./references/rules.md](./references/rules.md)。
```

与 Claude Code 不同，Codex `SKILL.md` 的 frontmatter 中 **`name` 字段是必填的**，用于 `$name` 调用和 Skill 选择器展示。

**第三步（可选）：添加 `agents/openai.yaml`（Codex 专有）**

这是 Codex 特有的元数据文件，用于声明调用策略和 MCP 工具依赖：

```yaml
interface:
  display_name: "我的 Skill"
  short_description: "简短描述（显示在 UI 中）"
  brand_color: "#3B82F6"
  default_prompt: "使用本 Skill 时的默认提示词"

policy:
  allow_implicit_invocation: false   # 默认 true；false = 只能显式 $skill 调用

dependencies:
  tools:
    - type: "mcp"
      value: "github"
      description: "需要 GitHub MCP 服务"
      transport: "streamable_http"
      url: "https://mcp.github.com"
```

`allow_implicit_invocation: false` 适合高风险操作（如部署、删除），防止 Codex 在不恰当时机自动触发。

**第四步（可选）：完整目录结构**

```
my-skill/
├── SKILL.md                # 入口（必须）
├── agents/
│   └── openai.yaml         # Codex 调用策略（可选）
├── scripts/
│   └── run.sh              # 可执行脚本
├── references/
│   └── rules.md            # 按需加载的参考文档
└── assets/
    └── template.md         # 模板文件
```

**安装后需重启 Codex** 使新目录生效。

### 方式二：通过 `config.toml` 注册任意路径的 Skill

Codex 支持在配置文件中注册任意位置的 Skill，这是 Claude Code 不具备的能力。

```toml
# ~/.codex/config.toml（用户级，全局生效）
# 或 .codex/config.toml（项目级，需信任项目）

[[skills.config]]
path = "/path/to/my-skill/SKILL.md"
enabled = true

[[skills.config]]
path = "/path/to/another-skill/SKILL.md"
enabled = false   # 暂时禁用
```

修改 `config.toml` 后需**重启 Codex**生效。

### 方式三：通过 `$skill-installer` 安装

Codex 内置 `$skill-installer`，可以从 URL 安装官方或社区 Skill：

```bash
# 在 Codex 会话中调用
$skill-installer install https://github.com/openai/skills/tree/main/skills/<skill-name>
```

安装后默认存放在 `~/.codex/skills/`，重启 Codex 生效。

### 方式四：git clone 后手动复制

```bash
git clone https://github.com/<user>/<repo>.git

# 用户级
cp -r <repo>/skills/my-skill ~/.codex/skills/

# 项目级（REPO 路径）
cp -r <repo>/skills/my-skill ./.agents/skills/
```

### 方式五：使用 `$skill-creator` 创建自定义 Skill

Codex 内置 `$skill-creator`，引导你交互式创建 Skill：

```bash
# 在 Codex 会话中调用
$skill-creator
```

Codex 会询问 Skill 的用途、触发条件，以及是否需要附带脚本，最终生成完整目录结构。

---

## 使用与调用

**自动触发（隐式调用）**：Codex 根据 `description` 匹配当前任务，自动加载 Skill。可在 `agents/openai.yaml` 中设置 `allow_implicit_invocation: false` 关闭特定 Skill 的自动触发。

**手动调用（显式调用）**：用 `$skill-name` 前缀，在提示词中直接引用。

```bash
# 在 Codex 提示词中显式调用
$my-skill 帮我检查这段代码

# 从 Skill 选择器选择
/skills    # 打开 Skill 选择器，浏览并选择
```

**内置 System Skills**（Codex 自带，无需安装）：

| 调用名 | 用途 |
|--------|------|
| `$skill-creator` | 引导创建新 Skill |
| `$skill-installer` | 从 URL 安装社区 Skill |
| `$plan` | 管理 Codex 计划文档（`~/.codex/plans/`） |

---

## 验证与诊断

**验证 Skill 已加载：**

```bash
# 方式一：在提示词中显式调用
$my-skill

# 方式二：打开 Skill 选择器查看列表
/skills

# 方式三：直接问 Codex
"列出所有可用的 Skill"
```

**检查文件是否到位：**

```bash
ls ~/.codex/skills/                          # 用户级列表
ls .agents/skills/                           # 项目级列表
cat ~/.codex/skills/my-skill/SKILL.md        # 查看内容
```

**检查 config.toml 注册状态：**

```bash
cat ~/.codex/config.toml | grep -A3 "skills.config"
```

**重要**：与 Claude Code 不同，Codex **不支持热更新**。新增或修改 Skill 后，必须重启 Codex 才能生效。

---

## SKILL.md 结构参考

```markdown
---
name: skill-name                    # 必填，小写字母 + 连字符
description: |
  核心用途一句话。
  触发条件：当用户需要做 X 时使用，涉及 Y 关键词时触发。
  不触发场景（可选但推荐）：当用户做 Z 时不使用本 Skill。
license: Apache-2.0                 # 可选
compatibility: Requires Python 3.14+  # 可选
---

## 背景（可选）

给 Codex 补充领域知识。

## 操作步骤

1. 第一步
2. 打开 references/rules.md 查阅规则
3. 执行 scripts/run.sh
4. 输出格式要求

## 约束（可选）

- 不要修改 src/core/ 之外的文件
```

**description 写法要点**：

- 前缀关键触发词（Codex 在描述被截断时优先保留前段）
- 明确说明**不触发场景**，防止误激活高风险 Skill
- `name` 字段决定 `$name` 调用名，只允许小写字母、数字和连字符

---

## 运维操作

```bash
# 更新（替换目录）
cp -r new-version/my-skill ~/.codex/skills/my-skill
# 重启 Codex

# 禁用（在 config.toml 中设置 enabled = false）
# 或重命名目录
mv ~/.codex/skills/my-skill ~/.codex/skills/_my-skill

# 恢复
mv ~/.codex/skills/_my-skill ~/.codex/skills/my-skill

# 删除
rm -rf ~/.codex/skills/my-skill

# 备份
tar -czf ~/codex-skills-backup.tar.gz ~/.codex/skills/
```

---

## 常见问题

**Skill 没有自动触发**  
→ 检查 `description` 是否包含触发场景关键词，且关键词是否前置  
→ 检查 `agents/openai.yaml` 中是否设置了 `allow_implicit_invocation: false`  
→ 用 `$my-skill` 手动调用，验证 Skill 本身是否正常

**`$skill-name` 未被识别**  
→ 确认目录和 `SKILL.md` 存在，且 `name` 字段与调用名一致  
→ 确认已重启 Codex（新增 Skill 必须重启）  
→ 检查 `config.toml` 中该 Skill 是否被设置为 `enabled = false`

**`$skill-installer` 安装后找不到 Skill**  
→ 安装后需重启 Codex  
→ 检查 `~/.codex/skills/` 目录下是否有对应目录

**MCP 工具依赖缺失**  
→ 检查 `agents/openai.yaml` 的 `dependencies.tools` 中声明的 MCP 服务是否已配置  
→ 在 `config.toml` 中添加对应 MCP Server 配置

---

## 附录：路径速查

| 层级 | macOS / Linux | Windows |
|------|--------------|---------|
| 用户级 | `~/.codex/skills/<name>/SKILL.md` | `%USERPROFILE%\.codex\skills\<name>\SKILL.md` |
| 项目级（REPO） | `.agents/skills/<name>/SKILL.md` | `.agents\skills\<name>\SKILL.md` |
| 系统内置 | `~/.codex/skills/.system/` | `%USERPROFILE%\.codex\skills\.system\` |
| 企业管理级 | 管理员统一部署 | 同左 |

**参考文档**：[developers.openai.com/codex/skills](https://developers.openai.com/codex/skills) · [developers.openai.com/codex/config-reference](https://developers.openai.com/codex/config-reference)
