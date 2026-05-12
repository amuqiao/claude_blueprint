# 文档索引

> 本目录用于补充仓库级总览文档，不替代 `README.md`、`PLAYBOOK.md`、`WHY.md`、`MAINTAINING.md`、`RUNTIME-MAINTAINING.md`；文档和 prompt 草稿统一留在 `drafts/` 目录，不放进 `docs/`。

---

## 先看什么

- 首次接触本仓库：看 [`README.md`](../README.md)
- 想理解开发范式：看 [`PLAYBOOK.md`](../PLAYBOOK.md)
- 想理解设计取舍：看 [`WHY.md`](../WHY.md)
- 想维护这套模板：看 [`MAINTAINING.md`](../MAINTAINING.md)
- 想维护运行层资产：看 [`RUNTIME-MAINTAINING.md`](../RUNTIME-MAINTAINING.md)

补充：
- 想先理解“人类层 vs Claude 层”的边界，先看 [`README.md`](../README.md) 对应小节

---

## 本目录包含什么

### 核心文档

这 3 篇是 `docs/` 目录的主柱，分别承载“理解层 / 能力层 / 主干流程层”。
推荐理解顺序是：先看“这套系统怎么理解”，再看“有哪些能力可用”，最后看“项目开发主线怎么走”。

- [`用户心智模型.md`](用户心智模型.md)
  解释为什么这套 blueprint 要区分“人类层”和“Claude 层”，以及你在 Claude TUI 中应该如何使用这套系统。

- [`能力地图.md`](能力地图.md)
  解释 `commands / agents / skills / hooks / templates` 的区别、触发方式和使用边界。

- [`项目开发主干流程.md`](项目开发主干流程.md)
  用节点模型把项目开发串成一条主干，说明每个节点的目标、输入、输出、质量标准和可调用能力。

### 辅助文档

这 2 篇用于纠偏和桥接，不承担主方法论，不应继续无限扩写。

- [`项目级落地范式.md`](项目级落地范式.md)
  解释面对一个真实项目时，如何从“想法”走到“项目定盘 → 首个核心模块 → 最小可用基建”，而不是误以为可以一键完成项目起盘。

- [`工作流参考.md`](工作流参考.md)
  用场景导航方式说明常见开发场景该从哪个入口进入、应该跳转到哪篇主文档。

---

## 不放什么

本目录当前不单独拆：

- `commands` 逐项说明书
- `skills` 逐项说明书
- `agents` 逐项说明书
- `hooks` 逐项说明书
- `templates` 逐项说明书

原因是这些细节已经分别散落在：

- `commands/*.md`
- `skills/*/SKILL.md`
- `agents/*.md`
- `hooks/*.sh`
- `templates/*.md`

现阶段优先保证总览清晰，避免文档重复和漂移。

补充：
- 当前只做**逻辑分级**，不做 `core/`、`support/` 这类物理目录拆分
- 只有当 `docs/` 数量明显增长、阅读导航开始拥挤时，才考虑物理分级
