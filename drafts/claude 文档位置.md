有偏差，我纠正一下。

按 Anthropic 官方文档，标准内存位置是：

- 项目共享内存：`./CLAUDE.md`
- 用户全局内存：`~/.claude/CLAUDE.md`
- 项目个人内存：`./CLAUDE.local.md`，但官方已标为 deprecated，并建议改用 `CLAUDE.md` 的 `@import` 方式替代。([docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code/memory?utm_source=openai))

所以：

- `/Users/admin/Downloads/Code/title/CLAUDE.md`：对，是**项目共享**的正式项目内存。([docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code/memory?utm_source=openai))
- `/Users/admin/Downloads/Code/title/.claude/CLAUDE.md`：**不是官方定义的“项目私有 CLAUDE”位置**。官方文档里项目私有对应的是 `./CLAUDE.local.md`，不是 `.claude/CLAUDE.md`。([docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code/memory?utm_source=openai))

更关键的是，官方还说明了两件事：

1. Claude 会从当前工作目录向上递归读取 `CLAUDE.md` / `CLAUDE.local.md`。([docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code/memory?utm_source=openai))  
2. 当前工作目录下**子树里的** `CLAUDE.md`，不是启动时全局加载，而是**只有当 Claude 读取该子树文件时才会纳入上下文**。([docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code/memory?utm_source=openai))

这意味着：

- `title/CLAUDE.md` 是正常的项目级主记忆。
- `title/.claude/CLAUDE.md` 更像一个**子目录记忆文件**，只在 Claude 读 `.claude/` 子树文件时才可能起作用；它**不等价于官方的项目私有 memory**。([docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code/memory?utm_source=openai))

所以你前面的直觉是对的：  
我之前把 `.claude/CLAUDE.md` 说成“项目级别私有 CLAUDE.md”，这个说法不准确。

## 对 blueprint 的建议

基于官方机制，我建议你定成这套规则：

- 项目共享主记忆：只用项目根的 `CLAUDE.md`
- 项目个人私有偏好：不要用 `.claude/CLAUDE.md`
- 如果确实需要项目私有内容：
  - 短期可用 `./CLAUDE.local.md`
  - 更推荐官方现在建议的方式：在项目 `CLAUDE.md` 里 `@import` 个人文件，比如 `@~/.claude/my-project-instructions.md`。([docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code/memory?utm_source=openai))

## 对你当前 `title` 项目的具体建议

更稳的收口方式是：

1. 保留 [`/Users/admin/Downloads/Code/title/CLAUDE.md`](</Users/admin/Downloads/Code/title/CLAUDE.md>) 作为唯一项目主记忆。
2. 不再把 [`.claude/CLAUDE.md`](</Users/admin/Downloads/Code/title/.claude/CLAUDE.md>) 当成“正式项目私有 CLAUDE”。
3. 如果里面有有价值内容：
   - 项目共享的，迁回根 `CLAUDE.md`
   - 个人私有的，迁到 `CLAUDE.local.md` 或用户目录下单独文件，再通过 `@import` 引入。([docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code/memory?utm_source=openai))

## 回到你最初那个架构问题

这也给了一个更清晰的结论：

- `arch` 这种系统级 agent 依赖的项目级入口，应当是**项目根 `CLAUDE.md` + `docs/design/...`**
- 不应该把 `.claude/CLAUDE.md` 当成项目初始化前提
- 缺失项目级文档时，还是应该靠一个显式的初始化命令去补，而不是靠 agent 自动猜测

如果你要，我下一步可以直接帮你做两件事之一：

1. 先只改 `claude_blueprint` 的文档，把“项目级 `CLAUDE.md` 的官方定位”写准  
2. 顺手审一下 `title/.claude/CLAUDE.md`，帮你判断里面哪些内容该迁回根 `CLAUDE.md`，哪些该转成私有导入文件


需要明确规定，但**不建议用 `.claude/rules/` 去做**。

原因是这条规则本质上不是“处理某类代码时的行为约束”，而是**Claude Code 目录与记忆位置的结构约定**。  
更适合放在这 3 个地方：

1. **`README.md`**
   说明 blueprint 对官方目录约定的采用方式。

2. **`MAINTAINING.md`**
   明确维护者以后不要再把 `.claude/CLAUDE.md` 当成“项目私有记忆”。

3. **`templates/project-CLAUDE.md`**
   直接把正确约定固化进项目模板，避免新项目继续长歪。

---

## 为什么不建议加成 rule

`rules/` 更适合这种内容：

- 某目录下的代码风格
- 某模块的分层限制
- 某类文件的实现约束

而你现在这条是：

- 项目共享记忆放哪里
- 项目私有记忆放哪里
- 什么位置不应该再使用

这属于**仓库结构约定 / 维护约定**，不是运行时推理规则。

如果硬塞进 rule，会有两个问题：

- 语义不对
- 以后用户会混淆“目录规范”和“代码规范”

---

## 最适合你当前 blueprint 的写法

我建议明确采用这套规则：

- **项目共享记忆**：`./CLAUDE.md`
- **用户全局记忆**：`~/.claude/CLAUDE.md`
- **项目个人记忆**：
  - 兼容官方旧机制可写 `./CLAUDE.local.md`
  - 但 blueprint 推荐方式是：在项目 `CLAUDE.md` 中用 `@import` 引个人文件

并明确写一句：

> `.claude/CLAUDE.md` 不作为本 blueprint 的标准项目记忆位置使用。

---

## 你应该把它写到哪里

### 1. `README.md`
给使用者一个清晰约定：

```text
本 blueprint 采用以下记忆位置约定：
- 项目共享：项目根 CLAUDE.md
- 用户全局：~/.claude/CLAUDE.md
- 项目个人：优先使用项目 CLAUDE.md 的 @import；不把 .claude/CLAUDE.md 作为标准项目记忆位置
```

### 2. `MAINTAINING.md`
给维护者一个明确边界：

```text
不要把 .claude/CLAUDE.md 当成项目私有 memory。
如果项目里出现该文件，应判断其内容是：
- 项目共享内容：迁回根 CLAUDE.md
- 个人私有内容：迁到 CLAUDE.local.md 或用户目录文件，再通过 @import 引入
```

### 3. `templates/project-CLAUDE.md`
直接把推荐写法放进去，例如加一个节：

```markdown
## 个人补充方式

如需项目个人私有说明，优先在本文件中通过 `@~/.claude/...` 引入个人文件。
不使用 `.claude/CLAUDE.md` 作为标准项目记忆位置。
```

---

## 结论

**要明确规定，但不要加成 rule。**

更好的落点是：

- `README.md`：对外说明
- `MAINTAINING.md`：维护约定
- `templates/project-CLAUDE.md`：模板固化

一句话总结：

**这是目录与记忆位置规范，不是 rules 规则。**

如果你要，我下一步可以直接把这三处一起补上。