# Codex Skill 安装与本地接入说明

> **文档职责**：说明 Codex 目前可确认的 skill 使用方式，以及本仓库如何把本地方法论落地为可复用 skill。
> **适用场景**：你想在 Codex 中使用 skill，但不确定“官方安装方式”和“本地仓库接入方式”之间的区别。
> **目标读者**：维护本仓库、同时使用 Codex CLI / Codex App 的开发者。
> **维护规范**：如果 Codex 官方文档补充了本地 skill 安装命令，或本仓库的 `skills/` 结构发生变化，需要同步更新本文。

---

## 1. 先说结论

当前更稳的理解是：

- Codex 官方已经明确支持 `skill` 这个概念，以及 `SKILL.md` 作为核心文件
- 官方也明确支持在 Codex / ChatGPT 界面中创建、安装、选择 skill
- 但截至本文落地时，本仓库没有把“本地目录直接安装为 Codex skill”的某个 CLI 命令当作稳定前提
- 因此，本仓库采用的是：
  - `skills/<name>/` 维护 skill 正文与 references 真源
  - 运行时按 Codex 的 skill 机制显式调用或语义触发
  - 不依赖一个尚未在本仓库中固化的“本地安装命令”

一句话：

**本仓库把 skill 当成稳定目录结构来维护，而不是绑定某个未确认长期稳定的本地安装命令。**

---

## 2. 官方可确认的部分

目前可以明确确认的官方事实只有这几类：

### 2.1 Codex CLI 的安装

Codex CLI 官方安装方式是：

```bash
npm i -g @openai/codex
codex
```

这解决的是 **Codex CLI 本体安装**，不是某个本地 skill 目录的安装。

### 2.2 Skill 的官方形态

官方把 skill 描述为一种可复用工作流，核心通常是一个 `SKILL.md` 文件。  
`SKILL.md` 被当作技能的 playbook，也是可移植的 Markdown/open standard。

### 2.3 Skill 的官方使用方式

官方当前更明确的使用方式是：

- 在 Codex / ChatGPT 界面中创建或安装 skill
- 在线程中按 `$` 选择 skill
- 或直接用 `$skill-name ...` 的方式调用

---

## 3. 为什么本仓库不把“本地安装命令”写死

原因很简单：

- 官方文档明确了 Codex CLI 的安装
- 官方文档明确了 skills 的概念、`SKILL.md` 结构和界面里的使用方式
- 但在本文编写时，本仓库没有把某个“从本地目录安装到 Codex CLI”的命令当作稳定依赖

所以这里要区分两件事：

### 3.1 官方稳定能力

- Codex 支持 skill
- skill 以 `SKILL.md` 为核心
- 可以在 Codex / ChatGPT 界面中使用 skill

### 3.2 本仓库的工程落地

- skill 先作为仓库内稳定目录维护
- 保证结构、真源、路由逻辑都自洽
- 后续如果 Codex 官方本地安装路径更明确，再补充“如何装入某个具体运行环境”

也就是说：

**这里优先保证 skill 本身是成立的，其次才是把它接进某个具体入口。**

---

## 4. 本仓库采用的落地方式

本仓库当前把 `project-methodology` 作为标准 skill 来维护。

目录位置：

- [../../../skills/project-methodology/SKILL.md](../../../skills/project-methodology/SKILL.md)
- [../../../skills/project-methodology/agents/openai.yaml](../../../skills/project-methodology/agents/openai.yaml)
- [../../../skills/project-methodology/references/README.md](../../../skills/project-methodology/references/README.md)

它的结构是：

```text
skills/project-methodology/
├── SKILL.md
├── agents/
│   └── openai.yaml
└── references/
    ├── README.md
    ├── 项目成型方法论.md
    ├── 功能模块成型方法论.md
    ├── 基础设施演进方法论.md
    ├── 需求与版本演进方法论.md
    └── 文档成型规则.md
```

这里的含义是：

- `SKILL.md`：触发说明、边界、最小路由逻辑
- `references/`：方法论真源
- `agents/openai.yaml`：面向 OpenAI / Codex UI 的补充元数据

---

## 5. 为什么这样更稳

这样设计有 4 个好处：

### 5.1 不依赖单一安装命令

即使未来 Codex 的本地安装入口变化，这份 skill 本身仍然是完整的。

### 5.2 真源和入口在一个 skill 目录内闭环

避免出现：

- `prompts/` 是真源
- `skills/` 只是外壳
- 两边长期漂移

### 5.3 更符合标准 skill 结构

当前这份 skill 已经是：

- `SKILL.md`
- `references/`
- `agents/openai.yaml`

这种更标准的自包含形态。

### 5.4 便于迁移

如果后续要迁到别的运行环境，你迁的是整个 `skills/project-methodology/`，而不是再拼装多处真源。

---

## 6. 实际应如何使用

### 6.1 在本仓库内维护

默认直接维护：

- [../../../skills/project-methodology/SKILL.md](../../../skills/project-methodology/SKILL.md)
- [../../../skills/project-methodology/references/](../../../skills/project-methodology/references/)

不要再回到 `prompts/meta/` 维护正文。  
`prompts/meta/` 现在只保留迁移说明：

- [../../../prompts/meta/README.md](../../../prompts/meta/README.md)

### 6.2 在 Codex 中触发

更稳的使用方式是：

- 在支持 skills 的 Codex / ChatGPT 入口中显式调用
- 用 `$project-methodology` 或明确的技能语义触发

例如：

```text
$project-methodology
我现在在做一个 0-1 的复杂项目 POC，请先判断当前层次、当前阶段、最主要问题，以及建议先调用哪份方法论。
```

### 6.3 在本地蓝图体系里部署

如果你维护的是这套 blueprint，本仓库的 `skills/` 本来就会通过部署脚本同步到运行层。  
这意味着：

- skill 目录本身会被部署
- 但你仍然不需要把一个未明确稳定的“本地安装命令”写进主流程

---

## 7. 什么时候不该把它当“已安装 skill”

下面这些情况，不要自欺欺人地说“已经装好了”：

- 你只是写好了仓库内的 `skills/project-methodology/`
- 但当前使用的 Codex 入口并不会读取这个目录
- 或者当前环境里并没有把该目录纳入 skill 发现范围

此时更准确的说法应该是：

- **skill 已经按标准结构落地**
- **但是否被当前 Codex 入口自动发现，还取决于该入口的加载机制**

这两件事不能混为一谈。

---

## 8. 当前推荐心智模型

不要把“安装 skill”只理解成一个命令。

更稳的理解是：

1. **先把 skill 结构维护正确**
2. **再确认当前 Codex 入口是否能发现 / 使用它**
3. **最后才讨论是否需要额外安装动作**

在这个顺序下：

- `skill 是否成立`
- `skill 是否被当前运行环境发现`
- `skill 是否有额外安装步骤`

是三件不同的事。

---

## 9. 对本仓库的建议

当前最合理的做法就是继续保持：

- `skills/project-methodology/` 作为 skill 真源
- `references/` 作为方法论正文
- `SKILL.md` 作为薄调度入口
- `prompts/meta/` 不再维护重复正文

如果未来 Codex 官方把“本地目录 skill 安装 / 注册”做得更清楚，再在本文补一节：

- 官方本地安装方式
- 本仓库对应接入步骤

在那之前，不要把未确认稳定的命令写成硬规范。
