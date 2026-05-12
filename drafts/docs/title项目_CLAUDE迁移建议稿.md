# `title` 项目 `.claude/CLAUDE.md` 迁回根 `CLAUDE.md` 建议稿

## 结论

`/Users/admin/Downloads/Code/title/.claude/CLAUDE.md` 当前内容基本都属于**项目共享规范**，不属于项目个人私有记忆。

因此建议：

- 将其中规则迁回项目根 [`/Users/admin/Downloads/Code/title/CLAUDE.md`](</Users/admin/Downloads/Code/title/CLAUDE.md>)
- 迁回后，删除或停用 [`/Users/admin/Downloads/Code/title/.claude/CLAUDE.md`](</Users/admin/Downloads/Code/title/.claude/CLAUDE.md>)
- 后续项目个人私有补充，改用：
  - 项目根 `CLAUDE.local.md`
  - 或在项目根 `CLAUDE.md` 中用 `@import` 引个人文件

当前 `.claude/CLAUDE.md` 里没有明显只属于“个人偏好”的内容。

---

## 为什么这些内容应迁回根 `CLAUDE.md`

`.claude/CLAUDE.md` 当前主要包含 4 类内容：

1. 新模块开发前置检查
2. 实现完成后的文档回写检查
3. 代码区域到设计文档的映射表
4. 设计文档写作边界

这些内容的共同特点是：

- 约束的是**任何人在这个项目里**如何让 Claude 工作
- 依赖的是项目共享文档和项目共享目录结构
- 不属于某个开发者个人的工作习惯

所以它们应被视为项目主记忆的一部分，而不是项目私有补充。

---

## 建议迁移方式

不建议把 `.claude/CLAUDE.md` 整份原样附加到根文件末尾。更好的方式是：

- 在根 `CLAUDE.md` 中新增一个项目级章节
- 将 `.claude/CLAUDE.md` 的内容按职责拆成 4 个小节并入
- 保留原有根 `CLAUDE.md` 的命令、架构、后端规则等主体结构不动

推荐新增一级标题：

```markdown
## Project Documentation Workflow
```

放置位置建议：

- 放在根 `CLAUDE.md` 的 `## Backend Rules` 之后
- 或放在文件末尾，作为项目级补充规则区

不建议插到 `## Architecture` 前面，避免打断现有“命令 → 架构 → 规则”的主叙事结构。

---

## 建议迁回根 `CLAUDE.md` 的内容

### 1. 实现前置检查

建议作为：

```markdown
### Documentation Preconditions
```

建议稿：

```markdown
### Documentation Preconditions

Applies when implementing a new feature, a new module, or making a structural change to an existing module. Pure bug fixes and config-only changes do not trigger this section.

**New module: design before implementation**

Treat the work as a "new module" only when all three are introduced together:
- a new backend DB table
- a new API endpoint
- a new frontend workspace surface (new page / store / service)

Before writing code:
1. Read `docs/design/架构设计方案.md` to confirm global layering constraints.
2. Create a design document to define data model, interface contract, and layer boundaries.
3. Wait for user confirmation before implementation.

If the design document does not exist, stop and do not infer the implementation on your own.

**Feature expansion inside an existing module: implement first, sync docs after**

When adding fields, branches, or pipeline steps inside an existing module:
1. Read the relevant design document first.
2. Implement the change.
3. Run the post-implementation documentation check before responding.
```

### 2. 实现后置检查

建议作为：

```markdown
### Documentation Post-Check
```

建议稿：

```markdown
### Documentation Post-Check

After code changes are complete and before replying to the user, check whether any affected design documents must be updated. A task is not complete until the relevant docs have been reviewed and updated if needed.
```

然后把原来的映射表整体迁入。

### 3. 设计文档索引

这一块内容量比较大，不建议整段硬塞进根 `CLAUDE.md` 作为长期静态表。

更稳的迁移方式：

- 在根 `CLAUDE.md` 只保留“读取入口”和“如何导航”
- 把具体映射表继续留在设计文档体系里维护

建议根 `CLAUDE.md` 只写成：

```markdown
### Documentation Entry Points

Use `docs/design/INDEX.md` as the primary navigation entry for project design documents.

When implementation touches a specific area, read the matching module or infrastructure document before changing code.

Important entry points:
- module docs: `docs/design/模块/`
- backend infrastructure docs: `docs/design/基础设施/后端/`
- frontend infrastructure docs: `docs/design/基础设施/前端/前端开发规范.md`
- topic / troubleshooting docs: `docs/专题/`
```

原因：

- 根 `CLAUDE.md` 里已经很长
- 把完整索引表重复塞进去，维护成本高
- 真正的权威入口本来就应该是 `docs/design/INDEX.md`

### 4. 设计文档写作规范

建议作为：

```markdown
### Documentation Boundary
```

建议稿：

```markdown
### Documentation Boundary

Global writing guidance comes from `~/.claude/CLAUDE.md`.

Before writing or updating any design document, read `docs/design/架构设计方案.md` §7 to confirm the boundary between:
- project-level architecture documentation
- module-level design documentation
- infrastructure documentation
```

---

## 不建议原样迁回的内容

以下内容不建议原样迁回根 `CLAUDE.md`：

### `## 设计文档索引` 下的完整长表

原因：

- 它和 `docs/design/INDEX.md` 职责重叠
- 后续每新增一个设计文档，就会形成双重维护
- 根 `CLAUDE.md` 会变得更长、更难读

建议处理：

- 根 `CLAUDE.md` 保留导航原则
- 具体索引继续以 `docs/design/INDEX.md` 为准

---

## 迁移后，`.claude/CLAUDE.md` 还要不要保留

建议：**不保留为正式项目记忆文件。**

迁移完成后有两种做法：

### 方案 A：删除

适合你已经确认根 `CLAUDE.md` 完整接住这些规则。

### 方案 B：保留一行提示后清空主体

例如仅保留：

```markdown
# Deprecated

This file is no longer used as the standard project memory location.
Project-shared rules have been moved to the repository root `CLAUDE.md`.
```

如果你担心短期内还有旧工作流引用它，可以先用方案 B，过一段时间再删。

---

## 迁移后的推荐结构

`title/CLAUDE.md` 继续承担：

- 开发命令
- 日志与诊断工具
- 架构说明
- 后端规则
- 项目级文档工作流规则

`.claude/CLAUDE.md` 不再承担正式职责。

如果未来确实有“只属于你个人”的项目私有说明，再放到：

- `title/CLAUDE.local.md`
- 或 `@import` 到个人文件

---

## 最小迁移步骤

1. 在根 `CLAUDE.md` 新增：
   - `Documentation Preconditions`
   - `Documentation Post-Check`
   - `Documentation Entry Points`
   - `Documentation Boundary`
2. 将 `.claude/CLAUDE.md` 中“实现前置检查”和“实现后置检查”合并进入根文件
3. 不迁移完整“设计文档索引”长表，只迁移导航原则
4. 将 `.claude/CLAUDE.md` 改成 deprecated 提示，观察一段时间
5. 确认无依赖后删除 `.claude/CLAUDE.md`
