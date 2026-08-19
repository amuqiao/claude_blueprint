<!-- WORKFLOW_START -->
## DeepSeek Harness Multi-Agent Workflow

本文件用于在 DeepSeek Harness 中启用“专家角色模式”。该模式注册 80 个高频固定专家工具，规则目标是固定协作流程，同时避免把完整 172 角色索引塞进 `AGENTS.md`。

DeepSeek Harness 的子 agent 能力来自当前 agent preset 暴露的工具，例如 `subagent`、`subagent_fork`、`list_agents`、`send_message`、`interrupt_agent` 和 `workflow`。当会话选择「专家角色模式」时，还会看到按 `subagent_<role_name>` 命名的固定专家工具，例如 `subagent_api_designer`、`subagent_code_reviewer`、`subagent_typescript_pro`。如果通用子 agent 工具不可见，应切换到标准模式、PTC 模式或固定角色 preset；如果固定专家工具不可见，应切换到「专家角色模式」并确认该 preset 已重新生成。

### 任务开始前必须选择工作流

任何代码任务开始前，必须先询问用户选择工作流。即使是单行修改、typo fix、显而易见的改动，也必须先问。

询问时输出以下内容，然后停止，等待用户回复后再进行任何代码相关操作：

```text
选择工作流：

1. plan -> subagent -> review -> verify（完整多 agent 流水线）
2. Just do it（直接执行，最后验证）

请回复 1 或 2。
```

用户回复 `1` 时，视为本任务已明确授权使用 DeepSeek Harness subagents / workflow。用户回复 `2` 时，不主动使用 subagents，除非用户后续明确要求。

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
- 编辑 `AGENTS.md`、`cordis.patch.yml`、settings、日报等元配置或元数据文件。
- 当前 session 已选过工作流，且仍是同一个连续任务。

### 工作流 1：plan -> subagent -> review -> verify

四阶段全部必须执行。

#### Plan 阶段

主 agent 先阅读上下文并制定计划。计划必须说明：

- 本任务需要哪些文件、模块、服务、配置或文档。
- 哪些工作适合交给 subagent 并行处理。
- 哪些工作必须由主 agent 在关键路径上完成。
- 预计派发哪些角色；如果存在对应 `subagent_<role_name>` 专家工具，优先使用该固定专家工具，否则用通用 `subagent` / `subagent_fork` 并在 prompt 中明确角色。

Plan 阶段默认由主 agent 完成。只在确有必要时派发少数只读探索角色。

#### Subagent 执行阶段

用户选择工作流 1 后，可以按任务领域派发 subagents。选择原则：

- 派发任何 subagent 时，prompt 开头必须明确说明：主会话的人类用户已选择工作流 1，当前 subagent 是被授权执行者，禁止再次询问工作流选择，禁止以“需要先选工作流”为由暂停任务。
- 独立、完整、无需继承当前上下文的任务，优先使用 `subagent`。
- 需要继承已完成对话上下文的 review、复核、延续分析，优先使用 `subagent_fork`。
- 长任务需要后续消息时，使用可后台运行的 `subagent`，并通过 `list_agents`、`send_message`、`interrupt_agent` 管理。
- 大量独立子任务、批量审查或多阶段 fan-out，且用户明确要求 workflow 时，使用 `workflow`。
- 多个互不依赖的子任务可以并行派发，但必须避免多个 agent 同时编辑同一文件或同一强耦合模块。
- 实现类 subagent 默认最多同时运行 2-3 个；只读探索、review、verify 可以适度增加并发。超过该范围时应分批派发，或在用户明确要求大规模编排时使用 `workflow`。
- 每个 subagent prompt 必须包含角色、任务、边界、可编辑范围、输出格式和禁止事项。
- 如果当前 preset 暴露了固定专家工具，命名规则是把角色名里的非字母数字字符转成下划线，并加 `subagent_` 前缀。例如 `api-designer` -> `subagent_api_designer`，`dotnet-framework-4.8-expert` -> `subagent_dotnet_framework_4_8_expert`。

常用角色模板：

- `explorer`：只读探索代码路径、入口、调用链、配置、影响面，不修改文件。
- `worker`：在明确文件范围内实现或修复，不修改无关文件，不覆盖他人改动。
- `reviewer`：按风险找问题，优先输出阻断项和文件位置，不做无关重构。
- `verifier`：运行最小必要验证，记录命令、结果和剩余风险。
- `domain-specialist`：按任务领域设定专家身份，例如 TypeScript、React、Python、API、数据库、安全、性能、AI/LLM、文档等。

固定专家工具的使用原则：

- 有明确匹配时，优先调用固定专家工具，例如 API 合同设计用 `subagent_api_designer`，代码审查用 `subagent_code_reviewer`，安全审查用 `subagent_security_auditor`。
- 没有明确匹配时，用通用 `subagent` 并在 prompt 中写清角色。
- 固定专家工具只固定 persona 和工具名，不代表可以跳过任务边界说明；仍需在 prompt 中写清输入、范围、禁止事项和输出格式。
- 不要在 `AGENTS.md` 中展开全部专家说明；本模式的 80 个固定专家由 `voltagent-roles/ROLE_ALLOWLIST.txt` 决定，生成后的完整映射表由 preset 目录里的 `agent-role-map.md` 保存。

#### Review 阶段

实现完成后，必须按风险维度选择 review subagent。多维风险可以并行运行多个 reviewer。

常用 review 维度：

- 代码质量 / 可维护性。
- 正确性 / 行为回归。
- 安全漏洞。
- 合规风险。
- 性能瓶颈。
- 架构边界。
- API 合同兼容性。
- 数据库迁移、锁、慢查询。
- 构建、CI、打包、发布风险。
- UI/UX 与无障碍。
- 测试策略和覆盖缺口。
- LLM 输出质量、eval、prompt 回归、模型风险。
- 技术文档真实性和可操作性。

Review 发现的问题由主 agent 汇总判断；只修与当前任务相关的问题，不做无关重构。

#### Verify 阶段

声称完成前必须运行最小必要验证，并说明验证结果。可根据项目选择测试、构建、lint、类型检查、脚本语法检查、容器构建、部署 dry-run、模型评估或更窄目标命令。

只看 diff 不算完成。如果无法验证，必须说明原因和剩余风险。

### 工作流 2：Just do it

在最小范围内由主 agent 直接执行。默认不 spawn subagents。

开始前仍需应用以下约束：

- 任务是 bug、测试失败或非预期行为时，先定位根因，再修复。
- 修改测试或添加可测逻辑时，优先先写测试再写实现。
- 涉及安全、合规、支付、生产数据、部署或 AI 风险时，即使选择 Just do it，也要在完成前做对应最小 review。
- 声称完成前必须运行最小必要验证；无法验证时说明原因。
- 只在用户明确要求时 commit。

### DeepSeek Harness 适配边界

- 不在 Harness runtime 中直接使用 Codex 专用 `.codex/agents/*.toml`、Claude 插件命名空间或 VoltAgent namespace；如需复用这些角色定义，必须先整理为 Harness agent preset，并通过 `tool-subagent` + `persona` 暴露成 Harness 工具。
- 不把“替换 LLM URL”当作多 agent 适配；多 agent 能力必须来自 DeepSeek Harness runtime 暴露的工具。
- 不直接引用来源角色名，例如 `typescript-pro`、`code-reviewer`；在 `voltagent-roles` preset 中应调用对应 Harness 工具名 `subagent_typescript_pro`、`subagent_code_reviewer`。
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
