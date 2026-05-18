# Claude Skills Migration Map

> **文档职责**：记录原 `~/.claude/skills` 与当前仓库内真源 / prompt 使用层之间的迁移关系，帮助后续溯源、归档和删除。
> **适用场景**：需要判断某个旧 skill 是否已经被仓库内新的真源接管，或决定哪些旧目录可以后续删除时。
> **目标读者**：本仓库维护者。
> **维护规范**：只记录迁移事实和当前判断；如后续 prompt 再变化，只更新映射关系，不扩写方法论正文。

## 结论总览

- 已收编到 `skills/personal-os/`：8 个
- 保留为独立例外真源：1 个
- 当前未发现完全没有对应落点的旧 skill

## 逐项映射

| 旧 skill | 当前判断 | 当前落点 | 备注 |
|---|---|---|---|
| `code-explain` | 已收编到 `personal-os` | [skills/personal-os/references/code-explain.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/code-explain.md:1) | 当前真源已收编到 `skills/personal-os/references/`，原分拆 skill 已迁到 [drafts/legacy/skill-splits/](/Users/admin/Downloads/Code/claude_blueprint/drafts/legacy/skill-splits:1) |
| `design-doc` | 已收编到 `personal-os` | [skills/personal-os/references/design-doc.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/design-doc.md:1) | 当前真源已收编到 `skills/personal-os/references/`，原分拆 skill 已迁到 [drafts/legacy/skill-splits/](/Users/admin/Downloads/Code/claude_blueprint/drafts/legacy/skill-splits:1) |
| `fastapi-backend` | 已收编到 `personal-os` | [skills/personal-os/references/fastapi-backend.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/fastapi-backend.md:1) | 当前真源已收编到 `skills/personal-os/references/`，原分拆 skill 已迁到 [drafts/legacy/skill-splits/](/Users/admin/Downloads/Code/claude_blueprint/drafts/legacy/skill-splits:1) |
| `python-script` | 已收编到 `personal-os` | [skills/personal-os/references/python-script.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/python-script.md:1) | 当前真源已收编到 `skills/personal-os/references/`，原分拆 skill 已迁到 [drafts/legacy/skill-splits/](/Users/admin/Downloads/Code/claude_blueprint/drafts/legacy/skill-splits:1) |
| `shell-service` | 已收编到 `personal-os` | [skills/personal-os/references/shell-service.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/shell-service.md:1) | 当前真源已收编到 `skills/personal-os/references/`，原分拆 skill 已迁到 [drafts/legacy/skill-splits/](/Users/admin/Downloads/Code/claude_blueprint/drafts/legacy/skill-splits:1) |
| `python-ops-cli` | 已收编到 `personal-os` | [skills/personal-os/references/python-ops-cli.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/python-ops-cli.md:1) | 当前真源已收编到 `skills/personal-os/references/`，原分拆 skill 已迁到 [drafts/legacy/skill-splits/](/Users/admin/Downloads/Code/claude_blueprint/drafts/legacy/skill-splits:1) |
| `writing` | 已收编到 `personal-os` | [skills/personal-os/references/document-writing.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/document-writing.md:1) | 当前真源已收编到 `skills/personal-os/references/`，原分拆 skill 已迁到 [drafts/legacy/skill-splits/](/Users/admin/Downloads/Code/claude_blueprint/drafts/legacy/skill-splits:1) |
| `os-maintenance` | 仓库内唯一真源 | [skills/personal-os/SKILL.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/SKILL.md:1) | 当前唯一真源在仓库内 `skills/personal-os/`，旧 legacy 目录仅保留历史溯源 |
| `project-methodology` | 仓库内唯一真源 | [skills/project-methodology/SKILL.md](/Users/admin/Downloads/Code/claude_blueprint/skills/project-methodology/SKILL.md:1) | 当前唯一真源在仓库内 `skills/project-methodology/`，后续不要再为它新增 prompt 文档 |

## 建议处理

### Legacy 目录可后续删除

- `code-explain/`
- `design-doc/`
- `fastapi-backend/`
- `python-script/`
- `shell-service/`
- `python-ops-cli/`
- `writing/`

### 仓库内真源应持续维护

- `project-methodology/`
  - 原因：
    - 当前仓库内已存在唯一真源：[skills/project-methodology/](/Users/admin/Downloads/Code/claude_blueprint/skills/project-methodology)
    - 旧 legacy 目录只保留作历史溯源，不再作为维护入口
  - 维护口径：
    - 后续只维护仓库内 `skills/project-methodology/`
    - 不再为它补新的 prompt 文档
- `code-explain/`
  - 原因：
    - 当前真源已收编到 [skills/personal-os/references/code-explain.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/code-explain.md:1)
    - 旧 legacy 目录和原分拆 skill 都只保留作历史溯源
  - 维护口径：
    - 后续只维护仓库内 `skills/personal-os/`
    - `代码讲解文档 Prompt` 仅作为日常使用层入口
- `design-doc/`
  - 原因：
    - 当前真源已收编到 [skills/personal-os/references/design-doc.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/design-doc.md:1)
    - 旧 legacy 目录和原分拆 skill 都只保留作历史溯源
  - 维护口径：
    - 后续只维护仓库内 `skills/personal-os/`
    - 设计相关 prompt 仅作为日常使用层入口
- `fastapi-backend/`
  - 原因：
    - 当前真源已收编到 [skills/personal-os/references/fastapi-backend.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/fastapi-backend.md:1)
    - 旧 legacy 目录和原分拆 skill 都只保留作历史溯源
  - 维护口径：
    - 后续只维护仓库内 `skills/personal-os/`
    - FastAPI 相关 prompt 仅作为日常使用层入口
- `python-script/`
  - 原因：
    - 当前真源已收编到 [skills/personal-os/references/python-script.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/python-script.md:1)
    - 旧 legacy 目录和原分拆 skill 都只保留作历史溯源
  - 维护口径：
    - 后续只维护仓库内 `skills/personal-os/`
    - 批量 API 调用脚本 prompt 仅作为历史派生物保留
- `shell-service/`
  - 原因：
    - 当前真源已收编到 [skills/personal-os/references/shell-service.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/shell-service.md:1)
    - 旧 legacy 目录和原分拆 skill 都只保留作历史溯源
  - 维护口径：
    - 后续只维护仓库内 `skills/personal-os/`
    - 服务生命周期管理 prompt 仅作为历史派生物保留
- `python-ops-cli/`
  - 原因：
    - 当前真源已收编到 [skills/personal-os/references/python-ops-cli.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/python-ops-cli.md:1)
    - 旧 legacy 目录和原分拆 skill 都只保留作历史溯源
  - 维护口径：
    - 后续只维护仓库内 `skills/personal-os/`
    - 运维诊断 CLI prompt 仅作为历史派生物保留
- `document-writing/`
  - 原因：
    - 当前真源已收编到 [skills/personal-os/references/document-writing.md](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os/references/document-writing.md:1)
    - 旧 legacy 目录和原分拆 skill 都只保留作历史溯源
  - 维护口径：
    - 后续只维护仓库内 `skills/personal-os/`
    - 写作相关 prompt 仅作为日常使用层入口
- `personal-os/`
  - 原因：
    - 当前仓库内已存在唯一真源：[skills/personal-os/](/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os)
    - 旧 legacy 目录 `os-maintenance/` 只保留作历史溯源，不再作为维护入口
  - 维护口径：
    - 后续只维护仓库内 `skills/personal-os/`
    - `蓝图维护与规则归档 Prompt` 仅作为日常使用层入口

## 溯源说明

本映射文档基于 2026-05-18 对以下两处内容的逐项核对得出：

- 旧目录：`/Users/admin/.claude/skills`（已迁出）
- 新主线：`/Users/admin/Downloads/Code/claude_blueprint/skills/personal-os` + `skills/project-methodology` + `drafts/prompts`

当前结论的判断标准是：

- 如果真源已经收编到 `skills/personal-os/`，则记为“已收编到 personal-os”
- 如果当前只有 prompt / archived prompt 承接其主要任务意图，则记为“可退役”
- 如果 prompt 仅覆盖主体，但缺少治理细节、路由逻辑或 reference 真源，则记为“部分覆盖”
- legacy 目录统一只用于历史溯源
