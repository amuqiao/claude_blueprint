<!-- WORKFLOW_START -->
## Codex Multi-Agent Workflow

本文件是 Claude Code 多 agent 协作规则的 Codex 适配版。目标是保留
"先选工作流、再按需派发专项 agent、最后 review 与 verify" 的协作结构，
但所有执行方式必须使用 Codex 原生概念：AGENTS.md、custom agents、
subagents，以及内置 `default` / `worker` / `explorer`。

### 任务开始前必须选择工作流

任何代码任务开始前，必须先询问用户选择工作流。即使是单行修改、
typo fix、显而易见的改动，也必须先问。

询问时输出以下内容，然后停止，等待用户回复后再进行任何代码相关操作：

```
选择工作流：

1. plan -> subagent -> review -> verify（完整多 agent 流水线）
2. Just do it（直接执行，最后验证）

请回复 1 或 2。
```

用户回复 `1` 时，视为本任务已明确授权使用 Codex subagents / parallel
agents。用户回复 `2` 时，不主动使用 subagents，除非用户后续明确要求。

### 触发场景

满足任一条，必须先询问工作流：

- 写新代码，包括新函数、新文件、新模块。
- 修改已有代码，包括编辑、重构、修 bug、改风格；单行改动也算。
- 增加或修改测试。
- 修改构建、依赖、类型、容器、迁移等配置。
- 编写实现方案、设计文档、迁移计划或重构计划。

以下场景不需要询问：

- 纯讨论、问答、解释。
- 只读代码、读文档、查找符号。
- 运行不修改源码的命令。
- 编辑 AGENTS.md、config.toml、auto-memory、日报等元配置或元数据文件。
- 当前 session 已选过工作流，且仍是同一个连续任务。

### 工作流 1：plan -> subagent -> review -> verify

四阶段全部必须执行。

#### Plan 阶段

主 agent 先阅读上下文并制定计划。计划必须说明：

- 本任务需要哪些文件或模块。
- 哪些工作适合交给 subagent 并行处理。
- 哪些工作必须由主 agent 在关键路径上完成。
- 预计使用哪些 custom agents；没有合适专项 agent 时使用 `default`、
  `worker` 或 `explorer`。

纯架构权衡或技术选型优先使用 `architect-reviewer` 参与分析。代码路径梳理和影响面分析优先使用 `explorer`。

#### Subagent 执行阶段

用户选择工作流 1 后，可以按任务领域显式 spawn subagents。选择原则：先看
任务技术栈和职责，再选择 description 最匹配的 custom agent；不要强行套用
不相关的专项 agent。

执行类任务优先使用 `worker` 或对应专项 agent；只读探索优先使用 `explorer`。
多个互不依赖的子任务可以并行派发，但必须避免多个 agent 同时编辑同一文件。

| 技术栈 / 场景 | 优先使用的 agent |
|---|---|
| TypeScript | `typescript-pro` |
| JavaScript | `javascript-pro` |
| React | `react-specialist` |
| Vue | `vue-expert` |
| Angular | `angular-architect` |
| Next.js | `nextjs-developer` |
| Node.js 服务 | `node-specialist` |
| Python 通用 | `python-pro` |
| Python / FastAPI | `fastapi-developer` |
| Python / Django | `django-developer` |
| Rust | `rust-engineer` |
| Go | `golang-pro` |
| Java / Spring | `java-architect` / `spring-boot-engineer` |
| Kotlin | `kotlin-specialist` |
| Swift / iOS | `swift-expert` |
| Flutter | `flutter-expert` |
| React Native / Expo | `expo-react-native-expert` |
| PHP 通用 | `php-pro` |
| Laravel | `laravel-specialist` |
| Symfony | `symfony-specialist` |
| Ruby / Rails | `rails-expert` |
| C# / .NET | `csharp-developer` / `dotnet-core-expert` |
| C++ | `cpp-pro` |
| SQL / 数据库 | `sql-pro` |
| Elixir | `elixir-expert` |
| PowerShell | `powershell-7-expert` / `powershell-5.1-expert` |
| 前端 UI/UX 实现 | `frontend-developer` |
| UI 视觉设计决策 | `ui-designer` |
| 后端 API 实现 | `backend-developer` |
| API 合同设计 | `api-designer` |
| 跨前后端完整功能 | `fullstack-developer` |
| Electron | `electron-pro` |
| 移动端跨平台 | `mobile-developer` |
| GraphQL | `graphql-architect` |
| 微服务架构 | `microservices-architect` |
| WebSocket | `websocket-engineer` |
| 无匹配技术栈 | `default` 或 `worker` |

#### Review 阶段

实现完成后，必须按风险维度选择 reviewer。多维风险可以并行运行多个
review subagents。

| 风险维度 | 优先使用的 agent |
|---|---|
| 代码质量 / 可维护性 | `code-reviewer` |
| 正确性 / 行为回归 | `code-reviewer` / `debugger` |
| 安全漏洞 | `security-auditor` / `penetration-tester` |
| 合规风险 | `compliance-auditor` / `gdpr-ccpa-compliance` |
| 性能瓶颈 | `performance-engineer` |
| 架构合理性 | `architect-reviewer` |
| 无障碍合规 | `accessibility-tester` |
| UI/UX 流程 | `ui-ux-tester` |
| 测试策略 / 覆盖缺口 | `qa-expert` / `test-automator` |

Review 发现的问题由主 agent 汇总判断；只修与当前任务相关的问题，不做无关
重构。

#### Verify 阶段

声称完成前必须运行最小必要验证，并说明验证结果。可根据项目选择测试、构建、
lint、类型检查或更窄的目标命令。只看 diff 不算完成。

如果无法验证，必须说明原因和剩余风险。

### 工作流 2：Just do it

在最小范围内由主 agent 直接执行。默认不 spawn subagents。

开始前仍需应用以下约束：

- 任务是 bug、测试失败或非预期行为时，先定位根因，再修复。必要时可在用户
  明确同意后使用 `debugger` 或 `error-detective`。
- 修改测试或添加可测逻辑时，优先先写测试再写实现。必要时可在用户明确同意后
  使用 `test-automator` 或 `qa-expert`。
- 声称完成前必须运行最小必要验证；无法验证时说明原因。
- 只在用户明确要求时 commit。

### Codex 适配边界

- 不使用 Claude 专用工具、插件命名空间或 skill 名称。
- custom agent 名称使用 `.codex/agents/*.toml` 中的 name 字段；文件名只作为
  简单约定，最终以 name 为准。
- Codex 内置 agents 只有 `default`、`worker`、`explorer`。不要引用不存在的
  内置 agent。
- subagents 只在用户选择工作流 1 或后续明确要求时使用。
- 保持改动小范围、可验证、可回滚；不要引入无关重构、依赖升级或目录迁移。

### 严格规则

- 不得以任务小为由跳过询问。
- 不得默认进入任何一个工作流。
- 不得先改代码再问。
- 收到用户回复后才能开始代码相关操作。

<!-- WORKFLOW_END -->

<!-- NO_FALLBACK_START -->
## 不擅自添加兜底策略

编写代码时不要为了“更稳”擅自添加 fallback、silent catch、默认值吞错、
空结果兼容或降级逻辑。除非需求明确要求，遇到异常应让错误快速暴露，
便于定位和修复。
<!-- NO_FALLBACK_END -->

<!-- LANGUAGE_START -->
## 语言偏好

**默认使用中文回复用户**——包括正文、总结、提问、进度更新等所有面向用户的文本，不论任务涉及的代码、子 agent 或工具返回内容是什么语言。

- 派发给 Agent/subagent 的执行结果、审查意见即使原文是英文，转述给用户时必须翻译改写成中文，不要直接搬运英文原文。
- 代码、命令、路径、协议名、库名等技术对象保持英文原文，不强行翻译。
- 仅当用户主动用英文提问，或明确要求用英文回复时，才切换成英文。
<!-- LANGUAGE_END -->