# Maintaining Claude Blueprint

> **文档职责**：说明这个仓库后续如何维护、如何迭代、改完后如何验证。
> **适用场景**：新增 prompt / skill / command / hook / agent、调整部署边界、修改脚本、准备发布更新前阅读。
> **目标读者**：本仓库维护者。
> **维护规范**：只要部署模型、目录职责、验收流程或维护流程发生变化，就同步更新本文档。

---

## 1. 核心文档各管什么

文档职责边界以本节为唯一准则。

- `README.md`：给使用者看，讲安装、部署、更新、验收
- `PLAYBOOK.md`：定义开发范式，说明项目生命周期和阶段边界
- `WHY.md`：记录为什么这样设计，解释关键决策
- `MAINTAINING.md`：给维护者看，说明仓库治理、文档治理、发布与检查
- `DRAFTS-MAINTAINING.md`：说明 `drafts/` 草稿箱如何分阶段、如何分类、何时升格
- `RUNTIME-MAINTAINING.md`：说明运行层资产（`CLAUDE.md`、`settings.json`、`rules/`、`hooks/`、`skills/`、`agents/`、`commands/`、`templates/`）怎么维护
- `docs/INDEX.md`：只索引 `docs/` 子目录，不负责全仓入口导航
- `plugin-install-plan.md`：Plugin 安装计划，属于配置资产，不属于维护文档

判断原则：
- 用户怎么用 → 改 `README.md`
- 先做什么、后做什么、阶段怎么切 → 改 `PLAYBOOK.md`
- 为什么这样设计 → 改 `WHY.md`
- 仓库治理、文档治理、发布检查 → 改 `MAINTAINING.md`
- 草稿箱治理、升格路径、分类规则 → 改 `DRAFTS-MAINTAINING.md`
- 运行层资产维护规则 → 改 `RUNTIME-MAINTAINING.md`
- `docs/` 子目录导航 → 改 `docs/INDEX.md`
- Plugin 分层和安装计划 → 改 `plugin-install-plan.md`

---

## 2. 部署边界怎么维护

本仓库采用“仓库是配置源，`~/.claude` 是部署目标”的模型。

真正会部署到 `~/.claude` 的内容，由 `deploy-manifest.txt` 白名单决定。

当前会部署的路径：
- `CLAUDE.md`
- `settings.json`
- `rules/`
- `hooks/`
- `skills/`
- `agents/`
- `commands/`
- `templates/`

默认不部署的内容：
- `scripts/`
- `acceptance/`
- `drafts/`
- `prompts/`
- `README.md`
- `WHY.md`
- `MAINTAINING.md`
- `DRAFTS-MAINTAINING.md`
- `.gitignore`

规则：
- 新增“应该进入 `~/.claude`”的路径时，必须同步更新 `deploy-manifest.txt`
- 新增仓库维护文件时，默认不要加进 manifest
- 改动部署范围后，必须同步更新 `README.md`

---

## 3. 记忆位置约定怎么维护

本 blueprint 采用以下 Claude Code 记忆位置约定：

- 项目共享记忆：项目根 `CLAUDE.md`
- 用户全局记忆：`~/.claude/CLAUDE.md`
- 项目个人补充：优先在项目 `CLAUDE.md` 中通过 `@import` 引入个人文件

兼容规则：
- 如需兼容官方项目个人记忆文件，可使用项目根 `CLAUDE.local.md`
- `.claude/CLAUDE.md` 不作为本 blueprint 的标准项目记忆位置

维护规则：
- 如果项目里出现 `.claude/CLAUDE.md`，不要直接沿用为标准方案
- 其中属于项目共享的内容，应迁回项目根 `CLAUDE.md`
- 其中属于个人私有的内容，应迁到 `CLAUDE.local.md` 或用户目录下单独文件，再通过 `@import` 引入
- 这套约定发生变化时，必须同步更新 `README.md`、`MAINTAINING.md` 和 `templates/project-CLAUDE.md`

---

## 4. 常见变更应该改哪里

### `docs/` 目录怎么维护

`docs/` 的定位是：**总览与桥接层**。

它不替代：
- `README.md`
- `PLAYBOOK.md`
- `WHY.md`
- `MAINTAINING.md`

当前 `docs/` 采用**逻辑分级**，而不是物理分目录：

- 核心文档：
  - `docs/用户心智模型.md`
  - `docs/能力地图.md`
  - `docs/项目开发主干流程.md`
- 辅助文档：
  - `docs/项目级落地范式.md`
  - `docs/工作流参考.md`

职责边界：
- `用户心智模型`：解释这套系统怎么理解
- `能力地图`：解释能力分类与边界
- `项目开发主干流程`：解释项目开发的主干节点
- `项目级落地范式`：解释为什么项目起盘不能理解成一键生成
- `工作流参考`：解释常见场景下该从哪个入口进入

维护规则：
- 优先更新现有文档，不要轻易新增新的 `docs/*.md`
- 只有当现有文档无法承载，且新文档解决的是一个独立问题域时，才新增文档
- `项目级落地范式` 和 `工作流参考` 作为辅助文档，不应继续膨胀成第二套主文档
- 方法主线的变化，优先落到 `docs/项目开发主干流程.md`
- 能力边界的变化，优先落到 `docs/能力地图.md`
- 理解框架的变化，优先落到 `docs/用户心智模型.md`
- 新增、删除或重命名 `docs/*.md` 时，必须同步检查 `docs/INDEX.md`
- `docs/INDEX.md` 只维护 `docs/` 子目录的导航，不重复维护根目录元文档职责

何时考虑物理分级：
- `docs/` 数量超过 8 到 10 篇
- 核心文档 / 辅助文档的边界已经稳定较长时间
- `docs/INDEX.md` 已明显拥挤，单页导航成本上升

在此之前，不新增 `docs/core/`、`docs/support/` 等物理子目录。

### 何时引入 rules / plugins

默认情况下，本 blueprint 不把 `rules/` 或 `plugins/` 当成默认大规模主结构层。

当前仓库的例外：
- 已保留一组系统级最小规则：`writing`、`file-naming`、`workflow`、`testing`、`security`、`git`
- 它们只承载跨项目都较稳定的轻量约束
- 这不代表本 blueprint 已转向“默认依赖 rules 承载完整方法论或项目细则”

引入 `rules/` 的信号：
- 项目级约束已经明显按路径或子域分化
- 项目根 `CLAUDE.md` 继续增长会失控
- 同一项目里不同目录需要不同的 Claude 行为约束

引入 `plugins/` 的信号：
- 需要接入新的外部能力，而不是只补文档或规范
- 需要封装新的工具链能力
- 现有 `commands` / `skills` / `hooks` 已不足以支撑目标能力

维护要求：
- 当 `rules/` 从“少量系统级规则”升级为“正式主结构层”时，更新 `PLAYBOOK.md` 说明它在范式中的位置
- 引入 `plugins/` 后，更新 `README.md` 说明安装和使用方式
- 任一者进入标准范式后，更新 `WHY.md` 说明为何不再维持当前精简路线

### 草稿何时升格

草稿箱治理已拆到 `DRAFTS-MAINTAINING.md`。

这里只保留摘要：

- 草稿箱按“资产类型 × 生命周期”管理
- 生命周期是主线，主题只是阶段内的辅助检索入口
- 当前推荐只在高密度阶段按主题补一层目录，例如 `drafts/prompts/wip/`
- 草稿稳定后，应尽快迁入正式文档、正式 prompt、少量真正必要的 `skills/` 或 `commands/`

需要判断：

- 该内容现在属于哪个阶段
- 是否值得继续投入
- 该升格到哪个正式资产
- 是否还需要继续保留在草稿箱

详细规则、心智模型和整理流程，统一看 `DRAFTS-MAINTAINING.md`。

### 草稿整理流程

草稿整理的完整流程已拆到 `DRAFTS-MAINTAINING.md`。

这里的要求只有两条：

- `drafts/` 积累较多文件时，要定期整理，不要长期堆积
- 提交较大改动前，优先先整理一遍相关草稿

### Prompt 与 Skill 的边界

当前仓库默认立场：

- 自写方法论、模板、检查清单、提示词母版，优先放 `drafts/prompts/`
- 只有成熟、稳定、边界清晰、确实像“运行时操作手册”的能力，才考虑放 `skills/`
- 不确定是否值得进入运行层时，先放 `drafts/prompts/wip/`

判断标准：

- 更像一次任务可直接复制使用的内容 → `drafts/prompts/`
- 更像长期说明或边界解释 → `docs/` 或 `drafts/docs/`
- 更像运行时需要按意图加载的稳定能力 → `skills/`

补充：

- 文件命名风格属于独立的系统级约束，不并入 `rules/writing.md`
- 这类约束优先单独写成 rule，例如 `rules/file-naming.md`

### 新增或修改 skill
运行层资产维护规则已移到 `RUNTIME-MAINTAINING.md`。

### 新增或修改 command
运行层资产维护规则已移到 `RUNTIME-MAINTAINING.md`。

### settings.json 怎么维护
运行层资产维护规则已移到 `RUNTIME-MAINTAINING.md`。

### 新增或修改 hook
运行层资产维护规则已移到 `RUNTIME-MAINTAINING.md`。

### 新增或修改 agent
运行层资产维护规则已移到 `RUNTIME-MAINTAINING.md`。

### 新增或修改部署脚本

要改：
- `scripts/backup-claude.sh`
- `scripts/deploy-to-claude.sh`
- `scripts/show-plugin-install-commands.sh`
- `plugin-install-plan.md`
- `README.md`
- 如部署模型变化，更新 `WHY.md`

改完至少验证：
- `bash -n scripts/*.sh`
- `bash scripts/deploy-to-claude.sh --dry-run`
- `bash scripts/show-plugin-install-commands.sh`

补充规则：
- `plugin-install-plan.md` 不是自由格式文档，而是脚本直接解析的 Markdown 数据源
- 修改二级标题名、列表格式或插件条目语法时，必须同步检查 `scripts/show-plugin-install-commands.sh`

### 新增或修改模板
运行层资产维护规则已移到 `RUNTIME-MAINTAINING.md`。

---

## 5. 标准迭代流程

每次改动本仓库，按这个顺序：

1. 修改仓库文件
2. 检查是否需要更新 `deploy-manifest.txt`
3. 检查是否需要更新 `README.md`
4. 检查是否需要更新 `WHY.md`
5. 运行：

```bash
bash scripts/deploy-to-claude.sh --dry-run
```

6. 如果 dry-run 正常，正式部署：

```bash
bash scripts/deploy-to-claude.sh
```

7. 进入 Claude TUI，运行：

```text
/smoke-test
```

8. 按需手工验证 hooks / skills / arch / rev

---

## 6. 发布前检查清单

- [ ] `deploy-manifest.txt` 是否仍然准确
- [ ] `README.md` 的命令是否仍可直接执行
- [ ] `WHY.md` 是否遗漏了新的设计决策
- [ ] `/smoke-test` 是否仍然有效
- [ ] `acceptance/` 下的 fixtures 是否还能用于验收
- [ ] `bash -n scripts/backup-claude.sh scripts/deploy-to-claude.sh scripts/show-plugin-install-commands.sh` 是否通过

---

## 7. 什么情况下必须更新 WHY.md

出现以下任一情况时，必须考虑更新 `WHY.md`：

- 部署模型变化
- `deploy-manifest.txt` 的边界策略变化
- hook 的职责边界变化
- agent 数量或角色定位变化
- 仓库与 `~/.claude` 的关系变化

原则：
- 只是改实现细节，不一定更新 `WHY.md`
- 只要“为什么这么设计”发生变化，就应该更新 `WHY.md`
