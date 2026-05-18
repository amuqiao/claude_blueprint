# Prompt Cleanup Map

> **文档职责**：给 `drafts/prompts/` 做一次按“真源关系”整理的清理清单，区分哪些 prompt 应保留为日常使用层，哪些应合并，哪些应归档。
> **适用场景**：准备建立“专属 skill 维护唯一真源，prompt 负责日常使用”的治理方式时。
> **目标读者**：本仓库维护者。
> **维护规范**：本文件只记录清理决策和当前口径；不要把各 prompt 的正文规则重新写进这里。

## 当前治理口径

当前默认采用三层分工：

- `skills/`：维护唯一真源
- `drafts/prompts/`：保留日常高频使用的任务启动器
- `drafts/prompts/archived/`：保留已被真源 skill 吸收、或不再主维护的历史派生物

当前已确认的真源：

- [skills/project-methodology/](/Users/admin/Downloads/Code/claude_blueprint/skills/project-methodology)
- [skills/personal-os/](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os)

说明：

- 文档表达、设计文档、FastAPI 后端、脚本模式、代码讲解等子主题真源，统一维护在 `skills/personal-os/references/`

## 处理原则

### 保留

满足以下任一条件，继续放在 `wip/` 作为日常 prompt 使用层：

- 你日常会直接复制使用
- 它本质上是“任务启动器”而不是规范真源
- 即使背后有真源 skill，单独保留仍然明显顺手
- 它表达的是某个具体工作流，而不是稳定方法论本体

### 合并

满足以下任一条件，建议收成一份主 prompt：

- 同一主题只有表达风格不同
- 只是针对不同文档类型做轻微变体
- 维护多份正文只会带来重复修改

### 归档

满足以下任一条件，建议迁到 `drafts/prompts/archived/`：

- 已经被真源 skill 接管
- 只是从旧 skill 拆出来的派生版
- 当前不再作为主维护入口
- 保留只为历史参考，不再日常直接使用

## 清理清单

### 建议保留：日常使用层

#### architecture

- [需求分析与技术栈选型_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/architecture/需求分析与技术栈选型_prompt.md:1)
  - 原因：更像“项目起盘前分析入口”，不是 `project-methodology` 真源本体
- [从粗架构到实现_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/architecture/从粗架构到实现_prompt.md:1)
  - 原因：是典型阶段性工作流 prompt，保留有使用价值
- [实现后补强架构文档_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/architecture/实现后补强架构文档_prompt.md:1)
  - 原因：偏“基于现有代码反推文档”的任务入口
- [架构设计方案质检_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/architecture/架构设计方案质检_prompt.md:1)
  - 原因：偏审查动作，保留为 [skills/personal-os/references/design-doc.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/design-doc.md:1) 的日常使用层入口更顺手

#### backend

- [FastAPI_Request_Body_示例_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/backend/FastAPI_Request_Body_示例_prompt.md:1)
  - 原因：粒度很小，保留为 [skills/personal-os/references/fastapi-backend.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/fastapi-backend.md:1) 的日常使用层入口更方便
- [FastAPI_单元测试补齐_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/backend/FastAPI_单元测试补齐_prompt.md:1)
  - 原因：偏具体实现检查，不是后端规范真源；保留为 [skills/personal-os/references/fastapi-backend.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/fastapi-backend.md:1) 的日常入口
- [FastAPI_接口验证与报告_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/backend/FastAPI_接口验证与报告_prompt.md:1)
  - 原因：偏验证工作流，保留为 [skills/personal-os/references/fastapi-backend.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/fastapi-backend.md:1) 的日常入口价值高

#### operations

- [Docker_开发环境端口检查_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/operations/Docker_开发环境端口检查_prompt.md:1)
  - 原因：是具体执行入口
- [服务安全检查_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/operations/服务安全检查_prompt.md:1)
  - 原因：偏专项审查入口
- [部署与服务管理_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/operations/部署与服务管理_prompt.md:1)
  - 原因：与 `project-methodology` 有关联，但本身是独立工作流
- [项目配置治理检查_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/operations/项目配置治理检查_prompt.md:1)
  - 原因：偏项目清理和收口动作，保留为专项 prompt 合理

#### writing

- [Claude_Code_CLI_与_Codex_CLI_文档_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/writing/Claude_Code_CLI_与_Codex_CLI_文档_prompt.md:1)
  - 原因：专题性很强，不适合被通用文档 skill 吃掉
- [FastAPI_对外接口文档_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/writing/FastAPI_对外接口文档_prompt.md:1)
  - 原因：偏交付物任务，不是写作真源
- [后台接口请求示例_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/writing/后台接口请求示例_prompt.md:1)
  - 原因：前端联调入口，保留价值高
- [项目讲解文档_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/writing/项目讲解文档_prompt.md:1)
  - 原因：更像项目导览任务入口，不是通用写作规则

### 已合并：同主题收口

#### writing / 可视化增强类

- 当前主文件：[文档可视化增强_prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/writing/文档可视化增强_prompt.md:1)
- 原 3 份文件已从 `wip/` 主维护位移出：
  - `Markdown_文档可视化增强_prompt.md`
  - `方法论文档可视化增强_prompt.md`
  - `架构文档可视化增强_prompt.md`

合并结果：

- 新主文件统一覆盖：
  - 通用 Markdown
  - 方法论文档
  - 架构文档
- 文档表达真源继续以 [skills/personal-os/references/document-writing.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/document-writing.md:1) 为准

### 已归档：由真源 skill 接管或明显是派生物

#### architecture

- [架构文档 Prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/archived/架构文档%20Prompt.md:1)
  - 已归档原因：已明显是 [skills/personal-os/references/design-doc.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/design-doc.md:1) 的派生物
- [模块设计文档 Prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/archived/模块设计文档%20Prompt.md:1)
  - 已归档原因：同上

#### backend

- [FastAPI 后端 Prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/archived/FastAPI%20后端%20Prompt.md:1)
  - 已归档原因：更像 [skills/personal-os/references/fastapi-backend.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/fastapi-backend.md:1) 的派生物，而不是日常专项入口
- [批量 API 调用脚本 Prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/archived/批量%20API%20调用脚本%20Prompt.md:1)
  - 已归档原因：已被 [skills/personal-os/references/python-script.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/python-script.md:1) 接管真源职责

#### operations

- [服务生命周期管理脚本 Prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/archived/服务生命周期管理脚本%20Prompt.md:1)
  - 已归档原因：已被 [skills/personal-os/references/shell-service.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/shell-service.md:1) 接管真源职责
- [运维诊断 CLI Prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/archived/运维诊断%20CLI%20Prompt.md:1)
  - 已归档原因：已被 [skills/personal-os/references/python-ops-cli.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/python-ops-cli.md:1) 接管真源职责
- [蓝图维护与规则归档 Prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/operations/蓝图维护与规则归档%20Prompt.md:1)
  - 当前状态：独立的 drafts 日常治理 prompt，不属于 `personal-os` 真源本体
  - 当前结构：作为 `drafts/` 层日常入口保留
  - 后续建议：观察一段时间，如使用频率下降，再迁入 `archived/`

#### writing

- [新建正式文档 Prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/archived/新建正式文档%20Prompt.md:1)
  - 已归档原因：已被 [skills/personal-os/references/document-writing.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/document-writing.md:1) 接管真源职责
- [代码讲解文档 Prompt.md](/Users/admin/Downloads/Code/claude_blueprint/drafts/prompts/wip/writing/代码讲解文档%20Prompt.md:1)
  - 当前状态：已降为 [skills/personal-os/references/code-explain.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/code-explain.md:1) 的派生使用层 prompt
  - 后续建议：观察一段时间，如使用频率下降，再迁入 `archived/`

## 建议执行顺序

### 第一阶段：只做低风险收口

1. 新增或保留本清单
2. 合并 3 份“可视化增强” prompt
3. 给建议归档但还不想立刻动的文件，先在文件头补“状态：派生自真源 skill，不再主维护”

当前执行状态：

- 第 1 步：已完成
- 第 2 步：已完成
- 第 3 步：已完成
- 专属总入口 skill：已创建 `skills/personal-os/`

### 第二阶段：确认专属 skill 稳定后再归档

已完成：

1. `架构文档 Prompt`
2. `模块设计文档 Prompt`
3. `FastAPI 后端 Prompt`
4. `批量 API 调用脚本 Prompt`
5. `服务生命周期管理脚本 Prompt`
6. `运维诊断 CLI Prompt`
7. `新建正式文档 Prompt`

### 第三阶段：观察后决定

以下文件不建议现在就删，先看你未来 2 到 4 周的真实使用频率：

- `蓝图维护与规则归档 Prompt`
- `代码讲解文档 Prompt`
- `FastAPI_Request_Body_示例_prompt`
- `架构设计方案质检_prompt`
- `FastAPI_单元测试补齐_prompt`
- `FastAPI_接口验证与报告_prompt`

## 当前判断

- 这次清理的目标不是减少文件数量，而是把 prompt 从“真源层”降回“使用层”
- 你后续如果走“专属 skill 维护唯一真源”的路线，这份清单就是 prompt 层的收口依据
- 在没有确认专属 skill 结构稳定前，不建议直接大批量删除 prompt
