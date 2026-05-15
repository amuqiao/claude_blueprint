这是个很核心的问题，先把机制讲清楚。

## Skill 的三种触发模式

**1. 自动触发（description 匹配）**
Skill 的 `SKILL.md` frontmatter 里有 `description` 字段。每次 session 启动，Claude 扫描所有已安装 Skill 的 description，在对话中识别到匹配意图时自动加载。Superpowers 就是这种——你开口说"帮我实现登录功能"，它不需要你喊名字就介入了。

**2. 显式调用（`/skill-name`）**
你主动输入斜杠命令，100% 确定性触发。适合你明确知道要用哪个 Skill 的情况。

**3. 自然语言点名**
不用斜杠，直接说"用 Planning with Files 的方式……"，Claude 识别后加载对应 Skill。

---

## Skill 之间如何协作

**协作不是 Skill 互相调用**，而是它们共享同一个 session 上下文。Claude 在一个 session 里同时持有多个 Skill 的指令，按需切换执行角色。

以 Planning with Files 为核心的协作链举例：

```
你说：帮我做一个用户认证模块

↓ Superpowers 自动触发
  → 引导你澄清需求（OAuth? JWT? 第三方登录?）
  → 生成实现规划

↓ 你说：把规划写到文件里
  Planning with Files 介入
  → 生成 task_plan.md（目标+分解任务）
  → 生成 findings.md（技术决策记录）
  → 生成 progress.md（当前进度）

↓ 开始实现，Ralph Loop 介入
  → 每完成一个任务就更新 progress.md
  → 被拦截不让退出，继续下一个任务

↓ 功能完成后
  Code Simplifier 介入 → 清理代码
  Code Review 介入 → 审查质量

↓ 有前端界面
  UI UX Pro Max 介入 → 设计语言建议
  Webapp Testing 介入 → 自动化测试
```

关键点：**Planning with Files 生成的 markdown 文件是跨 session 的共享状态**。下次 session 开始时，Claude 读取这些文件就能接着做，不依赖上下文记忆。这是它最大的价值——它不只是一个 Skill，而是整个协作链的"状态存储层"。

---

## 实际怎么用

**方式一：让 Superpowers 自动编排**

装好 Superpowers 后，其他 Skill 会被它感知和调度。你只需要描述任务，Superpowers 会在合适时机引入 Planning with Files（写规划文件）、引入 Ralph Loop（执行闭环）等。不需要你手动协调。

**方式二：手动串联（更可控）**

```
第一步：/planning-with-files 帮我规划用户认证模块
        → 生成 task_plan.md

第二步：按 task_plan.md 实现第一个任务
        （Claude 自动参考文件内容）

第三步：/ralph-loop "完成 task_plan.md 里所有未勾选的任务，
         每完成一个更新 progress.md，全部完成后输出 <promise>DONE</promise>"

第四步（完成后）：用 code-simplifier agent 整理今天的改动
```

**方式三：context 压缩时恢复**

这是 Planning with Files 最实用的场景。长 session 被 `/compact` 压缩后，直接说：

```
读取 task_plan.md 和 progress.md，从上次中断的地方继续
```

Claude 重建上下文，继续工作，不丢失之前的决策和进度。

---

## 一个实用建议

不需要一开始就把所有 Skill 都装上然后想"怎么协作"。**先装 Planning with Files + Superpowers**，跑一个真实任务，你会在实际使用中自然发现哪个环节需要补充哪个 Skill。协作链是用出来的，不是设计出来的。