# Maintaining Blueprint Runtime Assets

> **文档职责**：说明蓝图运行层资产如何维护、联动更新与验证。
> **适用范围**：`CLAUDE.md`、`settings.json`、`rules/`、`hooks/`、`skills/`、`agents/`、`commands/`、`templates/`
> **目标读者**：维护这套 `~/.claude` 蓝图的人。

---

## 1. 运行层资产各管什么

- `CLAUDE.md`：全局轻量入口、总约束、skill/rule 指针
- `settings.json`：Claude Code 官方 JSON 配置，控制 model / permissions / hooks / env
- `rules/`：轻量、稳定、跨任务复用的总原则；当前仅保留最小验证示例
- `hooks/`：关键动作的自动拦截或提醒
- `skills/`：某一类任务的完整工作方式
- `agents/`：带角色的分析或审查助手
- `commands/`：显式进入某个工作流阶段
- `templates/`：项目初始化或文档生成时的稳定骨架

判断原则：
- 需要全局入口、总约束、指针 → 改 `CLAUDE.md`
- 需要官方配置字段、权限、hooks 注册 → 改 `settings.json`
- 需要轻量总原则 → 改 `rules/`
- 需要自动触发的强制或提醒 → 改 `hooks/`
- 需要一类任务的完整方法 → 改 `skills/`
- 需要带角色的分析或审查 → 改 `agents/`
- 需要显式流程入口 → 改 `commands/`
- 需要稳定初稿或结构骨架 → 改 `templates/`

---

## 2. 运行层联动规则

- 新增会部署到 `~/.claude` 的目录或文件，检查 `deploy-manifest.txt`
- 改动运行层使用方式，检查 `README.md`
- 改动能力边界，检查 `docs/能力地图.md`
- 改动标准使用场景，检查 `docs/工作流参考.md`
- 改动项目主干方法，检查 `PLAYBOOK.md` 或 `docs/项目开发主干流程.md`
- 改动设计边界或仓库立场，检查 `WHY.md`

---

## 3. `CLAUDE.md` 怎么维护

要点：
- 保持轻量，优先做总约束与入口指针
- 不把完整工作流、长规则表、技术栈细节直接堆进 `CLAUDE.md`
- 当某类规则明显增长时，优先下沉到 `skills/` 或 `rules/`

改完至少验证：
- 行数仍然可控
- skill / rule 指针仍然准确
- 部署后 Claude 能按入口正确路由

---

## 4. `settings.json` 怎么维护

要点：
- `$schema` 使用当前官方 schema URL
- `settings.json` 只保留官方 schema 支持的字段，不添加自定义 `comment`
- `hooks` 对象顶层只能放合法事件名
- 环境变量使用 `env` 字段，不使用 `environment`
- 示例说明写到 `README.md` 或本文件，不写进真实配置文件

改完至少验证：
- `settings.json` JSON 语法正确
- VS Code 不再出现 schema 红线
- 部署后运行 `/doctor`，确认没有 schema 或 hook event 报错

---

## 5. `rules/` 怎么维护

要点：
- `rules/` 只放轻量、稳定、跨任务复用的总原则
- 当前仓库仅保留最小验证示例，不把 `rules/` 当成默认主结构层
- 当 `CLAUDE.md` 继续膨胀，且规则已经明显按主题或路径分化时，再考虑扩大使用

改完至少验证：
- 规则足够短，不演化成缩水版 skill
- 与对应 skill 不重复、不冲突
- 部署后能在目标任务里被正确读到

---

## 6. 新增或修改 hook

要改：
- `hooks/...`
- 如 hook 注册规则变化，更新 `settings.json`
- 如行为变化，更新 `README.md`
- 如设计边界变化，考虑更新 `WHY.md`

改完至少验证：
- 部署后手工触发对应场景

---

## 7. 新增或修改 skill

要改：
- `skills/...`
- 如有新目录需要部署，检查 `deploy-manifest.txt`
- 如触发方式或用途变化，更新 `README.md`
- 如能力边界变化，更新 `docs/能力地图.md`

改完至少验证：
- `bash scripts/deploy-to-claude.sh --dry-run`
- 部署后在 Claude TUI 中触发对应 skill

---

## 8. 新增或修改 agent

要改：
- `agents/...`
- 如 agent 职责变化，更新 `WHY.md`
- 如用户需要知道如何验收，更新 `README.md`

改完至少验证：
- 用 `acceptance/` 里的样例手工测一遍

---

## 9. 新增或修改 command

要改：
- `commands/...`
- 如 README 中有使用说明，更新 `README.md`
- 如 command 改变了能力边界，更新 `docs/能力地图.md`
- 如 command 形成了新的标准使用场景，更新 `docs/工作流参考.md`
- 如 command 用于验收，更新“验收”小节
- 如 command 影响项目生命周期主线，更新“标准项目生命周期”说明

改完至少验证：
- `/smoke-test` 或对应 command 能正常执行

---

## 10. 新增或修改模板

要改：
- `templates/...`
- 如模板字段、章节或初始化产物变化，更新 `README.md`
- 如模板改变了项目标准范式，更新 `WHY.md`

改完至少验证：
- `/init-architecture` 的产出是否仍与模板一致
- `bash scripts/deploy-to-claude.sh --dry-run`
