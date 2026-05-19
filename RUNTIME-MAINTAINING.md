# Maintaining Blueprint Runtime Assets

> **文档职责**：说明蓝图运行层资产如何维护、联动更新与验证。
> **适用范围**：`CLAUDE.md`、`settings.json`、`rules/`、`hooks/`、`skills/`、`agents/`、`commands/`、`templates/`
> **目标读者**：维护这套 `~/.claude` 蓝图的人。
> **当前立场**：运行层尽量保持最小；自写方法论、模板、检查清单默认先沉淀到 `prompts/meta/` 或 `drafts/prompts/`。只有当路由逻辑已经高度稳定，且需要运行时长期复用时，才允许收敛为 `skill + references` 形态。

---

## 1. 运行层资产各管什么

- `CLAUDE.md`：全局轻量入口、总约束
- `settings.json`：Claude Code 官方 JSON 配置，控制 model / permissions / hooks / env
- `rules/`：轻量、稳定、跨任务复用的总原则；当前保留少量系统级最小规则
- `hooks/`：关键动作的自动拦截或提醒
- `skills/`：少量成熟、稳定、真正适合运行时加载的能力；可包含极少量薄调度 skill
- `agents/`：带角色的分析或审查助手
- `commands/`：显式进入某个工作流阶段
- `templates/`：项目初始化或文档生成时的稳定骨架

判断原则：
- 需要全局入口、总约束、指针 → 改 `CLAUDE.md`
- 需要官方配置字段、权限、hooks 注册 → 改 `settings.json`
- 需要轻量总原则 → 改 `rules/`
- 需要自动触发的强制或提醒 → 改 `hooks/`
- 需要一类任务的完整方法，且已经高度稳定 → 改 `skills/`
- 需要在运行层判断“当前该用哪份方法论”，并长期复用对应真源 → 可改 `skills/`
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
- 当某类规则明显增长时，优先下沉到 `prompts/meta/`、`drafts/prompts/` 或 `rules/`

改完至少验证：
- 行数仍然可控
- 运行层入口是否仍然准确
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
- 当前仓库保留少量系统级最小规则，不把 `rules/` 当成默认主结构层
- 当 `CLAUDE.md` 继续膨胀，且规则已经明显按主题或路径分化时，再考虑扩大使用
- 默认不写 `paths`
- 不要写 `paths: []`；需要全局规则时，直接省略 `paths` 字段
- `paths` 不是“是否加载”的开关，而是“在哪些路径下执行”的作用域提示
- 因此带 `paths` 的规则也应尽量保持短、边界清晰，避免把复杂流程塞进 `rules/`
- 只有在规则之间存在作用域边界，或不同目录确实需要不同约束时，才添加 `paths`
- 如果没有作用域冲突，优先全局规则；这样比依赖模型自行判断路径更稳
- 一旦开始按路径拆规则，要保持写法统一：默认无 `paths`，只有必要时才添加明确的目录匹配

当前这组最小规则的职责边界：
- `user-background.md`：用户背景、理解偏好、默认技术上下文
- `workflow.md`：任务推进与协作判断规则
- `testing.md`：测试、验证与完成声明规则
- `security.md`：安全边界与敏感信息约束
- `git.md`：提交边界与提交信息默认规则
- `writing.md`：文档表达、结构与链接约束
- `file-naming.md`：文件命名、后缀与重命名规则

维护判断：
- 如果一条规则回答的是“这个用户是谁、擅长什么、哪里可能需要额外解释”，放 `user-background.md`
- 如果一条规则回答的是“任务应该怎么推进、怎么给判断”，放 `workflow.md`
- 如果一条规则回答的是“什么情况下才算验证成立”，放 `testing.md`
- 如果一条规则回答的是“文档怎么写更清楚”，放 `writing.md`
- 如果一条规则回答的是“文件该怎么命名或重命名”，放 `file-naming.md`
- 如果一条规则同时覆盖多个问题域，先拆分归位，再决定是否写入

不要这样做：
- 不要把背景事实、协作规则、验证规则混在同一个文件里
- 不要在 `writing.md` 重复维护命名规则
- 不要在 `workflow.md` 重复维护测试细则
- 不要为了形式统一，把本应留在 `CLAUDE.md` 的核心总原则过度下沉到 `rules/`

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

新增前先判断：
- 这是不是方法论 / 模板 / 检查清单
- 如果是，默认先放 `prompts/meta/` 或 `drafts/prompts/`
- 只有触发场景稳定、输出稳定、边界清晰，而且需要运行时长期复用时，才收敛为 `skills/<name>/references/` 真源，并由 `SKILL.md` 做薄调度

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
