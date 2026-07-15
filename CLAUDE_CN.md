<!-- WORKFLOW_START -->
## 工作流偏好

**在动任何代码之前，你必须通过 `AskUserQuestion` 工具询问用户使用哪种工作流。没有例外——哪怕是单行修改、拼写修正或"显而易见"的改动。**

### 触发场景（命中任意一条 → 必须询问，且必须在动代码之前询问）

- 编写新代码（新函数 / 文件 / 模块）
- 修改现有代码（编辑、重构、修 bug、风格调整——**单行字符串改动也算**）
- 新增 / 修改测试
- 修改构建配置（package.json / requirements.txt / vite.config / tsconfig / Dockerfile / Makefile / Alembic migration 等）
- 编写实现计划 / 设计文档（plan 工作流的第一步本身就是写计划）

### 无需询问（不属于代码任务）

- 纯讨论 / 问答 / 解释（"X 是什么"、"该用哪个库"）
- 阅读代码 / 阅读文档 / 查符号
- 运行命令（git / pytest / npm run / deploy 等——不修改源码）
- 编辑 `CLAUDE.md` / `settings.json` / auto-memory / 日报等 meta-config / 元数据文件
- 用户已**在当前 session 中**明确选定工作流，且仍处于同一连续任务内（新话题需重新询问）

### 两个选项

1. **plan → subagent → review → verify**：四个阶段全部必做，其中 Subagent / Review 两个阶段的子任务派发遵循 **chord 模型**（借用 Celery Canvas 的说法）——把互相独立的子任务当成一个并行分组（header）一次性发出，只在该组全部返回后做一次汇合（callback），而不是把整个任务当线性队列逐项派发、逐项等待。
   - **Plan**：纯架构权衡用 `voltagent-qa-sec:architect-reviewer`；一般规划用内置的 `Plan` agent。**Plan 阶段必须显式给出任务依赖图**：哪些子任务互不依赖、可归入同一个 chord 分组并行执行；哪些子任务依赖前面分组的产出、必须排在后面执行。不要只给一份看不出依赖关系的线性步骤清单。
   - **Subagent（执行）**：按技术栈和领域派发专精 agent。语言类专精走 `voltagent-lang:*`（如 `voltagent-lang:typescript-pro` / `voltagent-lang:react-specialist` / `voltagent-lang:python-pro` / `voltagent-lang:rust-engineer`）；功能类专精走 `voltagent-core-dev:*`（如 `voltagent-core-dev:frontend-developer` / `voltagent-core-dev:backend-developer` / `voltagent-core-dev:fullstack-developer` / `voltagent-core-dev:api-designer`）；都不匹配时用内置的 `general-purpose` agent。**机制层面的硬约束（不是建议）**：同一 chord 分组内的子任务，必须在同一条 assistant 消息里一次性发出对应数量的 Agent 调用（多个 tool_use），而不是"调用一个 → 等结果回来 → 再调用下一个"——后一种串行调用节奏才是工作流变慢的真正原因，光在文字上说"可以并行"不会改变实际调用动作，必须在动作层面强制批量发出。如果某个分组的产出不急着用（汇合前还有别的事可以先做），优先用 Agent 工具默认的后台执行（不要传 `run_in_background: false`），让多个子 agent 同时后台跑、陆续收到完成通知，而不是每派一个就同步阻塞等待。只有当后一分组确实需要前一分组的输出作为输入时，才允许排队等待。
   - **Review**：按风险维度挑选 reviewer；同一批 reviewer 属于同一个 chord 分组，必须按上面同样的机制一次性并行派发。代码质量 → `voltagent-qa-sec:code-reviewer`；安全 → `voltagent-qa-sec:security-auditor` / `voltagent-qa-sec:penetration-tester`；性能 → `voltagent-qa-sec:performance-engineer`；架构 → `voltagent-qa-sec:architect-reviewer`；可访问性 → `voltagent-qa-sec:accessibility-tester`。
   - **Verify**：宣布完成前，你必须运行 tests / build / lint / type-check 拿到通过的证据。只凭 diff 判断成功是不允许的。
2. **Just do it（直接做）**：跳过完整的 plan/subagent 工作流，以任务所需的最小范围直接执行。
   - 当任务是 bug / 测试失败 / 异常行为时：先用 `voltagent-qa-sec:debugger` 或 `voltagent-qa-sec:error-detective` 定位根因再动手。
   - 当修改测试或新增可测逻辑时：先写测试再写实现；需要时用 `voltagent-qa-sec:test-automator`。
   - 宣布完成前，你必须运行 tests / build / lint 拿到证据；只凭 diff 判断成功是不允许的。
   - 只在用户明确要求时才提交。

### 严格规则（违反即错误）

- **不要**凭自己对任务大小的判断跳过询问。"看起来很小"不是跳过的理由。
- **不要**默认进入任一工作流。
- **不要**先改代码再询问。必须先询问。
- **你必须使用** `AskUserQuestion` 工具来询问——不要用纯文本（用户点击选择更方便，且该工具会留下痕迹）。
- 只有在用户回复之后，才开始任何代码相关操作（Read / Edit / Write 等）。
- **不要**把可以并行的 chord 分组拆开逐个串行派发子 agent：先调一个、等结果、再调下一个——只要两个子任务之间不存在真实依赖（后者需要前者的输出作为输入），就默认视为独立，必须在同一条消息内批量并行发出，不允许因为"习惯一次调一个"而退化成串行。
- 当任务规模很大、chord 分组和层级很多、在对话里手动编排开始变得吃力时（比如需要多轮"并行 → 汇合 → 再并行"），可以主动向用户提出"要不要改用 Workflow 工具做正式编排"，但不能擅自调用 Workflow 工具——是否切换仍需用户显式同意（这是 Workflow 工具自身的门槛，不受本条规则免除）。
<!-- WORKFLOW_END -->

<!-- NO_FALLBACK_START -->
## 不擅自添加兜底策略

编写代码时不要为了"更稳"擅自添加 fallback、silent catch、默认值吞错、空结果兼容或降级逻辑。除非需求明确要求，遇到异常应让错误快速暴露，便于定位和修复。
<!-- NO_FALLBACK_END -->

<!-- LANGUAGE_START -->
## 语言偏好

**默认使用中文回复用户**——包括正文、总结、提问、进度更新等所有面向用户的文本，不论任务涉及的代码、子 agent 或工具返回内容是什么语言。

- 派发给 Agent/subagent 的执行结果、审查意见即使原文是英文，转述给用户时必须翻译改写成中文，不要直接搬运英文原文。
- 代码、命令、路径、协议名、库名等技术对象保持英文原文，不强行翻译。
- 仅当用户主动用英文提问，或明确要求用英文回复时，才切换成英文。
<!-- LANGUAGE_END -->
