# Claude Code 新用户完整指南

> 一个新用户，一个新项目，从安装到交付的完整路径。
> 每个概念在第一次出现时都会先解释清楚再往下走。

---

## 一、先建心智模型

Claude Code 是运行在终端的 AI 编程助手。它的能力来自三个来源，每次 session 启动时按顺序叠加：

```
┌────────────────────────────────────────────────────────────────┐
│  来源        内容                          加载时机             │
├────────────────────────────────────────────────────────────────┤
│  配置层      CLAUDE.md + rules/            session 启动全量加载 │
│  能力层      Skills + Plugins              按需激活             │
│  对话层      你说的话                      实时注入             │
└────────────────────────────────────────────────────────────────┘
```

**配置层**定义约束——告诉 Claude 什么不能做、什么必须做，始终在后台生效。

**能力层**扩展工具——告诉 Claude 怎么完成某类特定任务，按需激活。能力层有两种形态：

- **Skill**：一个 `SKILL.md` 文件，描述 Claude 如何完成某类任务。手动放进 `~/.claude/skills/` 即可使用。session 启动时只加载索引（name + description），匹配到意图时才加载正文。
- **Plugin**：可安装的分发包，可以打包 skills、hooks、agents、MCP servers 等，通过插件市场安装（`/plugin install`）。Plugin 里的 **hook 机制是推送型的**——按事件自动触发，不依赖意图匹配，安装即生效。

两者的关键区别：

| | Skill | Plugin |
|---|---|---|
| 形态 | 单个 SKILL.md 文件 | 含 skills + hooks + agents 的分发包 |
| 安装 | 手动放入 `~/.claude/skills/` | `/plugin install name@marketplace` |
| 触发 | 意图匹配或显式调用 | Hook 按事件自动触发，skill 按意图触发 |
| 适合 | 自定义工作流、操作手册 | 需要 hook 自动化或打包分发的场景 |

---

## 二、配置的两个层级

Claude Code 有系统级和项目级两套配置：

```
系统级  ~/.claude/              → 对所有项目生效，个人私有，不提交 git
项目级  your-project/.claude/   → 只对当前项目生效，提交 git，团队共享
```

同名规则存在时，项目级覆盖系统级。

### 完整目录结构

```
~/.claude/                        ← 系统级
├── CLAUDE.md                     ← 全局核心约束，< 100 行
├── settings.json                 ← 权限、hooks、模型配置
├── rules/                        ← 全局规则（主题化拆分）
│   ├── git.md
│   ├── testing.md
│   ├── workflow.md
│   └── security.md
├── skills/                       ← 手动安装的全局 Skill
│   ├── planning-with-files/
│   ├── code-review-skill/
│   └── ui-ux-pro-max/
├── plugins/                      ← Plugin 安装数据（自动管理，勿手动编辑）
│   ├── installed_plugins.json
│   └── cache/
├── agents/                       ← 全局子智能体
└── commands/                     ← 全局斜杠命令

your-project/.claude/             ← 项目级
├── CLAUDE.md                     ← 项目专属约束
├── settings.json                 ← 项目权限配置
├── rules/                        ← 项目专属规则
│   ├── api.md
│   └── frontend/
│       └── react.md
├── skills/                       ← 项目专属 Skill
├── agents/
└── commands/
```

> `plugins/` 由 Claude Code 自动管理，存放在 `~/.claude/plugins/`，不需要也不应该手动操作。

---

## 三、能力层的五种机制

知道每种东西是什么，才知道装了之后会发生什么。

### CLAUDE.md — 最高优先级约束

session 启动时自动全量读入，无条件生效。只放每次都必须遵守的核心规则，控制在 100 行以内。超过后 Claude 开始静默忽略，具体规范拆进 `rules/`。

### rules/ — 主题化约束

CLAUDE.md 的模块化拆分。session 启动时 `rules/` 下所有 `.md` 文件全量读入上下文，始终在后台约束行为。

frontmatter 里可以写 `paths` 字段，告诉 Claude「这条规则只对匹配路径的文件执行」——但**内容始终全量加载**，paths 不控制是否加载，只是 Claude 推理时的执行条件。`paths: []`（空数组）会导致规则从不执行，应删掉该字段。

### Skills — 任务型操作手册

每个 skill 是一个目录，入口文件是 `SKILL.md`。session 启动时只加载各 skill 的 name + description（索引），Claude 识别到任务意图匹配时才完整加载正文。也可显式调用：`/skill-name` 或自然语言点名。

### Plugins — 分发包，含 hook 自动化

通过 `/plugin install` 从插件市场安装。Plugin 可打包 skills、hooks、agents、MCP servers。其中 **hook 是推送型的**——按事件（session 启动、工具调用前后、session 退出等）自动触发，不需要意图匹配，安装即生效。这是 Plugin 和纯 Skill 最核心的区别。

```bash
/plugin                                    # 浏览已安装的 Plugin
/plugin install name@claude-plugins-official  # 从官方市场安装
/plugin marketplace add author/repo        # 添加第三方市场
/plugin install name@repo                  # 从第三方市场安装
```

### agents/ — 独立子智能体

有独立上下文窗口和工具权限的子任务执行者，由主 session 委托启动，执行不污染主上下文。

---

## 四、前置条件

```bash
# 必须
node --version                             # Node.js 18+
npm install -g @anthropic-ai/claude-code   # 安装 Claude Code
claude                                     # 登录，按提示完成 OAuth

# 按需
brew install gh && gh auth login           # GitHub CLI（Code Review 需要）
npx playwright install chromium            # Playwright（Webapp Testing 需要）
```

---

## 五、能力地图与安装

10 个推荐工具覆盖开发全流程，3 个是 Plugin，7 个是 Skill：

```
流程增强
  Superpowers             [Plugin]  编程方法论，hook 自动介入需求澄清和规划
  Planning with Files     [Skill]   任务状态持久化到文件系统
  Ralph Loop              [Plugin]  Stop Hook 强制任务闭环

质量保障
  Code Review             [Skill]   多智能体并行代码审查
  Code Simplifier         [Plugin]  Anthropic 官方代码整理 Agent
  Webapp Testing          [Skill]   Playwright 自动化测试

产出增强
  UI UX Pro Max           [Skill]   设计数据库驱动的 UI 建议
  PPTX                    [Skill]   直接生成原生 .pptx 文件

能力扩展
  MCP Builder             [Skill]   引导开发 MCP Server
  Skill Creator           [Skill]   创建自定义 Skill
```

**安装建议**：先装流程类，再按需补充。

---

### 流程增强

#### Superpowers `[Plugin]`

完整的 AI 编程工作方法论。打包了 skills + hooks，hook 在 session 启动时自动注册，识别到「实现功能」意图时自动拦截，先引导澄清需求再执行。全程无需手动触发。

```bash
# 在 Claude Code session 内运行：
/plugin install superpowers@claude-plugins-official
```

触发：自动。说「帮我实现 X 功能」，它自动介入。

---

#### Planning with Files `[Skill]`

把任务状态写入文件（`task_plan.md` · `findings.md` · `progress.md`），让 `/compact` 或 session 重启后任务可以无缝恢复。

```bash
npx skills add https://github.com/OthmanAdi/planning-with-files \
  --skill planning-with-files --global
```

触发：显式。说「把规划写到文件里」。  
产出：`task_plan.md`（任务清单）、`findings.md`（技术决策）、`progress.md`（进度快照）。

---

#### Ralph Loop `[Plugin]`

通过 Stop Hook 阻止 Claude 中途退出，强制闭环。打包了 hook 脚本，安装即生效。Claude 完成一步试图退出时，hook 拦截并重新喂入 prompt，继续下一步。

```bash
# 在 Claude Code session 内运行：
/plugin marketplace add MarioGiancini/ralph-loop-setup
/plugin install ralph-loop-setup
```

触发：显式启动循环，hook 自动拦截退出。
```
/ralph-loop "按 task_plan.md 逐项完成，完成后输出 <promise>DONE</promise>" --max-iterations 30
```

---

### 质量保障

#### Code Review `[Skill]`

多智能体并行代码审查，覆盖 17+ 语言，渐进式加载（核心 ~190 行，语言指南按需加载）。输出分级：`blocking / important / nit / suggestion`。

```bash
git clone https://github.com/awesome-skills/code-review-skill.git \
  ~/.claude/skills/code-review-skill
```

触发：显式。「用 code-review-skill 审查这次改动」

---

#### Code Simplifier `[Plugin]`

Anthropic 官方开源 Agent。对已完成代码做二次整理，以独立子智能体身份运行，不污染主上下文，不改变任何外部行为。

```bash
# 在 Claude Code session 内运行：
/plugin marketplace update claude-plugins-official
/plugin install code-simplifier
```

触发：显式。「用 code-simplifier agent 整理今天的改动」

---

#### Webapp Testing `[Skill]`

Anthropic 官方出品，基于 Playwright 的 Web 自动化测试。需要 Playwright 已安装。

```bash
npx skills add https://github.com/anthropics/skills \
  --skill webapp-testing --global
npx playwright install chromium
```

触发：显式。`/webapp-testing 访问 http://localhost:3000，测试登录流程，截图`

---

### 产出增强

#### UI UX Pro Max `[Skill]`

设计数据库驱动的 UI 建议：67 种 UI 风格、161 个配色方案、57 个字体搭配、99 条 UX 指南，覆盖 16 个技术栈。

```bash
npx skills add https://github.com/nextlevelbuilder/ui-ux-pro-max-skill \
  --skill ui-ux-pro-max
cp -r ~/.agents/skills/ui-ux-pro-max ~/.claude/skills/ui-ux-pro-max  # 同步到 Claude Code
rm -rf ~/.claude/skills/ui-ux-pro-max/scripts                        # 可选：删除高风险脚本
```

触发：`/ui-ux-pro-max 设计科技感登录页` 或直接描述 UI 任务。

---

#### PPTX `[Skill]`

Anthropic 官方出品，直接生成原生 `.pptx` 文件。

```bash
npx skills add https://github.com/anthropics/skills --skill pptx --global
```

触发：显式。「用 pptx skill 生成一份 5 页的产品方案 PPT」

---

### 能力扩展

#### MCP Builder `[Skill]`

四阶段框架引导开发高质量 MCP Server（Python 或 TypeScript）。

```bash
npx skills add https://github.com/anthropics/skills --skill mcp-builder --global
```

#### Skill Creator `[Skill]`

官方元技能，用于创建、修改、测试新 Skill。

```bash
npx skills add https://github.com/anthropics/skills --skill skill-creator --global
```

---

## 六、推荐 Rules 配置

新项目起手四条，放系统级 `~/.claude/rules/`：

### `git.md`
```yaml
---
description: Git 提交规范
---
提交信息必须符合 Conventional Commits 格式：<type>(<scope>): <subject>
type: feat / fix / docs / refactor / test / chore
每个提交只做一件事，功能完成后立即提交，不积攒大提交。
```

### `testing.md`
```yaml
---
description: 测试要求
---
声明"测试通过"前必须展示实际运行输出，不接受假设性声明。
提交前必须跑完整测试套件。单元测试中外部服务必须 mock。
```

### `workflow.md`
```yaml
---
description: 工作流约束
---
新功能开始前先澄清需求，不做猜测性实现。
声明任何状态前必须提供新鲜验证证据。
发现超出范围的问题，记录到 TODO，不立即扩展。
```

### `security.md`
```yaml
---
description: 安全编码规范
---
禁止硬编码密钥、token、密码，只从环境变量读取。
所有用户输入必须校验，SQL 查询必须参数化。
不读取或修改 ~/.ssh、~/.aws 等敏感目录。
```

---

## 七、完整任务流示例

**场景**：新项目，实现用户登录功能（React + FastAPI）。

**初始化**

```bash
cd your-project && claude
/init    # 生成 CLAUDE.md 草稿，删减至 100 行以内
```

**Session 启动（自动）**

```
加载顺序（优先级从低到高）：
① ~/.claude/CLAUDE.md            全局核心约束
② ~/.claude/rules/*.md           全局规则，全部读入
③ your-project/CLAUDE.md         项目约束，覆盖同类全局规则
④ .claude/rules/*.md             项目规则，全部读入
⑤ CLAUDE.local.md（如存在）

同时：
- Skill 索引加载（name + description，正文不加载）
- Plugin hook 根据事件类型注册完毕
```

**需求澄清（Superpowers Plugin hook 自动触发）**
```
你：帮我实现用户登录功能，email + 密码方式
```
→ hook 识别到「实现功能」意图，自动引导澄清需求。`workflow.md` 和 `security.md` 同时在后台约束。

**规划落档（Planning with Files Skill 显式触发）**
```
你：把规划写到文件里
```
→ 生成 `task_plan.md`、`findings.md`、`progress.md`。跨 session 状态存储。

**循环执行（Ralph Loop Plugin 显式启动，Stop Hook 自动运转）**
```
你：/ralph-loop "按 task_plan.md 逐项完成，完成后输出 <promise>DONE</promise>" --max-iterations 30
```
→ 实现 → 测试（testing.md）→ 提交（git.md）→ 更新 progress.md → Hook 拦截退出 → 继续。

**压缩恢复**
```
你：/compact
你：读取 task_plan.md 和 progress.md，从中断处继续
```

**代码整理（Code Simplifier Plugin）**
```
你：用 code-simplifier agent 整理今天的改动
```

**代码审查（Code Review Skill）**
```
你：用 code-review-skill 审查登录功能的改动
```

**前端优化（UI UX Pro Max Skill）**
```
你：/ui-ux-pro-max 帮登录页选一套配色和字体，科技感风格
```

**自动化验证（Webapp Testing Skill）**
```
你：/webapp-testing 访问 http://localhost:3000/login，测试正确密码、错误密码、空字段，截图
```

---

## 八、触发方式汇总

| 工具 | 类型 | 触发方式 |
|------|------|---------|
| CLAUDE.md | 配置 | session 启动自动全量加载 |
| rules/ | 配置 | session 启动自动全量加载 |
| Superpowers | Plugin | hook 已注册，意图匹配自动触发 |
| Planning with Files | Skill | 显式：「把规划写到文件里」 |
| Ralph Loop | Plugin | 显式启动循环；Stop Hook 自动拦截退出 |
| Code Review | Skill | 显式：「用 code-review-skill 审查」 |
| Code Simplifier | Plugin | 显式：「用 code-simplifier agent 整理」 |
| Webapp Testing | Skill | 显式：`/webapp-testing` |
| UI UX Pro Max | Skill | 显式或意图匹配 |
| PPTX | Skill | 显式：「用 pptx skill 生成」 |
| MCP Builder | Skill | 显式 |
| Skill Creator | Skill | 显式 |

---

## 九、常见误解

**paths 控制规则是否加载进上下文**  
→ 加载永远全量。paths 只告诉 Claude「这条规则只对匹配路径的文件执行」。`paths: []` 应删掉。

**Skill 和 Plugin 是同一回事**  
→ Skill 是操作手册（意图触发），Plugin 是分发包（可含 hook 自动触发）。Superpowers 是 Plugin，不是因为它能力强，而是因为它有 hook，装好就自动生效，不依赖你调用。

**CLAUDE.md 越详细越好**  
→ 超过 100 行后 Claude 开始静默忽略。核心约束留 CLAUDE.md，细节拆进 rules/。

**上下文压缩后任务就断了**  
→ Planning with Files 把状态写进文件，压缩后读文件恢复，无缝继续。

**Rules 和 Skills 功能重复**  
→ Rules 是约束（始终在后台），Skills 是执行手册（按需激活）。前者说「什么不能做」，后者说「怎么做某件事」。
