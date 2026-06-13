<!-- WORKFLOW_START -->
## Workflow Preference

**BEFORE TOUCHING ANY CODE, you MUST ask the user which workflow to use via the `AskUserQuestion` tool. NO EXCEPTIONS — even one-line edits, typo fixes, or "obvious" changes.**

### Trigger scenarios (hit any one → you MUST ask, and you MUST ask before touching code)

- Writing new code (new function / file / module)
- Modifying existing code (editing, refactoring, bug fixing, style changes — **a single-line string change counts too**)
- Adding / changing tests
- Changing build config (package.json / requirements.txt / vite.config / tsconfig / Dockerfile / Makefile / Alembic migration, etc.)
- Writing an implementation plan / design doc (the first step of the plan workflow is itself writing the plan)

### No need to ask (not a code task)

- Pure discussion / Q&A / explanation ("what is X", "which library should I use")
- Reading code / reading docs / looking up symbols
- Running commands (git / pytest / npm run / deploy, etc. — not modifying source code)
- Editing `CLAUDE.md` / `settings.json` / auto-memory / daily reports and other meta-config / metadata files
- The user has already explicitly chosen a workflow **in the current session** and is still within the same continuous task (a new topic requires asking again)

### The two options

1. **plan → subagent → review → verify**: all four stages are mandatory; for each stage pick the most fitting skill / agent based on the task's nature (not bound to a fixed list). Selection principle: first look at the task's domain (language / tech stack / function), then check whether an available agent's description matches; when there is no exact match, fall back to a general agent — do not force-fit an ill-suited specialist.
   - **Plan**: default `superpowers:writing-plans`; if the requirement / direction is vague, start with `superpowers:brainstorming`; for pure architecture trade-offs use the `Plan` agent or `voltagent-qa-sec:architect-reviewer`.
   - **Subagent (execution)**: dispatch specialist agents by tech stack and domain. Language specialists go through `voltagent-lang:*` (e.g. `typescript-pro` / `react-specialist` / `python-pro` / `rust-engineer`); functional specialists go through `voltagent-core-dev:*` (e.g. `frontend-developer` / `backend-developer` / `fullstack-developer` / `api-designer`); UI design goes through `frontend-design` or `voltagent-core-dev:ui-designer`; when nothing matches use `general-purpose` or `implementer`. When several independent subtasks can run in parallel, wrap them with `superpowers:dispatching-parallel-agents` to dispatch them in one shot.
   - **Review**: pick reviewers by risk dimension; run multiple in parallel for multi-dimensional risk. Code quality → `code-reviewer` / `code-review:code-review` / `voltagent-qa-sec:code-reviewer`; security → `security-review` / `voltagent-qa-sec:security-auditor` / `voltagent-qa-sec:penetration-tester`; performance → `voltagent-qa-sec:performance-engineer`; architecture → `voltagent-qa-sec:architect-reviewer`; readability / redundancy → `simplify`; accessibility → `voltagent-qa-sec:accessibility-tester`.
   - **Verify**: before claiming completion you MUST use `superpowers:verification-before-completion`, or directly run tests / build / lint / type-check to obtain passing evidence. Judging success from the diff alone is not allowed.
2. **Just do it**: skip the full plan/subagent workflow and execute directly at the minimal scope the task needs. **Before starting you MUST load the following skills in order** (for skills irrelevant to the task, read only the frontmatter; for relevant ones, follow their instructions):
   - `andrej-karpathy-skills:karpathy-guidelines` — general coding discipline (already enforced by global policy; reaffirmed here)
   - `superpowers:systematic-debugging` — when the task is a bug / test failure / unexpected behavior, use it to find the root cause before acting
   - `superpowers:test-driven-development` — when changing tests or adding testable logic, write the test before the implementation
   - `superpowers:verification-before-completion` — before claiming completion you MUST run tests / build / lint for evidence; judging success from the diff alone is not allowed
     Commit only when the user explicitly asks.

### Strict rules (violation = error)

- **Do NOT** skip asking based on your own judgment of task size. "It looks small" is not a reason to skip.
- **Do NOT** default into either workflow.
- **Do NOT** change code first and ask afterward. Asking must come first.
- **You MUST use** the `AskUserQuestion` tool to ask — not plain text (the user can click to choose more easily, and the tool leaves a trace).
- Begin any code-related action (Read / Edit / Write, etc.) only after the user replies.
<!-- WORKFLOW_END -->

<!-- NO_FALLBACK_START -->
## 不擅自添加兜底策略

编写代码时不要为了“更稳”擅自添加 fallback、silent catch、默认值吞错、空结果兼容或降级逻辑。除非需求明确要求，遇到异常应让错误快速暴露，便于定位和修复。
<!-- NO_FALLBACK_END -->