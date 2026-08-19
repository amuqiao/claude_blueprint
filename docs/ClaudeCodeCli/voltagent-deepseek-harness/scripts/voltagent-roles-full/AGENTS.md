<!-- WORKFLOW_START -->
## DeepSeek Harness Multi-Agent Workflow

本文件用于在 DeepSeek Harness 中复现多 agent 协作工作流。规则目标是固定协作流程；如果当前会话使用带固定角色工具的 preset，还可以调用 `subagent_<role>` 形式的专家子 agent 工具。

DeepSeek Harness 的子 agent 能力来自当前 agent preset 暴露的工具，例如 `subagent`、`subagent_fork`、`list_agents`、`send_message`、`interrupt_agent` 和 `workflow`。如果使用 `voltagent-roles-full` 这类固定角色 preset，还会看到按 `subagent_<role_name>` 命名的专家工具，例如 `subagent_api_designer`、`subagent_code_reviewer`、`subagent_typescript_pro`。如果通用子 agent 工具不可见，应切换到标准模式、PTC 模式或固定角色 preset；如果固定专家工具不可见，应切换到「专家角色全量模式」。

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
- 本全量模式要求所有生成的固定专家角色都可被主 agent 主动路由；完整路由表直接维护在本 `AGENTS.md` 的“全量固定专家角色索引”中。
- 路由时优先参考下方“全量固定专家角色索引”。索引中没有精确命中的场景，再使用通用 `subagent` 并在 prompt 中写清角色。

#### 全量固定专家角色索引

调用原则：

- 需要专家角色时，优先从下表选择语义最匹配的 `subagent_*` 工具。
- 不要只因为工具存在就派发；仍然必须遵守工作流 1 的授权、并发和文件边界规则。
- 一个任务跨多个领域时，优先选择最能降低风险的 1-3 个角色，不要一次派发大量专家。

| 来源角色 | Harness 工具 | 适用场景 |
|---|---|---|
| `api-designer` | `subagent_api_designer` | API contract design, evolution planning, or compatibility review. |
| `backend-developer` | `subagent_backend_developer` | Scoped backend implementation or backend bug fixes. |
| `code-mapper` | `subagent_code_mapper` | Map code paths, ownership boundaries, and execution flow. |
| `design-bridge` | `subagent_design_bridge` | Translate DESIGN.md into implementation-ready UI instructions. |
| `electron-pro` | `subagent_electron_pro` | Electron implementation, debugging, packaging, and runtime behavior. |
| `frontend-developer` | `subagent_frontend_developer` | Scoped frontend implementation or UI bug fixes. |
| `fullstack-developer` | `subagent_fullstack_developer` | One bounded feature or bug spanning frontend and backend. |
| `graphql-architect` | `subagent_graphql_architect` | GraphQL schema evolution, resolver architecture, federation, performance, or security. |
| `microservices-architect` | `subagent_microservices_architect` | Service boundaries, inter-service contracts, or distributed-system architecture. |
| `mobile-developer` | `subagent_mobile_developer` | Mobile implementation/debugging across lifecycle, APIs, and platform UX. |
| `ui-designer` | `subagent_ui_designer` | Concrete UI decisions, interaction design, and implementation-ready guidance. |
| `ui-fixer` | `subagent_ui_fixer` | Smallest safe patch for an already reproduced UI issue. |
| `websocket-engineer` | `subagent_websocket_engineer` | WebSocket lifecycle, message contracts, reconnects, and real-time state. |
| `angular-architect` | `subagent_angular_architect` | Angular architecture, dependency injection, routing, signals, and enterprise structure. |
| `cpp-pro` | `subagent_cpp_pro` | C++ performance, memory ownership, concurrency, or systems integration. |
| `csharp-developer` | `subagent_csharp_developer` | C#/.NET services, APIs, async flows, or application architecture. |
| `django-developer` | `subagent_django_developer` | Django models, views, forms, ORM, admin, or middleware. |
| `dotnet-core-expert` | `subagent_dotnet_core_expert` | Modern .NET / ASP.NET Core APIs, hosting, middleware, or cross-platform behavior. |
| `dotnet-framework-4.8-expert` | `subagent_dotnet_framework_4_8_expert` | Legacy .NET Framework 4.8 compatibility and Windows-bound integrations. |
| `elixir-expert` | `subagent_elixir_expert` | Elixir/OTP processes, supervision, fault tolerance, or Phoenix behavior. |
| `erlang-expert` | `subagent_erlang_expert` | Erlang/OTP, rebar3, releases, upgrades, or distributed runtime behavior. |
| `expo-react-native-expert` | `subagent_expo_react_native_expert` | Expo / React Native navigation, native modules, performance, or EAS builds. |
| `fastapi-developer` | `subagent_fastapi_developer` | FastAPI async endpoints, Pydantic contracts, dependencies, or ASGI behavior. |
| `flutter-expert` | `subagent_flutter_expert` | Flutter widgets, state, rendering, or cross-platform mobile behavior. |
| `golang-pro` | `subagent_golang_pro` | Go concurrency, services, interfaces, tooling, or performance paths. |
| `java-architect` | `subagent_java_architect` | Java architecture, JVM behavior, or large service structure. |
| `javascript-pro` | `subagent_javascript_pro` | JavaScript runtime behavior in browser or Node. |
| `kotlin-specialist` | `subagent_kotlin_specialist` | Kotlin JVM/Android applications, coroutines, or typed service logic. |
| `laravel-specialist` | `subagent_laravel_specialist` | Laravel routing, Eloquent, queues, validation, or application structure. |
| `nextjs-developer` | `subagent_nextjs_developer` | Next.js routing, rendering modes, server actions, data fetching, or deployment behavior. |
| `node-specialist` | `subagent_node_specialist` | Node APIs, CLIs, workers, streams, and event-loop behavior. |
| `php-pro` | `subagent_php_pro` | PHP application logic, framework integration, or runtime debugging. |
| `powershell-5.1-expert` | `subagent_powershell_5_1_expert` | Windows PowerShell 5.1 legacy automation and .NET Framework interop. |
| `powershell-7-expert` | `subagent_powershell_7_expert` | PowerShell 7 cross-platform automation and scripting. |
| `python-pro` | `subagent_python_pro` | Python runtime behavior, packaging, typing, testing, or framework-adjacent work. |
| `rails-expert` | `subagent_rails_expert` | Rails models, controllers, jobs, callbacks, or convention-driven changes. |
| `react-specialist` | `subagent_react_specialist` | React component behavior, state flow, rendering bugs, or modern patterns. |
| `rust-engineer` | `subagent_rust_engineer` | Rust ownership-heavy systems, async runtime, or performance-sensitive implementation. |
| `spring-boot-engineer` | `subagent_spring_boot_engineer` | Spring Boot services, configuration, data access, or enterprise APIs. |
| `sql-pro` | `subagent_sql_pro` | SQL query design, query review, schema-aware debugging, or migrations. |
| `swift-expert` | `subagent_swift_expert` | Swift iOS/macOS code, async flows, Apple APIs, or typed app logic. |
| `symfony-specialist` | `subagent_symfony_specialist` | Symfony routing, controllers, services, Doctrine, or security. |
| `typescript-pro` | `subagent_typescript_pro` | TypeScript types, interfaces, refactors, or compiler-driven fixes. |
| `vue-expert` | `subagent_vue_expert` | Vue components, Composition API, routing, state, or rendering issues. |
| `azure-infra-engineer` | `subagent_azure_infra_engineer` | Azure resources, networking, identity, or automation. |
| `cloud-architect` | `subagent_cloud_architect` | Cloud compute, storage, networking, reliability, or multi-service design. |
| `database-administrator` | `subagent_database_administrator` | Database operations, availability, backups, recovery, permissions, or health. |
| `deployment-engineer` | `subagent_deployment_engineer` | Deployment workflows, release strategy, rollout, and rollback safety. |
| `devops-engineer` | `subagent_devops_engineer` | CI, deployment pipelines, release automation, or environment configuration. |
| `devops-incident-responder` | `subagent_devops_incident_responder` | Operational triage across CI, deployments, infrastructure, and delivery failures. |
| `docker-expert` | `subagent_docker_expert` | Dockerfile review, image optimization, multi-stage builds, or container debugging. |
| `incident-responder` | `subagent_incident_responder` | Production incident triage, containment planning, and root cause evidence. |
| `kubernetes-specialist` | `subagent_kubernetes_specialist` | Kubernetes manifests, rollout safety, or workload debugging. |
| `network-engineer` | `subagent_network_engineer` | Network paths, connectivity, load balancers, or infrastructure network design. |
| `platform-engineer` | `subagent_platform_engineer` | Internal platform, golden path, or developer self-service infrastructure. |
| `security-engineer` | `subagent_security_engineer` | IAM, secrets, network controls, infrastructure security, or hardening. |
| `sre-engineer` | `subagent_sre_engineer` | SLOs, alerting, error budgets, operational safety, or resilience. |
| `terraform-engineer` | `subagent_terraform_engineer` | Terraform modules, plan review, state-aware changes, or IaC refactoring. |
| `terragrunt-expert` | `subagent_terragrunt_expert` | Terragrunt module orchestration, environment layering, dependencies, or DRY structure. |
| `windows-infra-admin` | `subagent_windows_infra_admin` | Windows infrastructure, Active Directory, DNS, DHCP, GPO, or automation. |
| `accessibility-tester` | `subagent_accessibility_tester` | Accessibility audit of UI changes, interaction flows, or components. |
| `ad-security-reviewer` | `subagent_ad_security_reviewer` | Active Directory security across identity, delegation, GPO, and hardening. |
| `ai-writing-auditor` | `subagent_ai_writing_auditor` | Check and rewrite prose to remove AI writing patterns. |
| `architect-reviewer` | `subagent_architect_reviewer` | Coupling, boundaries, maintainability, and architectural coherence. |
| `browser-debugger` | `subagent_browser_debugger` | Browser reproduction, UI evidence, or client-side debugging through browser MCP. |
| `chaos-engineer` | `subagent_chaos_engineer` | Resilience analysis, dependency failures, degraded modes, and fault injection. |
| `code-reviewer` | `subagent_code_reviewer` | Code health, maintainability, design clarity, correctness, and risky choices. |
| `compliance-auditor` | `subagent_compliance_auditor` | Compliance controls, auditability, policy alignment, or evidence gaps. |
| `debugger` | `subagent_debugger` | Deep bug isolation across code paths, stack traces, runtime, or failing tests. |
| `error-detective` | `subagent_error_detective` | Log, exception, or stack trace analysis for probable failure source. |
| `gdpr-ccpa-compliance` | `subagent_gdpr_ccpa_compliance` | GDPR/CCPA review of data practices, consent, and data-subject rights. |
| `penetration-tester` | `subagent_penetration_tester` | Adversarial review for exploitability, abuse cases, or attack surface. |
| `performance-engineer` | `subagent_performance_engineer` | Slow requests, hot paths, rendering regressions, or scalability bottlenecks. |
| `powershell-security-hardening` | `subagent_powershell_security_hardening` | PowerShell script safety, admin automation, execution controls, or Windows security. |
| `qa-expert` | `subagent_qa_expert` | Test strategy, acceptance coverage, or risk-based QA guidance. |
| `reviewer` | `subagent_reviewer` | PR-style review focused on correctness, security, regressions, and missing tests. |
| `security-auditor` | `subagent_security_auditor` | Code security, auth, secrets, input validation, or infrastructure configuration. |
| `test-automator` | `subagent_test_automator` | Automated tests, test harness improvements, or regression coverage. |
| `ui-ux-tester` | `subagent_ui_ux_tester` | UI/UX functional testing driven by documented user flows. |
| `ai-engineer` | `subagent_ai_engineer` | Model-backed application features, agent flows, or evaluation hooks. |
| `data-analyst` | `subagent_data_analyst` | Data interpretation, metrics, trends, or analytics decision support. |
| `data-engineer` | `subagent_data_engineer` | ETL, ingestion, transformation, warehouse, or data pipelines. |
| `data-scientist` | `subagent_data_scientist` | Statistical reasoning, experiments, features, or model-oriented data exploration. |
| `database-optimizer` | `subagent_database_optimizer` | Query plans, schema design, indexing, or data access performance. |
| `llm-architect` | `subagent_llm_architect` | Prompts, tool use, retrieval, evaluation, or multi-step LLM workflows. |
| `machine-learning-engineer` | `subagent_machine_learning_engineer` | ML training pipelines, feature flow, serving, or inference integration. |
| `ml-engineer` | `subagent_ml_engineer` | Practical ML implementation, feature engineering, inference, or model-backed logic. |
| `mlops-engineer` | `subagent_mlops_engineer` | Model deployment, registry, pipelines, monitoring, or ML environments. |
| `nlp-engineer` | `subagent_nlp_engineer` | NLP text processing, embeddings, ranking, or language-model pipelines. |
| `postgres-pro` | `subagent_postgres_pro` | PostgreSQL schema design, performance, locking, or operational features. |
| `prompt-engineer` | `subagent_prompt_engineer` | Prompt revision, instruction design, eval comparison, or output contract tightening. |
| `reinforcement-learning-engineer` | `subagent_reinforcement_learning_engineer` | RL environments, policies, rewards, or decision-making agents. |
| `build-engineer` | `subagent_build_engineer` | Build graph debugging, bundling, compiler pipelines, or CI build stabilization. |
| `cli-developer` | `subagent_cli_developer` | CLI features, UX, argument parsing, or shell-facing workflows. |
| `dependency-manager` | `subagent_dependency_manager` | Dependency upgrades, package graph analysis, version policy, or third-party risk. |
| `documentation-engineer` | `subagent_documentation_engineer` | Technical docs faithful to current code, tooling, and operator workflows. |
| `dx-optimizer` | `subagent_dx_optimizer` | Developer experience, setup time, local workflows, feedback loops, or tooling friction. |
| `git-workflow-manager` | `subagent_git_workflow_manager` | Branching strategy, merge flow, release branching, or repository collaboration. |
| `legacy-modernizer` | `subagent_legacy_modernizer` | Modernization paths for older code, frameworks, or architecture. |
| `mcp-developer` | `subagent_mcp_developer` | MCP servers, clients, tool wiring, or protocol-aware integrations. |
| `powershell-module-architect` | `subagent_powershell_module_architect` | PowerShell module structure, command design, packaging, or profile architecture. |
| `powershell-ui-architect` | `subagent_powershell_ui_architect` | PowerShell UI for terminals, forms, WPF, or admin tooling. |
| `readme-generator` | `subagent_readme_generator` | Maintainer-ready README grounded in exact repository reality. |
| `refactoring-specialist` | `subagent_refactoring_specialist` | Low-risk structural refactors that preserve behavior. |
| `slack-expert` | `subagent_slack_expert` | Slack bots, interactivity, events, workflows, or platform integrations. |
| `tooling-engineer` | `subagent_tooling_engineer` | Internal tooling, scripts, automation glue, or workflow support utilities. |
| `visual-asset-generator` | `subagent_visual_asset_generator` | Production visual assets such as icons, favicons, OG images, logos, or wordmarks. |
| `api-documenter` | `subagent_api_documenter` | Consumer-facing API docs from real implementation, schema, and examples. |
| `blockchain-developer` | `subagent_blockchain_developer` | Blockchain/Web3 implementation, smart contracts, wallets, or transaction lifecycle. |
| `embedded-systems` | `subagent_embedded_systems` | Embedded or hardware-adjacent firmware, timing, or low-level integration. |
| `fintech-engineer` | `subagent_fintech_engineer` | Ledgers, reconciliation, transfers, settlement, or compliance-sensitive transactions. |
| `game-developer` | `subagent_game_developer` | Gameplay systems, rendering loops, asset flow, or player-state behavior. |
| `healthcare-admin` | `subagent_healthcare_admin` | Healthcare administration, coding, payer analysis, operations, or interoperability. |
| `hipaa-compliance` | `subagent_hipaa_compliance` | HIPAA scope, BAA, PHI handling, safeguards, or breach response. |
| `iot-engineer` | `subagent_iot_engineer` | IoT devices, telemetry, edge communication, or cloud-device coordination. |
| `m365-admin` | `subagent_m365_admin` | Microsoft 365 administration across Exchange, Teams, SharePoint, or identity. |
| `mobile-app-developer` | `subagent_mobile_app_developer` | Mobile product screens, state, API integration, and release-sensitive behavior. |
| `payment-integration` | `subagent_payment_integration` | Checkout, idempotency, webhooks, retries, or settlement state. |
| `quant-analyst` | `subagent_quant_analyst` | Quantitative models, strategies, simulations, or numeric decision logic. |
| `risk-manager` | `subagent_risk_manager` | Product, operational, financial, or architectural risk analysis. |
| `seo-specialist` | `subagent_seo_specialist` | Crawlability, metadata, rendering, information architecture, or discoverability. |
| `assumption-mapping` | `subagent_assumption_mapping` | Surface and prioritize risky assumptions before engineering investment. |
| `backlog-grooming` | `subagent_backlog_grooming` | Product backlog refinement, sprint readiness, estimation, and cleanup. |
| `business-analyst` | `subagent_business_analyst` | Requirements clarification, scope normalization, or acceptance criteria. |
| `content-marketer` | `subagent_content_marketer` | Product-adjacent content strategy grounded in technical capabilities. |
| `content-quality-editor` | `subagent_content_quality_editor` | Final quality pass for AI-generated posts, docs, release notes, or PR text. |
| `customer-success-manager` | `subagent_customer_success_manager` | Support pattern synthesis, adoption risk, or customer-facing guidance. |
| `growth-loops` | `subagent_growth_loops` | Growth loops, PLG mechanics, or acquisition compounding analysis. |
| `legal-advisor` | `subagent_legal_advisor` | Legal-risk spotting around terms, data handling, or visible commitments. |
| `license-engineer` | `subagent_license_engineer` | License selection, dependency compliance, dual licensing, or liability risk. |
| `product-manager` | `subagent_product_manager` | Product framing, prioritization, or feature shaping. |
| `project-manager` | `subagent_project_manager` | Dependency mapping, milestones, sequencing, or delivery-risk coordination. |
| `sales-engineer` | `subagent_sales_engineer` | Technical solution positioning and pre-sales implementation tradeoffs. |
| `scrum-master` | `subagent_scrum_master` | Process facilitation, iteration planning, or workflow friction analysis. |
| `technical-writer` | `subagent_technical_writer` | Release notes, migration notes, onboarding, or developer-facing prose. |
| `ux-researcher` | `subagent_ux_researcher` | UI feedback synthesized into product and implementation guidance. |
| `wordpress-master` | `subagent_wordpress_master` | WordPress themes, plugins, content architecture, or operational debugging. |
| `agent-installer` | `subagent_agent_installer` | Selecting, copying, or organizing custom agent files from this repository. |
| `agent-organizer` | `subagent_agent_organizer` | Choosing subagents and dividing a larger task into delegated threads. |
| `codebase-orchestrator` | `subagent_codebase_orchestrator` | Repository-wide refactor governance, diff previews, and approval gates. |
| `context-manager` | `subagent_context_manager` | Compact project context summary for other subagents. |
| `error-coordinator` | `subagent_error_coordinator` | Group, prioritize, and assign multiple errors or symptoms. |
| `it-ops-orchestrator` | `subagent_it_ops_orchestrator` | Coordinated operational planning across infrastructure, incidents, identity, and admin. |
| `knowledge-synthesizer` | `subagent_knowledge_synthesizer` | Distill findings from multiple agents into non-redundant synthesis. |
| `multi-agent-coordinator` | `subagent_multi_agent_coordinator` | Multi-agent plan with role separation, dependencies, and integration. |
| `performance-monitor` | `subagent_performance_monitor` | Ongoing performance-signal interpretation before deeper optimization. |
| `task-distributor` | `subagent_task_distributor` | Break broad tasks into concrete sub-tasks for multiple agents/contributors. |
| `workflow-orchestrator` | `subagent_workflow_orchestrator` | Explicit Codex subagent workflow for complex multi-stage tasks. |
| `ab-test-analysis` | `subagent_ab_test_analysis` | A/B test analysis, p-values, confidence intervals, and ship/no-ship decisions. |
| `cohort-analysis` | `subagent_cohort_analysis` | Retention analysis, cohort comparison, activation metrics, or user group behavior. |
| `competitive-analyst` | `subagent_competitive_analyst` | Grounded comparison of tools, products, libraries, or implementation options. |
| `data-researcher` | `subagent_data_researcher` | Source gathering and synthesis around datasets, metrics, or quantitative questions. |
| `docs-researcher` | `subagent_docs_researcher` | Documentation-backed verification of APIs, versions, or framework behavior. |
| `first-principles-thinking` | `subagent_first_principles_thinking` | Challenge assumptions and rebuild a solution from fundamentals. |
| `market-researcher` | `subagent_market_researcher` | Market landscape, positioning, or demand-side research for a technical product. |
| `project-idea-validator` | `subagent_project_idea_validator` | Pressure-test ideas, competitor teardown, market validation, and fatal-flaw hunting. |
| `research-analyst` | `subagent_research_analyst` | Structured investigation of a technical topic, approach, or design question. |
| `scientific-literature-researcher` | `subagent_scientific_literature_researcher` | Evidence-grounded answers from published research. |
| `search-specialist` | `subagent_search_specialist` | Fast codebase or external searching before deeper analysis. |
| `trend-analyst` | `subagent_trend_analyst` | Trend synthesis across technology shifts, adoption, or emerging implementation directions. |
| `ai-governance-auditor` | `subagent_ai_governance_auditor` | AI governance controls, accountability, risk ownership, and deployment readiness. |
| `model-risk-manager` | `subagent_model_risk_manager` | Model risk analysis, failure modes, and mitigation planning. |
| `policy-guardrail-designer` | `subagent_policy_guardrail_designer` | Enforceable prompt, tool, workflow, or approval guardrails. |
| `responsible-ai-reviewer` | `subagent_responsible_ai_reviewer` | Fairness, transparency, misuse risk, and human oversight in AI features. |
| `backstage-specialist` | `subagent_backstage_specialist` | Backstage catalog, plugins, templates, or internal platform adoption. |
| `golden-path-designer` | `subagent_golden_path_designer` | Opinionated golden path for service creation, deployment, or operations. |
| `idp-architect` | `subagent_idp_architect` | Internal developer platform architecture and self-service control plane. |
| `platform-product-manager` | `subagent_platform_product_manager` | Platform roadmap, adoption strategy, metrics, and stakeholder alignment. |
| `ai-observability-engineer` | `subagent_ai_observability_engineer` | AI-native traces, metrics, logs, and debugging signals. |
| `eval-engineer` | `subagent_eval_engineer` | Evaluation design for prompts, retrieval, tools, or agent workflows. |
| `hallucination-investigator` | `subagent_hallucination_investigator` | Root cause analysis for factuality failures or unsupported claims. |
| `prompt-regression-tester` | `subagent_prompt_regression_tester` | Regression coverage for prompt, model, tool, or workflow changes. |

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
- 不直接引用来源角色名，例如 `typescript-pro`、`code-reviewer`；在 `voltagent-roles-full` preset 中应调用对应 Harness 工具名 `subagent_typescript_pro`、`subagent_code_reviewer`。
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
