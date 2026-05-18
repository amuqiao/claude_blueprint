# Prompt Layer Policy

## 核心口径

`drafts/prompts/` 是**使用层**，不是默认真源。

这意味着：

- prompt 可以保留
- prompt 可以高频使用
- 但规范和方法的最终维护应尽量回到 `skills/`

## prompt 的三种状态

### 1. 保留

保留在 `wip/` 的 prompt 通常满足以下条件：

- 你日常会直接用
- 它更像任务启动器
- 单独拿来就很顺手
- 即使背后有真源，保留它仍有实际使用价值

### 2. 合并

需要合并的 prompt 一般有这些信号：

- 同一主题只有措辞差异
- 多份文件在维护同一能力
- 每次改一处都要同步改另外几份

### 3. 归档

建议进入 `archived/` 的 prompt 一般满足：

- 已被真源 skill 接管
- 已经不再作为主维护入口
- 保留只为历史参考

## 当前观察期文件

在没有确认专属 skill 结构完全稳定前，下面这些文件允许继续观察，不急着归档：

- `drafts/prompts/wip/operations/蓝图维护与规则归档 Prompt.md`
- `drafts/prompts/wip/writing/代码讲解文档 Prompt.md`
- `drafts/prompts/wip/backend/FastAPI_Request_Body_示例_prompt.md`

## 当前已完成的收口

- 可视化增强类 prompt 已合并为：
  - `drafts/prompts/wip/writing/文档可视化增强_prompt.md`
- 第一批明确派生物已归入 `drafts/prompts/archived/`

## 使用原则

- 想快速做事：先用 prompt
- 想改规则真源：回 `skills/`
- 想判断一个 prompt 还该不该留：先看它是不是仍有日常使用价值

## 与真源层的关系

- `skills/` 负责真源
- `drafts/prompts/` 负责使用层
- `archived/` 负责历史派生物

只有当 prompt 长期脱离真源演化时，才需要把内容回收进 `skills/`
