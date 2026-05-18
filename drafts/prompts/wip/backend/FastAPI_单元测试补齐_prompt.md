# FastAPI 单元测试补齐 Prompt

> **状态**：派生自 [skills/personal-os/references/fastapi-backend.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/fastapi-backend.md:1) 的日常使用 prompt，当前保留使用，不作为唯一真源维护。

> **文档职责**：沉淀“检查现有单元测试情况，并为 FastAPI 项目补最小可用单元测试”的可复用 prompt。
> **适用场景**：FastAPI 项目已有代码实现，但缺少或需要补强 `pytest` 单元测试时。
> **目标读者**：本仓库维护者。
> **维护规范**：如果这类 prompt 的输入边界和输出结构稳定，可迁入 `prompts/`；如果后续被更完整的测试能力吸收，再迁入 `drafts/prompts/archived/`。

## 标准版

```text
请基于当前 FastAPI 项目代码，检查现有单元测试情况，并为这次改动补一组最小可用的单元测试。

要求：
1. 先检查项目里是否已经存在 `tests/`、`pytest` 配置和可复用测试样例
2. 优先为 service / repository / util 这类适合做单元测试的代码补测试
3. 如果涉及外部依赖，请使用 mock 或 stub，避免把单元测试写成集成测试
4. 不要一上来铺满整套测试体系，先补当前改动最关键的测试
5. 最后说明补了哪些测试、覆盖了哪些行为、还没覆盖什么
```

## 强执行版

```text
请把自己当成 FastAPI 后端测试补齐助手，针对当前代码和这次改动，补最小必要的单元测试。

请按以下顺序处理：
1. 检查项目当前是否已有：
   - `tests/` 目录
   - `pytest` 配置
   - fixture
   - mock 样例
2. 判断这次改动里哪些逻辑适合做单元测试，哪些不适合
3. 优先覆盖：
   - 纯业务逻辑
   - service 层行为
   - repository 封装逻辑
   - util / helper
4. 避免：
   - 直接依赖真实数据库、Redis、外部 API
   - 把接口联调测试写成单元测试
5. 如果现有项目完全没有测试基础，请先补最小测试结构，不要过度设计

输出要求：
1. 当前单元测试现状
2. 建议补齐的测试点
3. 推荐测试文件位置
4. 测试实现建议
5. 补完后应如何执行和验证
```

## 当前判断

- 这类 prompt 专门针对“单元测试补齐”，和“改动后验证工作流”是两条不同的线
- 当前保留为 `personal-os` 下 FastAPI 真源之上的快捷入口，不再承担后端规范本体职责
- 后续视真实使用频率决定是否继续保留在 `wip/`
