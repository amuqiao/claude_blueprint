---
name: init-architecture
description: 初始化项目级最小骨架。补齐项目 CLAUDE、设计索引、架构设计方案和实施清单，让项目进入可规范化开发状态。
---

收到 `/init-architecture`，按以下流程执行：

**边界说明**

- 这是一个“项目骨架入口”，不是完整的项目起盘方法
- 它负责补最小骨架、生成初稿、给出下一步入口
- 如果用户的问题在于“先定技术栈还是先选首个模块、先补前端还是后端基础设施”，先提醒用户回到项目级方法判断，而不是把这些高层判断都硬塞进当前命令

**Step 1 · 检查项目级基础文档是否存在**

依次检查以下路径：
- 项目根 `CLAUDE.md`
- `docs/design/INDEX.md`
- `docs/design/架构设计方案.md`
- `docs/实施清单.md`

输出检查结果：`存在 ✅ / 缺失 ❌`

**Step 2 · 先补齐骨架，再做分析**

先补齐目录骨架（只建目录，不预生成大量空文档）：
- `docs/design/模块/`
- `docs/design/基础设施/后端/`
- `docs/design/基础设施/前端/`
- `docs/需求/`
- `docs/专题/`

如果项目根 `CLAUDE.md` 不存在：
- 读取 `~/.claude/templates/project-CLAUDE.md`
- 基于当前仓库结构、开发命令和日志位置创建项目初稿
- 仅保留项目专属内容；不要重复全局 `~/.claude/CLAUDE.md`

如果 `docs/design/INDEX.md` 不存在：
- 读取 `~/.claude/templates/docs-INDEX.md`
- 创建 `docs/design/INDEX.md`

如果 `docs/design/架构设计方案.md` 不存在：
- 读取 `~/.claude/templates/架构设计方案.md`
- 先创建文档骨架，再进入下一步分析补全内容

如果 `docs/实施清单.md` 不存在：
- 读取 `~/.claude/templates/实施清单.md`
- 创建 `docs/实施清单.md`

**Step 3 · 调用 arch subagent 做首轮架构分析**

调用 `arch`，让其基于：
- 项目根 `CLAUDE.md`
- 当前代码目录结构
- 现有 `docs/design/` 文档（如果已有）

输出：
- 当前系统的分层结构判断
- 核心模块划分
- 关键技术选型
- 需要写入架构设计方案的核心约束

**Step 4 · 用 design-doc skill 补全架构设计方案**

- 读取 `~/.claude/skills/design-doc/SKILL.md`
- 基于 Step 3 的分析结果，补全 `docs/design/架构设计方案.md`
- 至少覆盖：系统目标、技术栈与关键选型、分层结构、核心数据流、模块边界、基础设施约定、文档边界、待定事项

**Step 5 · 更新 INDEX**

在 `docs/design/INDEX.md` 的“架构文档”表格中确认：
- `架构设计方案.md` 已登记
- 同步状态设为 `🆕`
- 最后更新日期写为当天

**Step 6 · 收尾提示**

输出：
- 已初始化的文件列表
- 已创建的目录骨架
- 仍需用户补充确认的信息
- 下一步建议命令：
  - 新建模块 → `/new-module`
  - 代码落库后同步文档 → `/update-docs`
