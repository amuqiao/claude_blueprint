<!-- WORKFLOW_START -->
## Claude Code Multi-Agent Workflow

本文件是 Claude Code 的多 agent 协作规则模板，适用于已经通过 Claude Code plugin marketplace 安装 VoltAgent subagents 的环境。目标是保留“先选工作流、按需派发专项 agent、最后 review 与 verify”的结构，同时使用 Claude Code 原生概念：`CLAUDE.md`、plugin subagents、内置 `Plan` / `general-purpose` agent。

使用 plugin subagent 时，以当前 Claude Code 已启用的 plugin 为准。VoltAgent plugin agent 使用 `<plugin-name>:<agent-name>` 命名空间，例如 `voltagent-lang:typescript-pro`、`voltagent-core-dev:api-designer`、`voltagent-qa-sec:code-reviewer`。

### 任务开始前必须选择工作流

任何代码任务开始前，必须先通过 `AskUserQuestion` 工具询问用户选择工作流。即使是单行修改、typo fix、显而易见的改动，也必须先问。

询问时提供以下两个选项，然后停止，等待用户回复后再进行任何代码相关操作：

```text
选择工作流：

1. plan -> subagent -> review -> verify（完整多 agent 流水线）
2. Just do it（直接执行，最后验证）

请回复 1 或 2。
```

用户回复 `1` 时，视为本任务已明确授权使用 Claude Code subagents / parallel agents。用户回复 `2` 时，不主动使用 subagents，除非用户后续明确要求。

### 触发场景

满足任一条，必须先询问工作流：

- 写新代码，包括新函数、新文件、新模块。
- 修改已有代码，包括编辑、重构、修 bug、改风格；单行改动也算。
- 增加或修改测试。
- 修改构建、依赖、类型、容器、迁移、CI、部署、模型评估等配置。
- 编写实现方案、设计文档、迁移计划、重构计划、发布计划或多 agent 执行计划。

以下场景不需要询问：

- 纯讨论、问答、解释。
- 只读代码、读文档、查找符号。
- 运行不修改源码的命令。
- 编辑 `CLAUDE.md`、settings、auto-memory、日报等元配置或元数据文件。
- 当前 session 已选过工作流，且仍是同一个连续任务。

### 工作流 1：plan -> subagent -> review -> verify

四阶段全部必须执行。

#### Plan 阶段

主 agent 先阅读上下文并制定计划。计划必须说明：

- 本任务需要哪些文件、模块、服务、配置或文档。
- 哪些工作适合交给 subagent 并行处理。
- 哪些工作必须由主 agent 在关键路径上完成。
- 预计使用哪些 plugin subagents；没有合适专项 agent 时使用 `Plan` 或 `general-purpose`。

Plan 阶段默认由主 agent 完成。只在确有必要时使用少数辅助角色：

- 架构权衡或边界评估：优先 `voltagent-qa-sec:architect-reviewer`。
- 外部文档/API 行为核验：可用 `voltagent-research:docs-researcher`。
- 跨模块大任务拆分：可用 `voltagent-meta:agent-organizer`、`voltagent-meta:task-distributor`。
- 多阶段、多团队或多 agent 流程：可用 `voltagent-meta:workflow-orchestrator`、`voltagent-meta:multi-agent-coordinator`。

不要为了“先找 agent 帮我选 agent”而递归派发。协调型 agent 只用于范围大、依赖多、风险高的任务。

#### Subagent 执行阶段

用户选择工作流 1 后，可以按任务领域显式调用 subagents。选择原则：

- 先看任务真实领域，再看 agent description 是否匹配。
- 执行类任务优先用对应技术栈或职责 agent。
- 多个互不依赖的子任务可以并行派发，但必须避免多个 agent 同时编辑同一文件。
- 每个 subagent 都必须有清晰角色、任务边界和预期输出；涉及文件编辑时，还必须明确可编辑范围和禁止事项。

常用执行路由：

- 前端框架：`voltagent-lang:react-specialist`、`voltagent-lang:vue-expert`、`voltagent-lang:angular-architect`、`voltagent-lang:nextjs-developer`。
- 前端实现与体验：`voltagent-core-dev:frontend-developer`、`voltagent-core-dev:ui-designer`。
- 后端与 API：`voltagent-core-dev:backend-developer`、`voltagent-core-dev:fullstack-developer`、`voltagent-core-dev:api-designer`。
- TypeScript / JavaScript / Node.js：`voltagent-lang:typescript-pro`、`voltagent-lang:javascript-pro`、`voltagent-lang:node-specialist`。
- Python：`voltagent-lang:python-pro`、`voltagent-lang:fastapi-developer`、`voltagent-lang:django-developer`。
- 系统与强类型语言：`voltagent-lang:golang-pro`、`voltagent-lang:rust-engineer`、`voltagent-lang:java-architect`、`voltagent-lang:spring-boot-engineer`、`voltagent-lang:csharp-developer`。
- 数据库与数据工程：`voltagent-lang:sql-pro`、`voltagent-data-ai:postgres-pro`、`voltagent-data-ai:database-optimizer`、`voltagent-data-ai:data-engineer`。
- 基础设施与发布：`voltagent-infra:docker-expert`、`voltagent-infra:kubernetes-specialist`、`voltagent-infra:terraform-engineer`、`voltagent-infra:deployment-engineer`、`voltagent-infra:devops-engineer`。
- AI / LLM / agent：`voltagent-data-ai:ai-engineer`、`voltagent-data-ai:llm-architect`、`voltagent-data-ai:mlops-engineer`。
- 工程效率：`voltagent-dev-exp:cli-developer`、`voltagent-dev-exp:build-engineer`、`voltagent-dev-exp:dependency-manager`、`voltagent-dev-exp:refactoring-specialist`。
- 文档：`voltagent-dev-exp:documentation-engineer`、`voltagent-dev-exp:readme-generator`。

明确领域任务才使用窄领域 agents，例如支付、金融、区块链、嵌入式、IoT、法律、SEO、WordPress 等。不要把它们作为普通代码任务默认路由。

#### Review 阶段

实现完成后，必须按风险维度选择 reviewer。多维风险可以并行运行多个 review subagents。

常用 review 路由：

- 综合代码质量 / 可维护性：`voltagent-qa-sec:code-reviewer`。
- 正确性 / 行为回归 / 失败定位：`voltagent-qa-sec:code-reviewer`、`voltagent-qa-sec:debugger`、`voltagent-qa-sec:error-detective`。
- 安全漏洞：`voltagent-qa-sec:security-auditor`、`voltagent-qa-sec:penetration-tester`。
- 合规风险：`voltagent-qa-sec:compliance-auditor`、`voltagent-qa-sec:gdpr-ccpa-compliance`。
- 性能瓶颈：`voltagent-qa-sec:performance-engineer`、`voltagent-data-ai:database-optimizer`。
- API 兼容性与合同破坏：`voltagent-core-dev:api-designer`。
- 架构合理性：`voltagent-qa-sec:architect-reviewer`。
- 构建、CI、打包、发布、回滚：`voltagent-dev-exp:build-engineer`、`voltagent-infra:deployment-engineer`、`voltagent-infra:devops-engineer`。
- 无障碍与 UI/UX：`voltagent-qa-sec:accessibility-tester`、`voltagent-qa-sec:ui-ux-tester`。
- 测试策略 / 覆盖缺口：`voltagent-qa-sec:qa-expert`、`voltagent-qa-sec:test-automator`。
- 技术文档真实性和质量：`voltagent-dev-exp:documentation-engineer`、`voltagent-dev-exp:readme-generator`、`voltagent-qa-sec:ai-writing-auditor`。

Review 发现的问题由主 agent 汇总判断；只修与当前任务相关的问题，不做无关重构。

#### Verify 阶段

声称完成前必须运行最小必要验证，并说明验证结果。可根据项目选择测试、构建、lint、类型检查、脚本语法检查、容器构建、部署 dry-run、模型评估或更窄目标命令。

只看 diff 不算完成。如果无法验证，必须说明原因和剩余风险。

### 工作流 2：Just do it

在最小范围内由主 agent 直接执行。默认不调用 subagents。

开始前仍需应用以下约束：

- 任务是 bug、测试失败或非预期行为时，先定位根因，再修复。必要时可在用户明确同意后使用 `voltagent-qa-sec:debugger` 或 `voltagent-qa-sec:error-detective`。
- 修改测试或添加可测逻辑时，优先先写测试再写实现。必要时可在用户明确同意后使用 `voltagent-qa-sec:test-automator` 或 `voltagent-qa-sec:qa-expert`。
- 涉及安全、合规、支付、生产数据、部署或 AI 风险时，即使选择 Just do it，也要在完成前做对应最小 review。
- 声称完成前必须运行最小必要验证；无法验证时说明原因。
- 只在用户明确要求时 commit。

### Claude Code 适配边界

- 不使用 Codex 专用 `.codex/agents/*.toml`、DeepSeek Harness `agent preset` / `Cordis` / `subagent_<role>` 工具命名。
- plugin subagent 名称使用 `<plugin-name>:<agent-name>`；不要把 plugin namespace 省略成裸 agent 名，除非明确使用手动 `.claude/agents/` 安装方式。
- 未安装对应 plugin 时，不要引用该 plugin 下的 agent。
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

编写代码时不要为了“更稳”擅自添加 fallback、silent catch、默认值吞错、空结果兼容或降级逻辑。除非需求明确要求，遇到异常应让错误快速暴露，便于定位和修复。
<!-- NO_FALLBACK_END -->

<!-- LANGUAGE_START -->
## 语言偏好

默认使用中文回复用户，包括正文、总结、提问、进度更新等所有面向用户的文本。

- 派发给 agent/subagent 的执行结果、审查意见即使原文是英文，转述给用户时必须翻译改写成中文，不要直接搬运英文原文。
- 代码、命令、路径、协议名、库名等技术对象保持英文原文。
- 仅当用户主动用英文提问，或明确要求用英文回复时，才切换成英文。
<!-- LANGUAGE_END -->
