---
name: personal-os
description: "我的个人专属方法 skill。适用于使用我长期沉淀的文档表达、设计文档、FastAPI 后端、脚本模式与代码讲解方法；当核心问题是这些稳定方法本体，而不是 drafts 日常治理时使用。"
---

# Personal OS Skill

这是一个**个人专属方法 skill**。  
它只维护你确认要长期保留的稳定方法真源。

它主要负责：

- 维护文档表达方法
- 维护设计文档方法
- 维护 FastAPI 后端工程方法
- 维护批量 Python 脚本模式
- 维护服务生命周期脚本模式
- 维护运维诊断 CLI 模式
- 维护代码讲解方法

## Canonical Sources

本 skill 的方法真源在以下 references 中：

- [`references/document-writing.md`](references/document-writing.md)
- [`references/design-doc.md`](references/design-doc.md)
- [`references/fastapi-backend.md`](references/fastapi-backend.md)
- [`references/python-script.md`](references/python-script.md)
- [`references/shell-service.md`](references/shell-service.md)
- [`references/python-ops-cli.md`](references/python-ops-cli.md)
- [`references/code-explain.md`](references/code-explain.md)

除本 skill 自身的 references 外，当前只保留一个外部例外真源：

- [`../project-methodology/`](../project-methodology)

读取顺序：

1. 先判断问题属于哪类方法
2. 再只读一个最相关的本地 reference
3. 只有当问题本质上属于项目方法时，才跳到 `project-methodology`

## 标准使用方式

这个 skill 的默认动作顺序是：

1. 先判断当前问题是“文档表达 / 设计文档 / FastAPI 后端 / 批量脚本 / 服务管理脚本 / 运维 CLI / 代码讲解 / 项目方法”中的哪一类
2. 读取一个最相关的本地 reference
3. 基于真源继续分析

## 什么时候使用

当问题主要是**我已经沉淀下来的个人方法该如何使用或补充**时，使用这个 skill。

### 必须使用

- 需要使用文档表达方法
- 需要使用设计文档方法
- 需要使用 FastAPI 后端工程方法
- 需要使用脚本模式或代码讲解方法

### 推荐使用

- 某个日常好用的做法已经稳定，准备补充进 skill
- 想判断某条内容更适合补到哪个现有 reference

### 不适合使用

- 纯代码实现任务
- 纯项目业务决策
- prompt 清理、归档、草稿治理
- 纯项目业务决策

## 路由逻辑

默认按下面顺序分流：

1. 如果核心问题是“文档怎么组织、怎么表达、怎么降低理解成本”
   则路由到：`references/document-writing.md`

2. 如果核心问题是“架构文档、模块设计文档、设计方案质检怎么做”
   则路由到：`references/design-doc.md`

3. 如果核心问题是“FastAPI 后端怎么起盘、怎么分层、怎么补测试、怎么验证”
   则路由到：`references/fastapi-backend.md`

4. 如果核心问题是“批量 API 调用脚本怎么组织、怎么做并发、重试和报告”
   则路由到：`references/python-script.md`

5. 如果核心问题是“dev.sh / service.sh 这类多服务生命周期脚本怎么写”
   则路由到：`references/shell-service.md`

6. 如果核心问题是“诊断 CLI 怎么设计、子命令怎么拆、--apply 怎么控制”
   则路由到：`references/python-ops-cli.md`

7. 如果核心问题是“这段代码怎么讲、哪些逻辑值得讲、代码讲解结构怎么组织”
   则路由到：`references/code-explain.md`

8. 如果核心问题是“项目现在该处在哪个阶段、下一步做什么”
   则路由到：`project-methodology`

## 输出契约

默认先输出：

```text
当前方法类型：
建议查看的 reference：
建议最小动作：
```

只有在这一步清楚后，才继续展开细节。

## 最小判断规则

- 如果问题是“文档表达” -> 读 `references/document-writing.md`
- 如果问题是“设计文档 / 设计评审” -> 读 `references/design-doc.md`
- 如果问题是“FastAPI 后端工程模式” -> 读 `references/fastapi-backend.md`
- 如果问题是“批量 API 调用脚本” -> 读 `references/python-script.md`
- 如果问题是“服务生命周期管理脚本” -> 读 `references/shell-service.md`
- 如果问题是“运维诊断 CLI” -> 读 `references/python-ops-cli.md`
- 如果问题是“代码讲解” -> 读 `references/code-explain.md`
- 如果问题是“项目方法” -> 用 `project-methodology`

## 重要边界

- 这是个人专属方法 skill，不负责 drafts 的治理
- `project-methodology` 仍是例外真源，不要复制它的正文
- drafts 里的日常好用内容，只有在你确认稳定后才收编进这里
