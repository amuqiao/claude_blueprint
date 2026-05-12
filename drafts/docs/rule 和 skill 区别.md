完成！我已经协调好 rules 和 skills，并创建了边界说明文档。

## 完成的工作

### 1. **创建边界文档**
📄 `/Users/admin/Downloads/Code/claude_blueprint/drafts/rule与skill的职责边界.md`

包含：
- ✅ 核心区别对照表（性质、问题、表达、内容、加载时机）
- ✅ 职责定位说明（什么适合放哪里）
- ✅ 边界判断决策流程图
- ✅ 协作关系说明（rule 指向 skill、skill 依赖 rule）
- ✅ 当前状态检查（已有的 rules 和 skills 列表）
- ✅ 扩展指南（何时新增 rule/skill）
- ✅ 反模式警示（3 个常见错误）
- ✅ 维护检查清单

### 2. **修复重复问题**
修改了 `skills/writing/SKILL.md` 的 §3 检查点：

**之前**（重复了 rule 内容）：
```markdown
- 表达是否合格：先结论后展开，简洁、直接、可执行
- 图示是否合适：复杂图用 Mermaid，简单结构用文本树或简洁文字图
```

**现在**（正确引用）：
```markdown
- 表达是否合格：对照 `rules/writing.md` 检查
- 图示是否合适：对照 §4 Mermaid 配色规范检查
```

### 3. **协调检查结果**
✅ **无冲突**：
- rules/writing.md 说原则（要做什么）
- skills/writing/SKILL.md 说方法（怎么做）+ 正确引用 rule
- 边界清晰，职责明确

## 核心原则记忆

```
rule  →  原则  →  一句话能说清  →  全局加载
skill →  方法  →  需要模板流程  →  按需加载
```

现在规范体系更加清晰和一致了！