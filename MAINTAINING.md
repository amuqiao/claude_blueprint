# Maintaining Claude Blueprint

> **文档职责**：说明这个仓库后续如何维护、如何迭代、改完后如何验证。
> **适用场景**：新增 skill / command / hook / agent、调整部署边界、修改脚本、准备发布更新前阅读。
> **目标读者**：本仓库维护者。
> **维护规范**：只要部署模型、目录职责、验收流程或维护流程发生变化，就同步更新本文档。

---

## 1. 核心文档各管什么

- `README.md`：给使用者看，讲安装、部署、更新、验收
- `PLAYBOOK.md`：定义开发范式，说明项目生命周期和阶段边界
- `WHY.md`：记录为什么这样设计，解释关键决策
- `MAINTAINING.md`：给维护者看，说明仓库治理、文档治理、发布与检查
- `RUNTIME-MAINTAINING.md`：说明运行层资产（`CLAUDE.md`、`settings.json`、`rules/`、`hooks/`、`skills/`、`agents/`、`commands/`、`templates/`）怎么维护

判断原则：
- 用户怎么用 → 改 `README.md`
- 先做什么、后做什么、阶段怎么切 → 改 `PLAYBOOK.md`
- 为什么这样设计 → 改 `WHY.md`
- 仓库治理、文档治理、发布检查 → 改 `MAINTAINING.md`
- 运行层资产维护规则 → 改 `RUNTIME-MAINTAINING.md`

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

何时考虑物理分级：
- `docs/` 数量超过 8 到 10 篇
- 核心文档 / 辅助文档的边界已经稳定较长时间
- `docs/INDEX.md` 已明显拥挤，单页导航成本上升

在此之前，不新增 `docs/core/`、`docs/support/` 等物理子目录。

### 何时引入 rules / plugins

默认情况下，本 blueprint 不把 `rules/` 或 `plugins/` 当成默认大规模主结构层。

当前仓库的例外：
- 已保留一个最小 `rules/writing.md` 示例
- 它的目的主要是验证 rules 机制可用
- 这不代表本 blueprint 已转向“默认依赖 rules 拆分 CLAUDE.md”

引入 `rules/` 的信号：
- 项目级约束已经明显按路径或子域分化
- 项目根 `CLAUDE.md` 继续增长会失控
- 同一项目里不同目录需要不同的 Claude 行为约束

引入 `plugins/` 的信号：
- 需要接入新的外部能力，而不是只补文档或规范
- 需要封装新的工具链能力
- 现有 `commands` / `skills` / `hooks` 已不足以支撑目标能力

维护要求：
- 当 `rules/` 从“最小验证示例”升级为“正式主结构层”时，更新 `PLAYBOOK.md` 说明它在范式中的位置
- 引入 `plugins/` 后，更新 `README.md` 说明安装和使用方式
- 任一者进入标准范式后，更新 `WHY.md` 说明为何不再维持当前精简路线

### 草稿何时升格

本仓库按“资产类型 × 生命周期”维护草稿：

- `drafts/docs/`：普通文档草稿，允许零散、试探、未收敛
- `drafts/docs/wip/`：正在重点整理中的文档草稿，结构和判断仍可能明显变化
- `drafts/docs/next/`：当前主线候选稿，已经形成较稳定方案，但还要继续实践验证
- `drafts/docs/archived/`：已废弃或已退出当前主线的历史文稿
- `drafts/prompts/wip/`：还在打磨的 prompt 草稿
- `drafts/prompts/next/`：当前主线候选 prompt，已可反复使用，但还没升为正式 `prompts/`
- `drafts/prompts/archived/`：已废弃或已被正式 prompt / skill 吸收的 prompt 草稿

进入 `drafts/docs/wip/` 的信号：
- 这篇草稿会反复影响后续设计判断
- 内容已经不只是随手记录，而是在形成方法论
- 结构、结论或边界还可能继续大改

从 `drafts/docs/wip/` 进入 `drafts/docs/next/` 的信号：
- 当前主线已经比较清楚
- 已经准备拿去真实使用或对照实践验证
- 还不想立即升为正式 `docs/`

从 `drafts/docs/next/` 升格为正式文档的信号：
- 经过实践验证
- 判断已经稳定
- 已开始反复被引用
- 需要作为当前标准执行

升格路径：
- 方法层稳定了 → `PLAYBOOK.md`
- 设计决策稳定了 → `WHY.md`
- 维护流程稳定了 → `MAINTAINING.md` 或 `RUNTIME-MAINTAINING.md`
- 使用方式稳定了 → `README.md`
- Prompt 稳定且可直接复用 → `prompts/`
- Prompt 已抽象成方法与工作流 → `skills/` 或 `commands/`

### 草稿整理流程

当 `drafts/` 目录积累了较多文件时，定期整理。

**推荐使用 `/distill-draft` 命令**：

```text
# 提炼具体草稿
/distill-draft drafts/docs/某想法.md

# 批量查看所有草稿状态
/distill-draft --batch
```

**手动整理时的分析框架**（如果不用命令）：

1. **读取草稿**：优先从 `drafts/docs/` 或 `drafts/prompts/` 中读取

2. **分析维度**：
   - 核心观点是什么？（1-3 句话）
   - 内容类型？（零散想法 / 思维链 / 方法论探索 / 设计决策 / 踩坑记录）
   - 成熟度？（仅记录 / 初步判断 / 接近定稿）
   - 影响范围？（仅当前项目 / 跨项目通用 / 影响范式 / 影响维护流程）

3. **判断去向**：
   - 文档类仅记录 → 保留在 `drafts/docs/`
   - 文档类初步判断 + 会反复影响设计 → `drafts/docs/wip/`
   - 文档类已形成当前主线、待实践验证 → `drafts/docs/next/`
   - Prompt 类仍在打磨 → `drafts/prompts/wip/`
   - Prompt 类已形成当前主线、待实践验证 → `drafts/prompts/next/`
   - 接近定稿 + 影响方法层 → `PLAYBOOK.md`
   - 接近定稿 + 影响设计决策 → `WHY.md`
   - 接近定稿 + 影响维护流程 → `MAINTAINING.md` 或 `RUNTIME-MAINTAINING.md`
   - 接近定稿 + 影响使用方式 → `README.md`
   - Prompt 已稳定可复用 → `prompts/`
   - Prompt 已被更高层机制吸收 → `drafts/prompts/archived/`

4. **整理并迁移**：
   - 提炼核心观点（3-5 条）
   - 补充"为什么"和"什么时候用"
   - 整合到目标文档的合适位置
   - 在草稿开头标注"✓ 已升格到 XXX"

**推荐频率**：
- 每次向仓库提交较大改动前，先整理一遍草稿
- 或每周/每月定期整理一次
- 或当 `drafts/docs/*.md`、`drafts/docs/wip/`、`drafts/docs/next/`、`drafts/prompts/wip/`、`drafts/prompts/next/` 累积较多时触发整理

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
- `README.md`
- 如部署模型变化，更新 `WHY.md`

改完至少验证：
- `bash -n scripts/*.sh`
- `bash scripts/deploy-to-claude.sh --dry-run`

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
- [ ] `bash -n scripts/backup-claude.sh scripts/deploy-to-claude.sh` 是否通过

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
