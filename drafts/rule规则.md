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