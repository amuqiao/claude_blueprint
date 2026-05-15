# Claude Code Rules 完整指南

> **覆盖内容**：rules 机制原理、推荐规则清单、如何自定义、如何触发、如何与 Skill 协作。

---

## 一、先建整体理解

Rules 解决的核心问题：**CLAUDE.md 只有一个文件，会越写越长，越长越容易被忽略。**

Rules 是 CLAUDE.md 的模块化拆分方案——把不同主题的规则拆进独立文件，让约束按主题组织，而不是全都堆在一个入口文件里。

```
规则体系三层
├── CLAUDE.md          → 核心骨架（< 100 行）：每次必须遵守的最高优先级约束
├── rules/             → 模块化规则：默认全局适用；必要时用 paths 限定作用域
└── Skills             → 任务型能力：完成特定任务时调用的深度操作手册
```

**三者分工边界**：

| 放 CLAUDE.md | 放 rules/ | 放 Skills |
|---|---|---|
| 层间调用方向 | 代码风格规范 | 代码审查流程 |
| 绝对禁止行为 | 测试要求 | UI 设计数据库 |
| 核心架构约束 | 安全检查清单 | MCP 开发框架 |

---

## 二、Rules 生效机制

理解这个机制是正确使用 rules 的前提。

### 无 `paths` 字段 → 全局规则（推荐）

```yaml
---
description: 代码风格规范
---
# 代码风格
- 使用 ES modules，不用 CommonJS
- 函数声明优先于箭头函数
```

每次 session 启动自动进入上下文，无条件适用。适合跨文件类型的通用约束。

### 有 `paths` 字段 → 路径条件执行

```yaml
---
paths:
  - "src/api/**/*.ts"
  - "src/routes/**/*.ts"
---
# API 开发规范
- 所有入参必须用 Zod 校验
- 返回统一错误结构：{ error: string, code: number }
- 所有请求记录 correlation ID
```

规则内容照样会进入上下文，但 Claude 需要自己判断当前操作是否命中这些路径，然后决定是否执行这条规则。这个判断依赖模型推理，因此**不如全局规则稳定**。

### 已知限制

- 不要写 `paths: []`；需要全局规则时，直接删掉 `paths` 字段
- `paths` 不是“是否加载”的开关，而是“是否适用这条规则”的作用域提示
- 全局规则比带 `paths` 的条件规则更稳，优先选择无 `paths` 的写法
- 只有在不同目录确实需要不同约束，或两条规则需要明确划分作用域时，才添加 `paths`

---

## 三、目录结构

```
~/.claude/rules/          ← 全局规则，所有项目生效
your-project/.claude/rules/  ← 项目规则，仅当前项目生效

推荐组织方式：
.claude/rules/
├── code-style.md         # 代码格式与命名
├── testing.md            # 测试要求
├── security.md           # 安全检查清单
├── git.md                # 提交与分支规范
├── workflow.md           # 工作流约束
└── frontend/             # 支持子目录
    ├── react.md
    └── styling.md
```

加载优先级：全局规则先加载，项目规则后加载（项目规则优先级更高，可覆盖全局）。

---

## 四、推荐规则清单

按主题分组，按需选用。

---

### 4.1 代码风格（`code-style.md`）

适合放全局，跨所有项目统一表达习惯。

```markdown
---
description: 代码风格与命名规范
---

# 代码风格

## 通用
- 使用 ES modules（import/export），禁止 require()
- 函数声明优先于箭头函数（export function foo() 而非 export const foo = () =>）
- 显式 return，避免隐式返回增加阅读成本
- 嵌套不超过 3 层，超出则提取函数

## 命名
- 变量和函数：camelCase
- 组件和类：PascalCase
- 常量：SCREAMING_SNAKE_CASE
- 文件名：kebab-case

## 禁止
- 不写 any 类型（TypeScript）
- 不用 console.log 进生产代码，用 logger
- 不写魔法数字，提取为命名常量
```

---

### 4.2 测试要求（`testing.md`）

```markdown
---
description: 测试规范与覆盖率要求
---

# 测试规范

## 基本要求
- 实现新功能前先写测试（TDD）
- 单元测试覆盖率不低于 80%
- 外部服务在单元测试中必须 mock

## 执行要求
- 提交前必须跑完整测试套件
- 声明"测试通过"前必须展示实际运行输出，不接受假设性声明
- 测试失败时不得跳过，必须修复后再继续

## 禁止
- 不写只测实现细节而不测行为的测试
- 不在测试里写业务逻辑
```

---

### 4.3 安全检查（`security.md`）

```markdown
---
description: 安全编码规范，防止常见漏洞
---

# 安全规范

## 必须检查
- 所有用户输入必须校验和净化，不信任任何外部输入
- 禁止在代码中硬编码密钥、token、密码
- 敏感信息只从环境变量读取，不提交 .env 文件
- SQL 查询必须用参数化查询，禁止字符串拼接

## 文件操作
- 操作文件路径前必须校验，防止路径穿越
- 不读取或修改 ~/.ssh、~/.aws、~/.gnupg 等敏感目录

## 依赖安全
- 添加新依赖前检查是否有已知 CVE
- 不安装来源不明的包
```

---

### 4.4 Git 规范（`git.md`）

```markdown
---
description: 提交信息与分支命名规范
---

# Git 规范

## 提交信息（Conventional Commits）
格式：<type>(<scope>): <subject>

type 枚举：
- feat：新功能
- fix：修复 bug
- docs：文档变更
- refactor：重构（不改功能）
- test：测试相关
- chore：构建、依赖、配置

示例：
- feat(auth): add OAuth2 login flow
- fix(api): handle null response from payment service
- docs(readme): update installation steps

## 提交粒度
- 每个提交只做一件事
- 不提交 WIP 到主分支
- 每完成一个独立任务就提交，不攒大提交

## 分支命名
- feature/描述-kebab-case
- fix/描述-kebab-case
- 不直接在 main/master 上开发
```

---

### 4.5 工作流约束（`workflow.md`）

```markdown
---
description: 开发工作流通用约束
---

# 工作流规范

## 开始前
- 新功能必须先有设计草案（问题定义 + 数据模型），再动代码
- 任务不明确时先澄清需求，不要开始猜测性实现

## 执行中
- 完成后立即验证（运行测试 / 截图 / 检查日志），不接受未验证的"应该可以"
- 声明任何状态（测试通过、bug 修复、功能完成）前必须提供新鲜的验证证据
- 发现问题超出原任务范围时，记录到 TODO 而不是立即扩展范围

## 完成后
- 新功能先跑核心流程 smoke test 确认无问题
- 有破坏性变更时主动说明影响范围
```

---

### 4.6 前端规范（`frontend/react.md`，路径条件规则）

```markdown
---
description: React 开发规范
paths:
  - "src/components/**/*.tsx"
  - "src/hooks/**/*.ts"
  - "src/pages/**/*.tsx"
---

# React 规范

- 只用函数组件，不用 class 组件
- 业务逻辑提取到 custom hook，组件只做渲染
- 昂贵计算用 useMemo，稳定回调用 useCallback
- 组件文件不超过 200 行，超出则拆分
- 用 data-testid 而不是 CSS 选择器做测试定位
- 禁止在组件内直接发 HTTP 请求，通过服务层调用
```

---

### 4.7 API 规范（`backend/api.md`，路径条件规则）

```markdown
---
description: API 开发规范
paths:
  - "src/api/**/*.ts"
  - "src/routes/**/*.ts"
---

# API 规范

- 所有请求参数用 Zod 校验，校验失败返回 400
- 统一错误结构：{ error: string, code: number, requestId: string }
- 所有请求记录 correlation ID，便于追踪
- 不在 controller 层写业务逻辑，委托给 service 层
- 敏感操作（删除、支付）必须有幂等性保护
```

---

## 五、如何自定义规则

### 5.1 从零写一条规则

三个要素：

**① frontmatter（必须有）**

```yaml
---
description: 这条规则是什么（给人看，也影响 Claude 识别场景）
# paths 可选：有则限定适用路径，无则全局适用
---
```

**② 规则正文**

好规则的特征：
- 描述行为，而不是态度（"每次提交前运行测试" 而非 "认真对待测试"）
- 给出反例（`❌ 不要...` `✅ 应该...`）
- 避免 Claude 自己就会做的事（"尽量写好代码" 这类无效）

**③ 放对位置**

```bash
# 全局（所有项目）
~/.claude/rules/my-rule.md

# 项目级（当前项目）
.claude/rules/my-rule.md
```

### 5.2 从现有 CLAUDE.md 迁移

如果你的 CLAUDE.md 已经很长，迁移步骤：

```bash
# 1. 建立 rules 目录
mkdir -p ~/.claude/rules

# 2. 按主题拆分内容
# 把代码风格相关的内容移到 code-style.md
# 把测试相关的内容移到 testing.md
# 以此类推

# 3. 给每个文件加 frontmatter
# 4. CLAUDE.md 只保留最核心的骨架（< 100 行）
# 5. 运行 /memory 验证规则被正确加载
```

### 5.3 用软链共享团队规则

```bash
# 把公司标准规则放在共享目录
~/company-standards/
├── security.md
└── git.md

# 在项目里软链，不用复制
ln -s ~/company-standards/security.md .claude/rules/security.md
ln -s ~/company-standards/git.md .claude/rules/git.md
```

---

## 六、Rules 如何与 Skill 协作

Rules 和 Skills 是互补关系，不是替代关系：

**Rules = 约束层**：告诉 Claude 什么不能做、什么必须做，始终在后台生效。
**Skills = 执行层**：告诉 Claude 怎么完成某类特定任务，按需激活。

### 协作示例：写一个 PR

```
Rules 在后台持续约束：
  ├── git.md → 提交信息格式必须是 Conventional Commits
  ├── testing.md → 声明完成前必须运行测试
  └── security.md → 不提交含密钥的文件

Skills 按任务激活：
  ├── Code Review skill → 审查改动
  ├── Code Simplifier → 整理代码
  └── Webapp Testing → 验证前端行为
```

Rules 不会说"怎么做代码审查"，那是 Skill 的职责。Skill 也不会说"提交信息必须符合 Conventional Commits"，那是 Rule 的职责。

### 一个完整任务流的分工

```
你说：实现用户登录功能

┌─ Rules 层（全程约束，无需触发）───────────────────┐
│  workflow.md   → 先澄清需求再动代码               │
│  testing.md    → 先写测试，完成后验证             │
│  security.md   → 密码必须哈希，不硬编码密钥       │
│  git.md        → 每步提交，用 Conventional 格式   │
└──────────────────────────────────────────────────┘

┌─ Skills 层（按需激活）──────────────────────────────┐
│  Planning with Files → 写 task_plan.md            │
│  Ralph Loop → 执行任务闭环不中途退出              │
│  Code Simplifier → 功能完成后整理代码             │
│  Webapp Testing → 验证登录流程                    │
└──────────────────────────────────────────────────┘
```

---

## 七、社区推荐规则来源

| 来源 | 内容 | 适合场景 |
|------|------|---------|
| `affaan-m/everything-claude-code` | 77 条规则，覆盖 13 种语言 | 按语言栈选装 |
| `MuhammadUsmanGM/claude-code-best-practices` | React/Python/Go/Rust 等 11 套模板 | 项目起盘时参考 |
| `shanraisshan/claude-code-best-practice` | 社区实战总结，持续更新 | 了解最新社区实践 |
| `NikiforovAll/claude-code-rules` | 可通过插件市场安装 | 快速上手 |

安装 everything-claude-code 的通用规则：

```bash
git clone https://github.com/affaan-m/everything-claude-code /tmp/ecc

# 安装通用规则（全局）
cp -r /tmp/ecc/rules/common ~/.claude/rules/

# 按技术栈选装（示例：TypeScript + Web）
cp -r /tmp/ecc/rules/typescript ~/.claude/rules/
cp -r /tmp/ecc/rules/web ~/.claude/rules/
```

---

## 八、快速检查清单

配置完成后，用这个清单验证是否正确：

```
□ 每个 rules 文件都有 frontmatter（至少有 description 字段）
□ 默认不写 paths；只有确实需要限定作用域时才添加
□ 没有 paths: []；全局规则直接省略该字段
□ CLAUDE.md 控制在 100 行以内
□ 启动 session 后 /memory 能看到规则内容
□ 全局规则放 ~/.claude/rules/，项目规则放 .claude/rules/
□ Rules 只写约束，不写操作手册（操作手册放 Skill）
```
