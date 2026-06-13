<!-- WORKFLOW_START -->
## 工作流偏好

**在触碰任何代码之前，你必须通过 `AskUserQuestion` 工具询问用户选择哪种工作流。无任何例外——哪怕是单行修改、错别字修复或"显而易见"的改动。**

### 触发场景（满足任意一条 → 必须先询问，且必须在动代码之前询问）

- 编写新代码（新函数 / 文件 / 模块）
- 修改已有代码（编辑、重构、修 bug、风格调整——**哪怕只改一行字符串也算**）
- 新增 / 修改测试
- 修改构建配置（package.json / requirements.txt / vite.config / tsconfig / Dockerfile / Makefile / Alembic migration 等）
- 编写实现方案 / 设计文档（方案工作流的第一步本身就是写方案）

### 无需询问（非代码任务）

- 纯讨论 / 问答 / 解释（"X 是什么"、"应该用哪个库"）
- 阅读代码 / 阅读文档 / 查找符号
- 运行命令（git / pytest / npm run / 部署等——不修改源码）
- 编辑 `CLAUDE.md` / `settings.json` / 自动记忆 / 日报及其他元配置 / 元数据文件
- 用户在**当前会话**中已明确选择了工作流，且仍处于同一个连续任务中（新话题需重新询问）

### 两种选项

1. **plan → subagent → review → verify**：四个阶段全部必须执行；每个阶段根据任务性质选择最合适的 skill / agent（不绑定固定列表）。选择原则：先看任务领域（语言 / 技术栈 / 功能），再查可用 agent 的描述是否匹配；没有精确匹配时退回通用 agent，不要强行套用不合适的专项角色。
   - **Plan**：默认用 `superpowers:writing-plans`；需求 / 方向模糊时先用 `superpowers:brainstorming`；纯架构权衡问题使用 `Plan` agent 或 `voltagent-qa-sec:architect-reviewer`。
   - **Subagent（执行）**：按技术栈和领域派发专项角色。语言专项走 `voltagent-lang:*`（如 `typescript-pro` / `react-specialist` / `python-pro` / `rust-engineer`）；功能专项走 `voltagent-core-dev:*`（如 `frontend-developer` / `backend-developer` / `fullstack-developer` / `api-designer`）；UI 设计走 `frontend-design` 或 `voltagent-core-dev:ui-designer`；没有匹配时用 `general-purpose` 或 `implementer`。多个独立子任务可并行时，用 `superpowers:dispatching-parallel-agents` 一次派发。
   - **Review**：按风险维度选评审角色；多维风险时并行跑多个。代码质量 → `code-reviewer` / `code-review:code-review` / `voltagent-qa-sec:code-reviewer`；安全 → `security-review` / `voltagent-qa-sec:security-auditor` / `voltagent-qa-sec:penetration-tester`；性能 → `voltagent-qa-sec:performance-engineer`；架构 → `voltagent-qa-sec:architect-reviewer`；可读性 / 冗余 → `simplify`；无障碍 → `voltagent-qa-sec:accessibility-tester`。
   - **Verify**：声明完成前必须使用 `superpowers:verification-before-completion`，或直接运行测试 / 构建 / lint / 类型检查并获取通过证据。仅凭 diff 判断成功不被允许。
2. **Just do it**：跳过完整的 plan/subagent 流程，以任务所需的最小范围直接执行。**开始前必须按顺序加载以下 skills**（与任务无关的 skill 只读前置字段；相关的按其指令执行）：
   - `andrej-karpathy-skills:karpathy-guidelines` — 通用编码规范（全局策略已强制执行，此处重申）
   - `superpowers:systematic-debugging` — 当任务是 bug / 测试失败 / 异常行为时，先用它定位根因，再动手
   - `superpowers:test-driven-development` — 涉及修改测试或新增可测试逻辑时，先写测试，再写实现
   - `superpowers:verification-before-completion` — 声明完成前必须运行测试 / 构建 / lint 取得证据；仅凭 diff 判断成功不被允许
     仅在用户明确要求时才提交。

### 严格规则（违反即错误）

- **不得**以自己对任务规模的判断跳过询问。"看起来很小"不是跳过的理由。
- **不得**默认进入任意一种工作流。
- **不得**先改代码再询问。询问必须在前。
- **必须**使用 `AskUserQuestion` 工具询问——不能用普通文本（工具让用户能点击选择，也留有记录）。
- 只有在用户回复后，才能开始任何与代码相关的操作（Read / Edit / Write 等）。
<!-- WORKFLOW_END -->

<!-- NO_FALLBACK_START -->
## 不擅自添加兜底策略

编写代码时不要为了"更稳"擅自添加 fallback、silent catch、默认值吞错、空结果兼容或降级逻辑。除非需求明确要求，遇到异常应让错误快速暴露，便于定位和修复。
<!-- NO_FALLBACK_END -->
