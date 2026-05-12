# 文档索引

> 本目录用于补充仓库级总览文档，不替代 `README.md`、`PLAYBOOK.md`、`WHY.md`、`MAINTAINING.md`。

---

## 先看什么

- 首次接触本仓库：看 [`README.md`](/Users/admin/Downloads/Code/claude_blueprint/README.md)
- 想理解开发范式：看 [`PLAYBOOK.md`](/Users/admin/Downloads/Code/claude_blueprint/PLAYBOOK.md)
- 想理解设计取舍：看 [`WHY.md`](/Users/admin/Downloads/Code/claude_blueprint/WHY.md)
- 想维护这套模板：看 [`MAINTAINING.md`](/Users/admin/Downloads/Code/claude_blueprint/MAINTAINING.md)

补充：
- 想先理解“人类层 vs Claude 层”的边界，先看 [`README.md`](/Users/admin/Downloads/Code/claude_blueprint/README.md) 对应小节

---

## 本目录包含什么

- [`用户心智模型.md`](/Users/admin/Downloads/Code/claude_blueprint/docs/用户心智模型.md)
  解释为什么这套 blueprint 要区分“人类层”和“Claude 层”，以及你在 Claude TUI 中应该如何使用这套系统。

- [`项目级落地范式.md`](/Users/admin/Downloads/Code/claude_blueprint/docs/项目级落地范式.md)
  解释面对一个真实项目时，如何从“想法”走到“项目定盘 → 首个核心模块 → 最小可用基建”，而不是误以为可以一键完成项目起盘。

- [`项目开发主干流程.md`](/Users/admin/Downloads/Code/claude_blueprint/docs/项目开发主干流程.md)
  用节点模型把项目开发串成一条主干，说明每个节点的目标、输入、输出、质量标准和可调用能力。

- [`能力地图.md`](/Users/admin/Downloads/Code/claude_blueprint/docs/能力地图.md)
  解释 `commands / agents / skills / hooks / templates` 的区别、触发方式和使用边界。

- [`工作流参考.md`](/Users/admin/Downloads/Code/claude_blueprint/docs/工作流参考.md)
  把项目定盘、模块设计、实现落地、回写抽象串成一条可复用主线。

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
