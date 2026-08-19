<!-- WORKFLOW_START -->
## Codex Multi-Agent Workflow

本文件用于在 Codex 中启用“专家角色模式”。该模式默认全量安装 `VoltAgent/awesome-codex-subagents` 的 custom agents，但 `AGENTS.md` 只维护 80 个高频路由角色，目标是固定“先选工作流、按需派发专项 agent、最后 review 与 verify”的协作流程，同时避免把完整 172 角色索引塞进规则文件。

Codex 的专家能力来自当前生效的 custom agent 定义：全局目录是 `~/.codex/agents/*.toml`，项目级目录是 `.codex/agents/*.toml`，项目级优先级更高。agent 名称取 `.toml` 中的 `name` 字段；`description` 用于判断该 agent 适合什么任务。本文只列常用路由，不是完整 agent 名录；未列出的 agent 可以在确有匹配时按其 `description` 精确使用。

### 任务开始前必须选择工作流

任何代码任务开始前，必须先询问用户选择工作流。即使是单行修改、typo fix、显而易见的改动，也必须先问。

询问时输出以下内容，然后停止，等待用户回复后再进行任何代码相关操作：

```text
选择工作流：

1. plan -> subagent -> review -> verify（完整多 agent 流水线）
2. Just do it（直接执行，最后验证）

请回复 1 或 2。
```

用户回复 `1` 时，视为本任务已明确授权使用 Codex subagents / parallel agents。用户回复 `2` 时，不主动使用 subagents，除非用户后续明确要求。

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
- 编辑 `AGENTS.md`、`config.toml`、auto-memory、日报等元配置或元数据文件。
- 当前 session 已选过工作流，且仍是同一个连续任务。

### 工作流 1：plan -> subagent -> review -> verify

四阶段全部必须执行。

#### Plan 阶段

主 agent 先阅读上下文并制定计划。计划必须说明：

- 本任务需要哪些文件、模块、服务、配置或文档。
- 哪些工作适合交给 subagent 并行处理。
- 哪些工作必须由主 agent 在关键路径上完成。
- 预计使用哪些 custom agents；没有合适专项 agent 时使用 Codex 内置 `default`、`worker` 或 `explorer`。

Plan 阶段默认由主 agent 完成。只在确有必要时使用少数辅助角色：

- 代码路径、入口、调用链、状态流梳理：优先 `explorer`，需要更系统的代码地图时可用 `code-mapper`。
- 架构权衡或边界评估：优先 `architect-reviewer`。
- 外部文档/API 行为核验：可用 `docs-researcher`。
- 跨模块大任务拆分：可用 `agent-organizer`、`task-distributor`。
- 多阶段、多团队或多 agent 流程：可用 `workflow-orchestrator`、`multi-agent-coordinator`。

不要为了“先找 agent 帮我选 agent”而递归派发。协调型 agent 只用于范围大、依赖多、风险高的任务。

#### Subagent 执行阶段

用户选择工作流 1 后，可以按任务领域显式 spawn subagents。选择原则：

- 派发任何 subagent 时，prompt 开头必须明确说明：主会话的人类用户已选择工作流 1，当前 subagent 是被授权执行者，禁止再次询问工作流选择，禁止以“需要先选工作流”为由暂停任务。
- 先看任务真实领域，再看 agent description 是否匹配。
- 只读探索优先用 `explorer`、`code-mapper`、`docs-researcher`。
- 执行类任务优先用对应技术栈或职责 agent。
- 多个互不依赖的子任务可以并行派发，但必须避免多个 agent 同时编辑同一文件。
- 实现类 subagent 默认最多同时运行 2-3 个；只读探索、review、verify 可以适度增加并发。超过该范围时应分批派发。
- 每个 subagent prompt 必须包含角色、任务、边界、可编辑范围、输出格式和禁止事项。
- custom agent 名称必须使用 `.toml` 的 `name` 字段，例如 `api-designer`、`code-reviewer`、`typescript-pro`；不要使用文件路径、插件命名空间或其他 runtime 的工具名。

常用执行路由：

- 前端框架：`react-specialist`、`vue-expert`、`angular-architect`、`nextjs-developer`。
- 前端实现与体验：`frontend-developer`、`ui-designer`、`ui-fixer`。
- 后端与 API：`backend-developer`、`fullstack-developer`、`api-designer`、`api-documenter`。
- TypeScript / JavaScript / Node.js：`typescript-pro`、`javascript-pro`、`node-specialist`。
- Python：`python-pro`、`fastapi-developer`、`django-developer`。
- 系统与强类型语言：`golang-pro`、`rust-engineer`、`java-architect`、`spring-boot-engineer`、`csharp-developer`、`dotnet-core-expert`。
- 数据库与数据工程：`sql-pro`、`postgres-pro`、`database-optimizer`、`data-engineer`。
- 架构与实时系统：`microservices-architect`、`graphql-architect`、`websocket-engineer`。
- 基础设施与发布：`docker-expert`、`kubernetes-specialist`、`terraform-engineer`、`deployment-engineer`、`devops-engineer`。
- AI / LLM / agent：`ai-engineer`、`llm-architect`、`prompt-engineer`、`mcp-developer`。
- 工程效率：`cli-developer`、`build-engineer`、`dependency-manager`、`refactoring-specialist`、`tooling-engineer`。
- 文档：`documentation-engineer`、`readme-generator`。

明确领域任务才使用窄领域 agents，例如支付、金融、区块链、嵌入式、IoT、医疗合规、法律、SEO、WordPress 等。不要把它们作为普通代码任务默认路由。

custom agent 使用原则：

- 有明确匹配时，优先调用专项 custom agent，例如 API 合同设计用 `api-designer`，代码审查用 `code-reviewer`，TypeScript 任务用 `typescript-pro`。
- 没有明确匹配时，使用 `default`、`worker` 或 `explorer`，并在 prompt 中写清临时角色。
- custom agent 的 persona 来自对应 `.toml`，但这不代表可以跳过任务边界说明；仍需在 prompt 中写清输入、范围、禁止事项和输出格式。
- 不要在 `AGENTS.md` 中展开全部专家说明；本模式的 80 个高频路由由 `voltagent-roles/ROUTE_ALLOWLIST.txt` 维护。`ROUTE_ALLOWLIST.txt` 不是 Codex runtime 配置，也不限制安装数量，只是维护本规则文件时的参考真源。

#### Review 阶段

实现完成后，必须按风险维度选择 reviewer。多维风险可以并行运行多个 review subagents。

常用 review 路由：

- 综合代码质量 / 可维护性：`code-reviewer`、`reviewer`。
- 正确性 / 行为回归 / 失败定位：`code-reviewer`、`debugger`、`error-detective`。
- 浏览器问题证据收集：`browser-debugger`。
- 安全漏洞：`security-auditor`、`penetration-tester`、`security-engineer`。
- 合规风险：`compliance-auditor`、`gdpr-ccpa-compliance`。
- 性能瓶颈：`performance-engineer`、`database-optimizer`。
- 数据库锁、迁移、慢查询：`database-optimizer`、`postgres-pro`。
- API 兼容性与合同破坏：`api-designer`。
- 架构合理性：`architect-reviewer`。
- 韧性和生产故障模式：`chaos-engineer`、`sre-engineer`。
- 构建、CI、打包、发布、回滚：`build-engineer`、`deployment-engineer`、`devops-engineer`。
- 容器、Kubernetes、IaC：`docker-expert`、`kubernetes-specialist`、`terraform-engineer`、`terragrunt-expert`。
- 依赖、许可证、供应链：`dependency-manager`、`license-engineer`、`security-auditor`。
- 无障碍与 UI/UX：`accessibility-tester`、`ui-ux-tester`。
- 测试策略 / 覆盖缺口：`qa-expert`、`test-automator`。
- LLM 输出质量、eval、prompt 回归：`eval-engineer`、`prompt-regression-tester`、`hallucination-investigator`。
- AI 治理、模型风险、误用风险：`ai-governance-auditor`、`model-risk-manager`、`responsible-ai-reviewer`。
- 技术文档真实性和质量：`documentation-engineer`、`api-documenter`、`content-quality-editor`、`ai-writing-auditor`。

Review 发现的问题由主 agent 汇总判断；只修与当前任务相关的问题，不做无关重构。

#### Verify 阶段

声称完成前必须运行最小必要验证，并说明验证结果。可根据项目选择测试、构建、lint、类型检查、脚本语法检查、容器构建、部署 dry-run、模型评估或更窄目标命令。

只看 diff 不算完成。如果无法验证，必须说明原因和剩余风险。

### 工作流 2：Just do it

在最小范围内由主 agent 直接执行。默认不 spawn subagents。

开始前仍需应用以下约束：

- 任务是 bug、测试失败或非预期行为时，先定位根因，再修复。必要时可在用户明确同意后使用 `debugger`、`error-detective` 或 `browser-debugger`。
- 修改测试或添加可测逻辑时，优先先写测试再写实现。必要时可在用户明确同意后使用 `test-automator` 或 `qa-expert`。
- 涉及安全、合规、支付、生产数据、部署或 AI 风险时，即使选择 Just do it，也要在完成前做对应最小 review。
- 声称完成前必须运行最小必要验证；无法验证时说明原因。
- 只在用户明确要求时 commit。

### Codex 适配边界

- 不使用 Claude 专用工具、插件命名空间或 skill 名称。
- 不使用 DeepSeek Harness 专用 `subagent_<role>` 工具名、Cordis preset、`agent.cordis.yml` 或 `tool-subagent` 术语；这些不是 Codex runtime 的接入点。
- custom agent 名称使用当前生效 `.toml` 中的 `name` 字段；文件名只作为简单约定，最终以 `name` 为准。
- Codex custom agent 定义由 `~/.codex/agents/*.toml` 和项目 `.codex/agents/*.toml` 提供；`AGENTS.md` 只负责工作流规则和路由偏好，不负责注册 agent。
- Codex 内置 agents 只有 `default`、`worker`、`explorer`。不要引用不存在的内置 agent。
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
