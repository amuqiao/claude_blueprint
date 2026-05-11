你说得对，我刚才偏题了。

正确目标不是整理 `title`，而是：**把 `title` 里已经跑通的项目级模式抽象回 `claude_blueprint`，让它成为新项目和老项目都能复用的标准模板。**

基于这个目标，`title` 给 `claude_blueprint` 的启发主要有 4 个：

1. **项目级 `CLAUDE.md` 必须承担“文档工作流规则”**
不是只写启动命令和目录映射，还要写：
- 新模块先设计后实现
- 实现后必须做文档回写检查
- 文档入口从哪读

2. **项目初始化和日常开发必须分开**
这也是为什么我们刚加了 `/init-architecture`。
- 初始化：补齐 `CLAUDE.md`、`INDEX.md`、`架构设计方案.md`、`实施清单.md`
- 日常开发：`/new-module`、`/update-docs`、`@arch`、`@rev`

3. **根 `CLAUDE.md` 应该只保留通用的项目级规则**
`title` 里的很多规则是好东西，但不是每一条都该原样塞进模板。
应该抽象成：
- 文档前置条件
- 文档后置检查
- 文档入口原则
- 文档边界原则

4. **具体文档映射表不应进入模板**
像 `title` 那种“哪个目录对应哪个文档”的长表，是项目成熟后才有的项目资产，不该进 `claude_blueprint` 模板。
模板里只该保留方法，不该保留项目特定清单。

所以现在对 `claude_blueprint` 来说，最值得继续做的不是动 `title`，而是把这些启发继续固化到模板里。下一步最有价值的 3 件事是：

- **增强 [`templates/project-CLAUDE.md`](/Users/admin/Downloads/Code/claude_blueprint/templates/project-CLAUDE.md)**
  加入通用版的：
  - Documentation Preconditions
  - Documentation Post-Check
  - Documentation Entry
  - Documentation Boundary

- **补一个 [`templates/实施清单.md`](/Users/admin/Downloads/Code/claude_blueprint/templates)**
  这样 `/init-architecture` 就不是临时写最小骨架，而是按模板生成。

- **在 [`README.md`](/Users/admin/Downloads/Code/claude_blueprint/README.md) 或 [`MAINTAINING.md`](/Users/admin/Downloads/Code/claude_blueprint/MAINTAINING.md) 里明确“标准项目生命周期”**
  例如：
  - 新项目先 `/init-architecture`
  - 新模块用 `/new-module`
  - 代码落库后 `/update-docs`
  - 发现新通用规则再 `/add-rule`

一句话总结：

**`title` 现在最有价值的作用，是当“已验证样板间”；`claude_blueprint` 要做的是把其中稳定的模式抽象成模板，而不是回头围着 `title` 本身做迁移。**

如果你要，我下一步就只做 `claude_blueprint` 本身这 3 个强化，不再展开 `title`。