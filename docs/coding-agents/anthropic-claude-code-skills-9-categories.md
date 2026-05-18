# Anthropic 内部实践的 9 类 Skills 分类

> **原文来源**：Thariq Shihipar（Anthropic Claude Code 工程团队）于 2026 年 3 月 17 日发布的帖文  
> **原文链接**：[X (Twitter) 原帖](https://x.com/trq212/status/2033949937936085378) · [LinkedIn 文章版](https://www.linkedin.com/pulse/lessons-from-building-claude-code-how-we-use-skills-thariq-shihipar-iclmc)  
> **完整整理版**：[GitHub - shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice/blob/main/tips/claude-thariq-tips-17-mar-26.md)

---

## 背景

Skills 已经成为 Claude Code 中使用最广泛的扩展点之一。Anthropic 内部在积极使用 **数百个 Skills**，在对它们进行系统整理后，发现它们集中于以下 9 大类别。

> 一个关键观察：**大多数团队只使用了其中 2–3 类**，不是因为其他类别没用，而是因为他们不知道这些类别的存在。

---

## 重要前提：Skills 不只是 Markdown 文件

一个常见误解是把 Skills 当作"只是 Markdown 文件"。实际上，**Skills 是文件夹**，可以包含脚本、资源、数据等——是 Claude 可以动态发现、探索和使用的完整工具包，还支持注册动态 Hooks 等高级配置。

---

## 9 大 Skills 类别

### 1. 库与 API 参考（Library & API Reference）

**定位**：解释如何正确使用某个库、CLI 工具或 SDK。

这类 Skills 可以针对内部私有库，也可以针对 Claude Code 偶尔处理不好的公共库。通常包含一个参考代码片段文件夹，以及一份需要规避的"坑点（Gotchas）"清单。

**示例**：`billing-lib`、`internal-platform-cli`、`frontend-design`

---

### 2. 产品验证（Product Verification）

**定位**：描述如何测试或验证代码是否正常工作。

这类 Skills 通常与 Playwright、tmux 等外部工具配合使用。验证类 Skills 对确保 Claude 输出的正确性极为重要——Thariq 认为，**让一名工程师花一周时间专门打磨验证 Skill，完全值得**。

典型技巧：用无头浏览器模拟用户操作、在每个步骤添加断言、录制验证过程视频。

**示例**：`signup-flow-driver`、`checkout-verifier`、`tmux-cli-driver`

---

### 3. 数据获取与分析（Data Fetching & Analysis）

**定位**：连接组织内部的数据与监控体系。

可包含附带凭证的数据获取库、特定 Dashboard ID，以及常用数据查询流程或方式说明，让 Claude 能够在组织独特的数据迷宫中快速定位。

**示例**：`funnel-query`、`cohort-compare`、`grafana`

---

### 4. 业务流程与团队自动化（Business Process & Team Automation）

**定位**：将重复性工作流自动化为单条命令。

这类 Skills 通常指令较简单，但可能依赖其他 Skills 或 MCP。将以往执行结果保存到日志文件中，可帮助模型保持一致性、并对历史执行进行回顾。

**示例**：`standup-post`、`create-<ticket-system>-ticket`、`weekly-recap`

---

### 5. 代码脚手架与模板（Code Scaffolding & Templates）

**定位**：为代码库中特定功能生成框架样板代码。

可以将 Skill 与脚本组合使用。当脚手架中包含"只有自然语言才能描述"的需求时（即无法完全用代码表达），这类 Skills 尤为有价值。

**示例**：`new-<framework>-workflow`、`new-migration`、`create-app`

---

### 6. 代码质量与审查（Code Quality & Review）

**定位**：在组织内落地代码质量规范，并辅助代码审查。

可以包含确定性脚本或工具以确保鲁棒性。可以配置为在 Hooks 中自动触发，或集成进 GitHub Action 流水线中运行。

**示例**：`adversarial-review`、`code-style`、`testing-practices`

---

### 7. CI/CD 与部署（CI/CD & Deployment）

**定位**：帮助在代码库中完成代码的拉取、推送和部署操作。

这类 Skills 可以引用其他 Skills 来收集所需数据，支撑完整的发布流程。

**示例**：`babysit-pr`、`deploy-<service>`、`cherry-pick-prod`

---

### 8. 故障排查手册（Runbooks）

**定位**：接受一个"症状"（如 Slack 消息、告警通知、报错签名），走完多工具排查流程，最终输出结构化报告。

这类 Skills 沉淀了团队历史踩坑经验，让 Claude 在故障发生时能有条不紊地协助定位和处理问题。

**示例**：`<service>-debugging`、`oncall-runner`、`log-correlator`

---

### 9. 基础设施运维（Infrastructure Operations）

**定位**：执行日常维护和运维操作流程，其中部分操作涉及破坏性动作，因此需要内置防护措施（Guardrails）。

这类 Skills 降低了工程师在关键操作中犯错的风险，使遵循最佳实践变得更加自然。

**示例**：`<resource>-orphans`（清理孤立资源）、`dependency-management`、`cost-investigation`

---

## 关于你看到的分类描述，是否准确？

**基本准确，但存在若干偏差**，对比原文有以下几点差异：

| 你看到的描述 | 原文实际名称与说明 |
|---|---|
| 数据分析（Data Analysis） | **数据获取与分析（Data Fetching & Analysis）** — 侧重点包含"连接数据源/监控系统"，不仅是分析 |
| 代码模板（Code Templates） | **代码脚手架与模板（Code Scaffolding & Templates）** — 强调框架生成，而非泛泛的"模板" |
| 代码审查（Code Review） | **代码质量与审查（Code Quality & Review）** — 范围更广，包含质量规范落地 |
| 故障排查手册（Troubleshooting Manuals） | **Runbooks** — 原文强调"接受症状 → 多工具排查 → 结构化报告"这一特定流程 |
| 产品验证描述较简略 | 原文特别强调：值得专门派一名工程师花一周打磨验证 Skill |

---

## 写好 Skills 的核心原则（原文 9 条 Tips 摘要）

1. **不要陈述显而易见的内容**——聚焦于能推动 Claude 突破默认思维的信息
2. **构建 Gotchas 章节**——每个 Skill 最高价值的内容来自已知的"坑点"，持续更新
3. **利用文件系统实现渐进式披露**——Skill 是一个文件夹，让 Claude 按需读取，而非一次性加载所有内容
4. **避免过度限制 Claude**——给出目标与约束，而非逐步骤的死板指令
5. **想清楚初始配置**——用 `config.json` 存储配置，首次运行时引导用户填写
6. **描述字段是写给模型看的**——用于描述"何时触发"此 Skill，而非功能摘要
7. **支持记忆与数据存储**——可用日志文件、JSON 或 SQLite 存储会话间状态
8. **内置脚本，生成代码**——给 Claude 可直接调用的代码，让它专注于组合而非重写样板
9. **使用按需 Hooks**——仅在 Skill 激活时生效的 Hook，适合高度定制的防护规则（如 `/careful` 阻止 `rm -rf`）

---

## 参考链接

- **原始帖文（X/Twitter）**：https://x.com/trq212/status/2033949937936085378
- **GitHub 完整整理版**：https://github.com/shanraisshan/claude-code-best-practice/blob/main/tips/claude-thariq-tips-17-mar-26.md
- **Anthropic 官方 Skills 文档**：https://code.claude.com/docs/en/skills
- **Anthropic Agent Skills 技术博客**：https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- **Anthropic 公开 Skills 仓库**：https://github.com/anthropics/skills
