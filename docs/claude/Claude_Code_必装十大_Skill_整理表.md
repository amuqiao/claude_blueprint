# Claude Code 必装十大 Skill

> **文档职责**：覆盖 10 个常见 Skill 的核心价值、安装命令和触发方式，供选型和安装参考。
> **维护规范**：Skill 名单、安装来源或触发方式变化时同步更新。

---

## 一、先建整体理解

这 10 个 Skill 覆盖 4 类能力，不是 10 个平行插件：

```
Claude Code Skill
├── 流程增强        Superpowers · Planning with Files · Ralph Loop
├── 质量保障        Code Review · Code Simplifier · Webapp Testing
├── 产出增强        UI UX Pro Max · PPTX
└── 能力扩展        MCP Builder · Skill Creator
```

更实用的使用思路：**先判断你缺的是哪类，再按优先级安装。**

---

## 二、安装前须知

所有 Skill 都安装到 Claude Code 原生扫描目录：

```
~/.claude/skills/<skill-name>/   ← 全局（推荐）
.claude/skills/<skill-name>/     ← 项目级
```

安装后检查 3 件事：
- 目录存在于 `~/.claude/skills/`
- 入口文件是 `SKILL.md`
- 相关资源子目录（references/、scripts/）没有丢失

验证是否生效：启动 Claude Code 后运行 `/skills`，确认列表中出现对应 Skill 名称。

---

## 三、十大 Skill 详情

### 流程增强

---

#### 1. Superpowers
**核心价值**：完整的 AI 编程工作方法论。启动即自动拦截，引导澄清需求、拆分规划、TDD 执行，全程无需手动触发。

**适合场景**：所有正式开发任务；想让 Claude 自动走完"需求 → 规划 → 执行 → 验收"全流程。

**安装**（推荐，官方插件市场）：
```bash
# 在 Claude Code session 内运行
/plugin install superpowers@claude-plugins-official
```

**触发方式**：自动触发，无需显式调用。Skill 会在识别到编程任务时主动介入。

---

#### 2. Planning with Files
**核心价值**：把 Claude 的"工作记忆"写入文件（`task_plan.md`、`findings.md`、`progress.md`），避免上下文压缩后关键信息丢失。

**适合场景**：长期任务、复杂需求收敛、多阶段推进；任何需要跨 session 保持上下文连续性的场景。

**安装**：
```bash
npx skills add https://github.com/OthmanAdi/planning-with-files --skill planning-with-files
```

**触发方式**：显式调用，例如：`用 Planning with Files 的方式把这次规划落到文件里`

---

#### 3. Ralph Loop
**核心价值**：通过 Stop Hook 拦截 Claude 提前退出，把任务强制做成闭环——Claude 工作 → 尝试退出 → 被拦截 → 重新喂入同一 prompt → 循环直到完成。

**适合场景**：长任务、复杂功能实现；TDD 闭环；容易半途收尾的场景。

**安装**（官方插件）：
```bash
# 方式 A：官方插件市场
/plugin marketplace add MarioGiancini/ralph-loop-setup
/plugin install ralph-loop-setup
```

**触发方式**：显式调用：
```
/ralph-loop "实现用户登录功能，完成后输出 <promise>DONE</promise>" --max-iterations 20
```

---

### 质量保障

---

#### 4. Code Review
**核心价值**：多智能体并行代码审查，涵盖 17+ 语言，渐进式加载（核心 ~190 行，语言指南按需加载），按严重程度（blocking / important / nit）分类输出。

**适合场景**：PR 审查、提交前质量门禁、回归检查。

**安装**：
```bash
git clone https://github.com/awesome-skills/code-review-skill.git \
  ~/.claude/skills/code-review-skill
```

**触发方式**：显式调用：`用 code-review-skill 审查这次改动` 或在 `.claude/commands/review.md` 里封装成 `/review`。

---

#### 5. Code Simplifier
**核心价值**：Anthropic 官方开源的代码整理 Agent，对已完成代码做二次精简——消除冗余、降低嵌套层级、改善命名，不改变任何外部行为。

**适合场景**：功能完成后的收口；PR 开出前的清理；长 session 后的代码整理。

**安装**（官方插件，推荐）：
```bash
# 在 Claude Code session 内运行
/plugin marketplace update claude-plugins-official
/plugin install code-simplifier
```

**触发方式**：显式调用：`用 code-simplifier agent 整理今天改动的代码`

---

#### 6. Webapp Testing
**核心价值**：Anthropic 官方出品，基于 Playwright 的 Web 自动化测试 Skill，支持服务器生命周期管理、截图、多 server 场景。

**适合场景**：前端页面回归、交互验证、CI 自动化测试留档。

**安装**（官方仓库）：
```bash
npx skills add https://github.com/anthropics/skills --skill webapp-testing
```

**触发方式**：显式调用：`/webapp-testing 访问 http://localhost:3000，完成登录流程并截图`

---

### 产出增强

---

#### 7. UI UX Pro Max
**核心价值**：设计数据库驱动的 UI 增强 Skill，内置 67 种 UI 风格、161 个配色方案、57 个字体搭配、99 条 UX 指南，覆盖 16 个技术栈。

**适合场景**：页面设计、改版、原型探索、需要明确设计语言的前端任务。

**安装**：
```bash
# 推荐：npx 安装
npx skills add https://github.com/nextlevelbuilder/ui-ux-pro-max-skill --skill ui-ux-pro-max

# 安装后如不在 ~/.claude/skills/，手动复制或软链
cp -r ~/.agents/skills/ui-ux-pro-max ~/.claude/skills/ui-ux-pro-max
# 或
ln -s ~/.agents/skills/ui-ux-pro-max ~/.claude/skills/ui-ux-pro-max
```

> ⚠️ 安装器实际落盘路径为 `~/.agents/skills/`，需手动同步到 `~/.claude/skills/`。
> ⚠️ 该 Skill 包含 `scripts/` 目录（Gen 评级 High Risk），如不需要脚本功能可删除：`rm -rf ~/.claude/skills/ui-ux-pro-max/scripts`

**触发方式**：显式调用 `/ui-ux-pro-max`，或直接描述 UI 任务，Claude 会根据 description 自动识别。

---

#### 8. PPTX
**核心价值**：Anthropic 官方出品，直接生成原生 `.pptx` 文件，减少手工排版负担。

**适合场景**：汇报材料、方案讲解、分享内容输出。

**安装**（官方仓库）：
```bash
npx skills add https://github.com/anthropics/skills --skill pptx
```

**触发方式**：显式调用：`用 pptx skill 生成一份 5 页的产品方案 PPT`

---

### 能力扩展

---

#### 9. MCP Builder
**核心价值**：四阶段框架引导开发高质量 MCP Server（Python 或 TypeScript），覆盖工具设计原则、实现模式和测试策略。

**适合场景**：从零开发 MCP Server；想减少踩坑时。

**安装**：
```bash
npx skills add https://github.com/anthropics/skills --skill mcp-builder
```

**触发方式**：显式调用：`用 mcp-builder skill 帮我设计这个 MCP Server 的工具结构`

---

#### 10. Skill Creator
**核心价值**：Anthropic 官方元技能，用于创建、修改、测试新 Skill，包含完整的 Skill 规范说明。

**适合场景**：现有 Skill 不够用时；想把重复需求沉淀成自己的 Skill；评审现有 Skill 结构。

**安装**（官方仓库）：
```bash
npx skills add https://github.com/anthropics/skills --skill skill-creator
```

**触发方式**：显式调用：`用 skill-creator 帮我创建一个新的 code-review Skill`

---

## 四、推荐安装顺序

如果今天刚开始补 Skill，建议按以下顺序：

**第一批（流程稳定）**：Planning with Files → Ralph Loop → Superpowers

**第二批（质量保障）**：Code Review → Code Simplifier → Webapp Testing

**第三批（产出与扩展）**：UI UX Pro Max → PPTX → MCP Builder → Skill Creator

逻辑：先补稳定性，再补质量，再补产出，最后补扩展。

---

## 五、推荐组合

| 组合 | 解决的问题 |
|------|-----------|
| Planning with Files + Ralph Loop | 规划留档 + 任务强制闭环 |
| Code Review + Code Simplifier | 先找问题，再做结构收口 |
| UI UX Pro Max + Webapp Testing | 先做界面，再自动化验证 |
| Ralph Loop + 任意复杂任务 | 避免长任务做到一半就停 |
| Skill Creator + 重复需求 | 把经验沉淀成可复用 Skill |