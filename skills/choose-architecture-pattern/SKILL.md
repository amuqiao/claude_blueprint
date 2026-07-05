---
name: choose-architecture-pattern
description: >-
  Use when choosing or reviewing a software architecture or design pattern for a feature: translating vague requirements into the real problem, naming the mature pattern behind a described effect, enumerating candidate solutions (patterns, technologies, libraries) with their trade-offs, giving a reasoned recommendation, and checking production readiness across failure modes. Triggers on architecture or design-pattern decisions, technology/library/stack selection, "what is this effect called" pattern-naming, state management, data consistency/idempotency, async/queue/retry reliability, API contracts, auth boundaries, caching, offline-first, SSR/hydration, background workers, and frontend/backend seams (Flutter/mobile, frontend/web, Python/backend, full-stack). 适用于架构选型、技术栈/库选型、把描述性效果映射到有名字的成熟模式、枚举可选候选方案、状态管理、数据一致性、异步可靠性、离线优先、全栈接缝设计与生产落地审查。Do not use for pure bug fixes, mechanical refactors, or implementation where no architecture/pattern boundary or production trade-off is in question.
---

# Choose Architecture Pattern

在涉及架构判断、技术选型或生产可靠性的问题上，先用本 skill 放慢决策速度。核心定位是「需求翻译器 + 模式命名器 + 候选枚举器 + 生产落地审查器」，不是只给结论的方案选择器。目标是先把自然语言诉求翻译成工程真实需求，把描述性效果映射到有名字的成熟模式（给出业界叫法与可搜索关键词），再枚举可选候选方案（模式 / 技术栈 / 库）并对照场景约束，最后给出**带理由的推荐 + 可落地可运维的最小方案**，避免过早自定义机制或重复造轮子。

关键原则：**推荐与枚举并存，不做盲盒决策**。始终同时交付①一个带理由的推荐方案 + 最小可信落地路径，②可枚举的候选清单（每个候选标注 canonical name、成熟度、适用边界、坑、采用者），把最终决策权交还用户。只给单一结论、不摊开可选项，等同于把选型变成模型盲盒，是被禁止的。

本 skill 要对抗三个常见病症：

- 病 A：把"用户提出的实现手段"误当成"需求"。
- 病 B：把"happy path 能跑"误当成"生产架构合理"。
- 病 C：用户能描述效果但不知道它叫什么，于是自己手写造轮子；或只给单一结论、不给可枚举候选，把选型变成盲盒。

不要用于纯 bug 修复、机械重构，或不涉及任何架构/模式边界与生产权衡的实现工作。

## Workflow

1. 翻译需求：区分"表面诉求 / 用户提出的实现 / 真实需求 / 不在解决的问题"四层。
2. 明确关键假设：列出当前判断依赖的事实，例如一致性级别、失败代价、吞吐量、延迟、团队运维能力、现有技术栈。
3. 判断是否需要先澄清（闸门）：如果缺失信息会改变架构边界，或涉及资金、权限、合规、数据丢失、用户可见状态、不可逆操作，先向用户提出 1-3 个带"推荐默认项"的选择题；如果不阻塞，先继续但显式标注假设。详见 `references/decision-rubric.md`。
4. 识别项目类型 + 问题维度，按需加载对应模式库。见下方 "Project Type Routing"。
5. 命名（关键步骤）：把用户描述的效果/诉求映射到有名字的成熟模式，读已加载的 `patterns-*.md`。给出该效果/模式在业界的所有通用叫法（英文为主，含平台官方命名与社区俗称）、最典型出处（哪个产品或设计规范），以及 3-5 个可直接搜索的英文关键词。常见问题优先用已知模式，而不是从零发明——用户不知道名字不等于没有成熟实现。
6. 枚举候选（不是简单比较）：列出实现该模式的可选候选方案（模式 / 技术栈 / 库都算），官方 API 优先，其次高星社区库。每个候选标注：canonical name、成熟度（维护状态 / star 量级 / 最近更新）、适用边界、已知坑、哪些知名产品在用。除非用户只问一个极窄问题，否则至少枚举两个候选，说明各自适用边界而不只列优缺点。
7. 分析失败模式：部分失败、重试、重复请求/消息、并发竞争、陈旧数据、一致性缺口、运维恢复、安全滥用、可观测性缺口。对照 `references/anti-patterns.md`。
8. 给出推荐 + 保留枚举，不做盲盒决策：明确推荐一个方案，说明为什么推荐、成立前提是什么、不建议采用什么；同时保留第 6 步的可枚举候选清单，让用户能自己复核和改选。禁止只丢一个结论而不摊开可选项。
9. 给出最小的生产可信落地路径。避免过度设计，但不能隐藏关键可靠性要求。
10. 列出实施前必须验证的事实。如果信息可能过时，或依赖具体生态/云服务/库版本，先查权威来源。

## Project Type Routing

第 4 步分两层执行。

第一层 — 识别项目类型，决定加载哪个模式库（通常只读一个）：

| 信号 | 项目类型 | 加载 |
| --- | --- | --- |
| Flutter / Dart / 跨端移动 app / 离线 / 本地持久化 / app 生命周期 | Flutter/跨端移动 | `references/patterns-flutter.md` |
| SwiftUI / Swift / iOS·macOS 原生 / property wrapper / @Observable / Swift Concurrency / SwiftData·Core Data / CloudKit | SwiftUI/iOS 原生 | `references/patterns-swiftui.md` |
| React / Vue / 浏览器 / SSR / 水合 / 表单 / server-state 缓存 / 路由 URL 状态 | 前端/Web | `references/patterns-frontend.md` |
| FastAPI / Django / 服务端 / 队列 / worker / DB 一致性 / webhook / 迁移 | 后端（模式通用，示例为 Python） | `references/patterns-python-backend.md` |
| 同时跨前后端 / 端到端类型 / 契约 / auth 边界 / 前后端数据流 | 全栈/接缝 | `references/patterns-fullstack.md`（再按需交叉读 frontend + python-backend） |

跨界与边界说明：

- 非 Python 后端（Node / Go / Java 等）：`patterns-python-backend.md` 里的通用分布式模式（outbox、idempotent consumer、saga、幂等键、expand-contract 迁移等）仍然适用，忽略其中 Python 专属实现注解（structlog / SQLAlchemy / ASGI / Celery 等）即可。
- 移动端分流：跨端框架（React Native / Flutter）走 `patterns-flutter.md`（声明式跨端的状态/离线/生命周期模式通用，忽略 Dart 专属 API）；**原生 SwiftUI / iOS·macOS 走 `patterns-swiftui.md`**——原生的状态所有权（property wrapper / @Observable）、导航（NavigationStack）、并发（Swift Concurrency / actor）模型与跨端不同，不要用 Flutter 包硬套。iOS 后台执行限制两包结论一致，可交叉参考。
- Web PWA 离线：以 `patterns-frontend.md` 为主，离线持久化与冲突解决可交叉读 `patterns-flutter.md` 的离线小节。

第二层 — 在选定包内按问题维度归类。统一维度词表：`状态 / 数据一致性 / 异步可靠性 / API 合同 / 安全访问 / 可观测运维`。各包按相关性取这个词表的子集；包内 `##` 小节标题是该维度针对具体 stack 的特化展开（可能更细分或换用 stack 习惯说法），按语义对回上述维度即可，不要求字面一致。

加载规则：

- 单一 stack → 只读对应一个包。
- 全栈任务 → 读 `patterns-fullstack.md`，它会指引按需再读 frontend / python-backend。
- 多个 stack 都不确定 → 先走第 3 步澄清闸门确认项目类型，再加载。
- 按需加载，不要一次把 4 个包都读进来。

## Clarification Rules

不要默认直接裁决。先判断用户是在要"结论"，还是需要"把需求翻译成成熟模式"。澄清时要枚举可选项并标注推荐项，不要只问开放问题。完整规则见 `references/decision-rubric.md`。

必须先澄清的情况：

- 用户的目标、失败代价或一致性等级不清楚，且不同答案会导致不同架构。
- 需求可能涉及资金、权限、合规、数据丢失、用户可见状态或不可逆操作。
- 用户把某个实现方式当成需求，但看起来可能不是最合适的生产模式。
- 需要选择会显著增加运维面的基础设施，例如队列、分布式锁、事件总线、工作流引擎、CDC、搜索集群、离线同步引擎。

可以不阻塞、继续给建议的情况：

- 关键假设可以安全声明，且推荐方案在这些假设下明显成立。
- 用户明确要求先给判断或方案草案。
- 问题是窄范围解释，不涉及实施决策。

## Decision Criteria

当问题常见、失败代价高、涉及用户状态/资金/权限/数据丢失/合规，或需要可运维恢复时，优先采用成熟模式。

当范围很小、单进程或同步、失败能直接暴露给调用方，或成熟模式带来的运维成本超过风险时，优先采用更简单的本地设计。

不要把"happy path 能跑"当成生产架构合理；必须考虑重试、崩溃、并发请求、重复消息、部署重启和外部服务部分失败下的正确性。不要把用户提出的机制直接当成需求——先问：它真正要保护什么事实？要避免什么失败？谁要恢复？恢复依据在哪里？详见 `references/decision-rubric.md` 与 `references/anti-patterns.md`。

选型（架构 / 技术栈 / 库）必须「推荐 + 枚举」并存，不做盲盒决策：给出带理由的首选，同时摊开可枚举候选（每个带 canonical name、成熟度、适用边界、坑、采用者），决策权归用户。用户能描述效果但说不出名字时，先完成命名（业界叫法 + 可搜索关键词），再枚举成熟实现，不要跳过命名直接手写造轮子。

## Output Structure

复杂决策默认使用结构化输出：需求翻译 / 关键假设 / 问题类别（项目类型 + 问题维度）/ 命名（业界叫法 + 出处 + 可搜索关键词）/ 可枚举候选（每个带 canonical name、成熟度、适用边界、坑、采用者）/ 推荐选项（带理由与前提）/ 需要确认 / 失败模式 / 不建议 / 最小可信落地 / 需要验证。命名与可枚举候选、推荐选项都必须出现，缺一即为盲盒。小问题可以压缩表达，但仍保留同样的判断逻辑。完整骨架见 `references/output-templates.md`。

## References

引擎参考（stack 无关，按阶段使用）：

- `references/decision-rubric.md`：评估清单、澄清规则与推荐规则（第 2/3/6/8 步）。
- `references/anti-patterns.md`：推理类反模式，做第 7 步失败模式分析时对照。
- `references/output-templates.md`：结构化输出骨架（产出阶段）。

模式库（第 4 步识别项目类型后按需加载，通常只读其一）：

- Flutter/跨端移动 → `references/patterns-flutter.md`
- SwiftUI/iOS 原生 → `references/patterns-swiftui.md`
- 前端/Web → `references/patterns-frontend.md`
- Python/后端 → `references/patterns-python-backend.md`
- 全栈/接缝 → `references/patterns-fullstack.md`（接缝模式 + 交叉引用另两个包）
