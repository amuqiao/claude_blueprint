# Maintaining Claude Blueprint

> **文档职责**：说明这个仓库后续如何维护、如何迭代、改完后如何验证。
> **适用场景**：新增 skill / command / hook / agent、调整部署边界、修改脚本、准备发布更新前阅读。
> **目标读者**：本仓库维护者。
> **维护规范**：只要部署模型、目录职责、验收流程或维护流程发生变化，就同步更新本文档。

---

## 1. 三份核心文档各管什么

- `README.md`：给使用者看，讲安装、部署、更新、验收
- `WHY.md`：记录为什么这样设计，解释关键决策
- `MAINTAINING.md`：给维护者看，说明以后怎么改、改哪里、改完怎么验

判断原则：
- 用户怎么用 → 改 `README.md`
- 为什么这样设计 → 改 `WHY.md`
- 维护者以后如何继续演进 → 改 `MAINTAINING.md`

---

## 2. 部署边界怎么维护

本仓库采用“仓库是配置源，`~/.claude` 是部署目标”的模型。

真正会部署到 `~/.claude` 的内容，由 `deploy-manifest.txt` 白名单决定。

当前会部署的路径：
- `CLAUDE.md`
- `settings.json`
- `hooks/`
- `skills/`
- `agents/`
- `commands/`
- `templates/`

默认不部署的内容：
- `scripts/`
- `acceptance/`
- `drafts/`
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

### 新增或修改 skill

要改：
- `skills/...`
- 如有新目录需要部署，检查 `deploy-manifest.txt`
- 如触发方式或用途变化，更新 `README.md`

改完至少验证：
- `bash scripts/deploy-to-claude.sh --dry-run`
- 部署后在 Claude TUI 中触发对应 skill

### 新增或修改 command

要改：
- `commands/...`
- 如 README 中有使用说明，更新 `README.md`
- 如 command 用于验收，更新“验收”小节
- 如 command 影响项目生命周期主线，更新“标准项目生命周期”说明

改完至少验证：
- `/smoke-test` 或对应 command 能正常执行

### 新增或修改 hook

要改：
- `hooks/...`
- 如 hook 注册规则变化，更新 `settings.json`
- 如行为变化，更新 `README.md`
- 如设计边界变化，考虑更新 `WHY.md`

改完至少验证：
- 部署后手工触发对应场景

### 新增或修改 agent

要改：
- `agents/...`
- 如 agent 职责变化，更新 `WHY.md`
- 如用户需要知道如何验收，更新 `README.md`

改完至少验证：
- 用 `acceptance/` 里的样例手工测一遍

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

要改：
- `templates/...`
- 如模板字段、章节或初始化产物变化，更新 `README.md`
- 如模板改变了项目标准范式，更新 `WHY.md`

改完至少验证：
- `/init-architecture` 的产出是否仍与模板一致
- `bash scripts/deploy-to-claude.sh --dry-run`

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
