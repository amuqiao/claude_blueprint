<!-- WORKFLOW_START -->
## DeepSeek Harness Lite Expert Workflow

本文件用于在 DeepSeek Harness 中启用“专家角色精简模式”。它保留多 agent 协作流程，并只路由 lite preset 已注册的高频专家工具，避免把规则文件和工具目录扩成全量角色表。

DeepSeek Harness 的通用子 agent 能力来自当前 agent preset 暴露的工具，例如 `subagent`、`subagent_fork`、`list_agents`、`send_message`、`interrupt_agent` 和 `workflow`。当会话选择「专家角色精简模式」时，还会看到 `subagent_<role_name>` 形式的固定专家工具，例如 `subagent_api_designer`、`subagent_code_reviewer`、`subagent_typescript_pro`。

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

Plan 阶段默认由主 agent 完成。只在确有必要时使用少数辅助角色：

- 代码路径、入口、调用链、状态流梳理：`subagent_code_mapper` 或通用 `subagent` 的 explorer 角色。
- 架构权衡或边界评估：`subagent_architect_reviewer`。
- 外部文档/API 行为核验：`subagent_docs_researcher`。

#### Subagent 执行阶段

用户选择工作流 1 后，可以按任务领域派发 subagents。选择原则：

- 派发任何 subagent 时，prompt 开头必须明确说明：主会话的人类用户已选择工作流 1，当前 subagent 是被授权执行者，禁止再次询问工作流选择，禁止以“需要先选工作流”为由暂停任务。
- 独立、完整、无需继承当前上下文的任务，优先使用 `subagent` 或对应固定专家工具。
- 需要继承已完成对话上下文的 review、复核、延续分析，优先使用 `subagent_fork`。
- 多个互不依赖的子任务可以并行派发，但必须避免多个 agent 同时编辑同一文件或同一强耦合模块。
- 实现类 subagent 默认最多同时运行 2-3 个；只读探索、review、verify 可以适度增加并发。
- 每个 subagent prompt 必须包含角色、任务、边界、可编辑范围、输出格式和禁止事项。
- 固定专家工具命名规则是把角色名里的非字母数字字符转成下划线，并加 `subagent_` 前缀。例如 `api-designer` -> `subagent_api_designer`，`dotnet-core-expert` -> `subagent_dotnet_core_expert`。

常用执行路由：

- 前端框架：`subagent_react_specialist`、`subagent_vue_expert`、`subagent_angular_architect`、`subagent_nextjs_developer`。
- 前端实现与体验：`subagent_frontend_developer`、`subagent_ui_designer`、`subagent_ui_fixer`。
- 后端与 API：`subagent_backend_developer`、`subagent_fullstack_developer`、`subagent_api_designer`、`subagent_api_documenter`。
- TypeScript / JavaScript / Node.js：`subagent_typescript_pro`、`subagent_javascript_pro`、`subagent_node_specialist`。
- Python：`subagent_python_pro`、`subagent_fastapi_developer`、`subagent_django_developer`。
- 系统与强类型语言：`subagent_golang_pro`、`subagent_rust_engineer`、`subagent_java_architect`、`subagent_spring_boot_engineer`、`subagent_csharp_developer`、`subagent_dotnet_core_expert`。
- 数据库与数据工程：`subagent_sql_pro`、`subagent_postgres_pro`、`subagent_database_optimizer`、`subagent_data_engineer`。
- 架构与实时系统：`subagent_microservices_architect`、`subagent_graphql_architect`、`subagent_websocket_engineer`。
- 基础设施与发布：`subagent_docker_expert`、`subagent_kubernetes_specialist`、`subagent_terraform_engineer`、`subagent_deployment_engineer`、`subagent_devops_engineer`。
- AI / LLM / agent：`subagent_ai_engineer`、`subagent_llm_architect`、`subagent_prompt_engineer`、`subagent_mcp_developer`。
- 工程效率：`subagent_cli_developer`、`subagent_build_engineer`、`subagent_dependency_manager`、`subagent_refactoring_specialist`、`subagent_tooling_engineer`。
- 文档：`subagent_documentation_engineer`、`subagent_readme_generator`。

没有明确匹配的窄领域任务，优先用通用 `subagent` 并在 prompt 中写清角色，不要假设 lite preset 存在全量模式里的所有专家。

#### Review 阶段

实现完成后，必须按风险维度选择 review subagent。多维风险可以并行运行多个 reviewer。

常用 review 路由：

- 综合代码质量 / 可维护性：`subagent_code_reviewer`、`subagent_reviewer`。
- 正确性 / 行为回归 / 失败定位：`subagent_code_reviewer`、`subagent_debugger`、`subagent_error_detective`。
- 浏览器问题证据收集：`subagent_browser_debugger`。
- 安全漏洞：`subagent_security_auditor`、`subagent_penetration_tester`、`subagent_security_engineer`。
- 合规风险：`subagent_compliance_auditor`。
- 性能瓶颈：`subagent_performance_engineer`、`subagent_database_optimizer`。
- 数据库锁、迁移、慢查询：`subagent_database_optimizer`、`subagent_postgres_pro`。
- API 兼容性与合同破坏：`subagent_api_designer`。
- 架构合理性：`subagent_architect_reviewer`。
- 韧性和生产故障模式：`subagent_chaos_engineer`、`subagent_sre_engineer`。
- 构建、CI、打包、发布、回滚：`subagent_build_engineer`、`subagent_deployment_engineer`、`subagent_devops_engineer`。
- 容器、Kubernetes、IaC：`subagent_docker_expert`、`subagent_kubernetes_specialist`、`subagent_terraform_engineer`。
- 依赖、许可证、供应链：`subagent_dependency_manager`、`subagent_license_engineer`、`subagent_security_auditor`。
- 无障碍与 UI/UX：`subagent_accessibility_tester`、`subagent_ui_ux_tester`。
- 测试策略 / 覆盖缺口：`subagent_qa_expert`、`subagent_test_automator`。
- LLM 输出质量、eval、prompt 回归：`subagent_eval_engineer`、`subagent_prompt_engineer`。
- 技术文档真实性和质量：`subagent_documentation_engineer`、`subagent_api_documenter`。

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
- 不直接引用来源角色名，例如 `typescript-pro`、`code-reviewer`；在 lite preset 中应调用对应 Harness 工具名 `subagent_typescript_pro`、`subagent_code_reviewer`。
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
