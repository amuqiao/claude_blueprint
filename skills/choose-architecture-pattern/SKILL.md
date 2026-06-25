---
name: choose-architecture-pattern
description: >-
  Use when Codex must translate vague or implementation-shaped user needs into production-grade architecture requirements, map those requirements to mature patterns, compare options, clarify assumptions, and avoid custom reinvention or technical debt. Trigger for full-stack architecture decisions, "what is the real requirement", "avoid reinventing the wheel", "production-ready", "mature solution", reliability, scalability, maintainability, security, data consistency, queues, async workflows, caching, APIs, frontend state, deployment, observability, billing, AI integrations, or any request asking whether an architecture is reasonable or which approach is better.
---

# Choose Architecture Pattern

在涉及架构判断、技术选型或生产可靠性的问题上，先使用本 skill 放慢决策速度。目标是先把用户的自然语言诉求翻译成工程真实需求，再对照成熟模式和场景约束，最后给出可落地、可运维的方案，避免过早自定义机制或重复造轮子。

核心定位：这是一个“需求翻译器 + 成熟模式匹配器 + 生产落地审查器”，不是只给结论的方案选择器。

## 必须执行的流程

1. 先翻译需求：区分“用户原话/表面诉求”“用户提出的实现方式”“真正要保证的结果”“不在解决的问题”。
2. 明确关键假设：列出当前判断依赖的事实，例如一致性级别、失败代价、吞吐量、延迟、团队运维能力、现有技术栈。
3. 判断是否需要先澄清：如果缺失信息会改变架构边界、高风险数据正确性、安全/合规、成本或运维责任，先向用户提出 1-3 个关键问题，并给出推荐默认选项；如果不阻塞，先继续但显式标注假设。
4. 归类问题领域：前端状态、API 合同、认证授权、数据一致性、异步流程、队列、重试、存储、缓存、搜索、可观测性、部署、成本/计费、AI 集成，或其他类别。
5. 在提出自定义设计前，先把需求信号映射到成熟模式。常见生产问题优先考虑已知模式，而不是从零发明。
6. 除非用户只是问一个窄问题，否则至少比较两个可行方案；比较时说明适用边界，不只比较优缺点。
7. 分析失败模式：部分失败、重试、重复请求/消息、并发竞争、陈旧数据、一致性缺口、运维恢复、安全滥用和可观测性缺口。
8. 明确推荐一个方案，说明为什么推荐、成立前提是什么，并说明不建议采用什么方案。
9. 给出最小的生产可信落地路径。避免过度设计，但不能隐藏关键可靠性要求。
10. 列出实施前必须验证的事实。如果信息可能过时，或依赖具体生态/云服务/库版本，先查权威来源。

## 澄清规则

不要默认直接裁决。先判断用户是在要“结论”，还是需要“把需求翻译成成熟模式”。

必须先澄清的情况：

- 用户的目标、失败代价或一致性等级不清楚，且不同答案会导致不同架构。
- 需求可能涉及资金、权限、合规、数据丢失、用户可见状态或不可逆操作。
- 用户把某个实现方式当成需求，但看起来可能不是最合适的生产模式。
- 需要选择会显著增加运维面的基础设施，例如队列、分布式锁、事件总线、工作流引擎、CDC、搜索集群。

可以不阻塞、继续给建议的情况：

- 关键假设可以安全声明，且推荐方案在这些假设下明显成立。
- 用户明确要求先给判断或方案草案。
- 问题是窄范围解释，不涉及实施决策。

澄清时要枚举可选项并标注推荐项，不要只问开放问题。例如：

```text
我先确认一致性目标，推荐选项是 2：
1. best-effort：失败可人工补发，允许少量丢失。
2. 最终一致且不丢：DB 状态和消息意图必须持久化，队列可重试。
3. 强一致同步提交：需要事务消息或分布式事务，复杂度更高。
```

## 决策标准

当问题常见、失败代价高、涉及用户状态/资金/权限/数据丢失/合规，或需要可运维恢复时，优先采用成熟模式。

当范围很小、单进程、同步失败可直接暴露给调用方，或成熟模式带来的运维成本超过风险时，优先采用更简单的本地设计。

不要把“happy path 能跑”当成生产架构合理。必须考虑重试、崩溃、并发请求、重复消息、部署重启和外部服务部分失败下的正确性。

不要把用户提出的机制直接当成需求。先问：它真正要保护什么事实？它要避免什么失败？谁要恢复？恢复依据在哪里？

## 输出结构

复杂决策默认使用这个结构：

```text
需求翻译：
- 用户原话/表面诉求：
- 用户提出的实现方式：
- 我理解的真实需求：
- 不在解决的问题：

关键假设：
- ...

问题类别：
- ...

成熟模式候选：
- 模式 A：适用/不适用原因。
- 模式 B：适用/不适用原因。

候选方案：
- 方案 A：
- 方案 B：

推荐选项：
- 推荐：
- 为什么：
- 成立前提：

需要确认：
- 问题 1：可选项 + 推荐项。

失败模式：
- ...

不建议：
- ...

最小可信落地：
- ...

需要验证：
- ...
```

小问题可以压缩表达，但仍保留同样的判断逻辑。

## References

只读取当前任务需要的 reference：

- `references/decision-rubric.md`：用于架构评估清单和推荐规则。
- `references/mature-patterns.md`：用于把问题映射到成熟生产模式。
- `references/anti-patterns.md`：用于识别自定义造轮子和隐藏可靠性债务。
- `references/output-templates.md`：用于需要结构化架构比较时。
