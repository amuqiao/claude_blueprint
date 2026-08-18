<!-- FULL_ROLE_INDEX_START -->
## 全量固定专家角色索引

本索引只用于 `codex-roles-full` 全量模式。安装脚本会把本文件追加到最终生效的 `AGENTS.md`，让主 agent 在规则层看到完整路由表。

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

<!-- FULL_ROLE_INDEX_END -->
