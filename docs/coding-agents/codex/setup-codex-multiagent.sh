#!/usr/bin/env bash
# =============================================================================
# setup-codex-multiagent.sh
# 一键为 Codex 配置多 agent 环境，对标 Claude Code + VoltAgent + CLAUDE.md
#
# 做了什么：
#   1. clone VoltAgent/awesome-codex-subagents（已存在则 pull 更新）
#   2. 安装 agent .toml 到 ~/.codex/agents/（或 .codex/agents/）
#   3. 写入 AGENTS.md（有则备份后覆盖，无则新建，纯 Codex 原生指令）
#
# 用法：
#   bash setup-codex-multiagent.sh              # 全局安装
#   bash setup-codex-multiagent.sh --dry-run    # 只预览，不写入
#   bash setup-codex-multiagent.sh --project    # 项目级安装（.codex/）
#   bash setup-codex-multiagent.sh --project --dry-run
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC}  $*"; }
info() { echo -e "${BLUE}→${NC}  $*"; }
warn() { echo -e "${YELLOW}!${NC}  $*"; }
err()  { echo -e "${RED}✗${NC}  $*" >&2; }
step() { echo -e "\n${BOLD}${CYAN}[$1]${NC} $2"; }

# ── 参数 ──────────────────────────────────────────────────────────────────────
DRY_RUN=false
PROJECT_SCOPE=false
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --project) PROJECT_SCOPE=true ;;
    --help|-h)
      echo "用法: bash setup-codex-multiagent.sh [--dry-run] [--project]"
      echo "  --dry-run   只预览，不写入任何文件"
      echo "  --project   安装到脚本所在 Git 项目的 .codex/，默认安装到 ~/.codex/（全局）"
      exit 0 ;;
  esac
done

run() { $DRY_RUN && echo -e "  ${YELLOW}[dry-run]${NC} $*" || "$@"; }

# ── 路径 ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../../.." && pwd))"
REPO_URL="https://github.com/VoltAgent/awesome-codex-subagents.git"

if $PROJECT_SCOPE; then
  REPO_CACHE="$PROJECT_ROOT/.codex/_awesome-subagents"
  AGENTS_DIR="$PROJECT_ROOT/.codex/agents"
  AGENTS_MD_PATH="$PROJECT_ROOT/AGENTS.md"
  SCOPE_LABEL="项目级（$PROJECT_ROOT/.codex/agents/ + $PROJECT_ROOT/AGENTS.md）"
else
  REPO_CACHE="$HOME/.codex/_awesome-subagents"
  AGENTS_DIR="$HOME/.codex/agents"
  AGENTS_MD_PATH="$HOME/.codex/AGENTS.md"
  SCOPE_LABEL="全局（~/.codex/agents/ + ~/.codex/AGENTS.md）"
fi

# ── 头部 ──────────────────────────────────────────────────────────────────────
echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Codex 多 agent 一键配置                           ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  安装范围 : ${CYAN}${SCOPE_LABEL}${NC}"
echo -e "  AGENTS.md: ${CYAN}${AGENTS_MD_PATH}${NC}"
$DRY_RUN && warn "DRY-RUN 模式，不会写入任何文件"

# ── 0. 前置检查 ───────────────────────────────────────────────────────────────
step "0/4" "前置检查"
command -v git &>/dev/null && ok "git 已安装" || { err "需要 git，请先安装"; exit 1; }
command -v codex &>/dev/null \
  && ok "codex $(codex --version 2>/dev/null | head -1 || echo '已安装')" \
  || { warn "未检测到 codex 命令"; warn "安装方式: npm install -g @openai/codex"; }

# ── 1. clone / pull ───────────────────────────────────────────────────────────
step "1/4" "获取 VoltAgent/awesome-codex-subagents"
if [ -d "$REPO_CACHE/.git" ]; then
  info "仓库已存在，pull 更新..."
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} git -C $REPO_CACHE pull"
  else
    git -C "$REPO_CACHE" pull --ff-only --quiet && ok "已更新到最新" \
      || warn "pull 失败（可能无网络），使用本地缓存继续"
  fi
else
  info "首次 clone（depth=1）..."
  run git clone --depth=1 "$REPO_URL" "$REPO_CACHE"
  $DRY_RUN && ok "clone 预览完成 → $REPO_CACHE" || ok "clone 完成 → $REPO_CACHE"
fi
SRC="$REPO_CACHE/categories"

# ── 2. 安装 agents ────────────────────────────────────────────────────────────
step "2/4" "安装 agent .toml → ${AGENTS_DIR}/"
run mkdir -p "$AGENTS_DIR"

INSTALLED=0; SKIPPED=0

install_agent() {
  local label="$1"; shift
  echo -e "\n  ${BOLD}# ${label}${NC}"
  for rel in "$@"; do
    local src="$SRC/$rel"
    local dest="$AGENTS_DIR/$(basename "$rel")"
    if [ -f "$src" ]; then
      run cp "$src" "$dest"
      echo -e "    ${GREEN}+${NC} $(basename "$rel" .toml)"
      INSTALLED=$((INSTALLED + 1))
    elif $DRY_RUN && [ ! -d "$SRC" ]; then
      echo -e "    ${YELLOW}[dry-run]${NC} cp $src $dest"
      INSTALLED=$((INSTALLED + 1))
    else
      echo -e "    ${YELLOW}?${NC} 未找到: $rel"
      SKIPPED=$((SKIPPED + 1))
    fi
  done
}

install_agent "功能角色" \
  01-core-development/backend-developer.toml \
  01-core-development/frontend-developer.toml \
  01-core-development/fullstack-developer.toml \
  01-core-development/api-designer.toml \
  01-core-development/ui-designer.toml \
  01-core-development/ui-fixer.toml \
  01-core-development/code-mapper.toml

install_agent "语言专家" \
  02-language-specialists/typescript-pro.toml \
  02-language-specialists/react-specialist.toml \
  02-language-specialists/python-pro.toml \
  02-language-specialists/rust-engineer.toml \
  02-language-specialists/golang-pro.toml \
  02-language-specialists/nextjs-developer.toml \
  02-language-specialists/node-specialist.toml \
  02-language-specialists/fastapi-developer.toml \
  02-language-specialists/java-architect.toml \
  02-language-specialists/sql-pro.toml

install_agent "质量与安全" \
  04-quality-security/reviewer.toml \
  04-quality-security/code-reviewer.toml \
  04-quality-security/security-auditor.toml \
  04-quality-security/architect-reviewer.toml \
  04-quality-security/performance-engineer.toml \
  04-quality-security/debugger.toml \
  04-quality-security/error-detective.toml \
  04-quality-security/qa-expert.toml \
  04-quality-security/test-automator.toml \
  04-quality-security/accessibility-tester.toml

install_agent "编排与规划" \
  09-meta-orchestration/workflow-orchestrator.toml \
  09-meta-orchestration/agent-organizer.toml \
  09-meta-orchestration/multi-agent-coordinator.toml \
  09-meta-orchestration/task-distributor.toml \
  09-meta-orchestration/context-manager.toml \
  10-research-analysis/docs-researcher.toml \
  10-research-analysis/search-specialist.toml

echo ""
if $DRY_RUN; then
  ok "agents 安装预览：${INSTALLED} 个计划，${SKIPPED} 个未找到"
else
  ok "agents 安装完成：${INSTALLED} 个成功，${SKIPPED} 个未找到"
fi

# ── 3. 写入 AGENTS.md ────────────────────────────────────────────────────────
# 无论用户有没有 AGENTS.md，跑完都会有一份正确的：
#   · 已有文件 → 备份后覆盖
#   · 没有文件 → 直接新建
# 内容：纯 Codex 原生指令，无任何 Claude Code 专用引用
#   · 无 AskUserQuestion / superpowers:* / voltagent-xxx:* 引用
#   · 所有 agent 名与已安装的 .toml name 字段精确匹配
#   · worker / explorer / default 是 Codex 内置 subagent，无需 .toml
step "3/4" "写入 ${AGENTS_MD_PATH}"

if $DRY_RUN; then
  if [ -f "$AGENTS_MD_PATH" ]; then
    echo -e "  ${YELLOW}[dry-run]${NC} 检测到已有 AGENTS.md → 将备份后覆盖"
    echo -e "  ${YELLOW}[dry-run]${NC} 备份 → ${AGENTS_MD_PATH}.backup.<时间戳>"
  else
    echo -e "  ${YELLOW}[dry-run]${NC} 未检测到 AGENTS.md → 将新建"
  fi
  echo -e "  ${YELLOW}[dry-run]${NC} 写入 $AGENTS_MD_PATH"
else
  mkdir -p "$(dirname "$AGENTS_MD_PATH")"
  if [ -f "$AGENTS_MD_PATH" ]; then
    BAK="${AGENTS_MD_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$AGENTS_MD_PATH" "$BAK"
    warn "已有 AGENTS.md，备份 → $BAK"
    info "覆盖写入新版本..."
  else
    info "新建 AGENTS.md..."
  fi

  cat > "$AGENTS_MD_PATH" << 'AGENTS_EOF'
<!-- WORKFLOW_START -->
## Workflow Preference

**任何代码任务开始前，必须先询问用户选择工作流。NO EXCEPTIONS。**
**即使是单行修改、typo fix、"显而易见"的改动也必须问。**

询问时输出以下内容，然后停止，等待用户回复后再进行任何操作：

```
选择工作流：

1. plan → subagent → review → verify（完整流水线）
2. Just do it（直接执行，最后验证）

请回复 1 或 2。
```

---

### 触发场景（满足任一条 → 必须先问）

- 写新代码（新函数 / 文件 / 模块）
- 修改已有代码（编辑、重构、修 bug、改风格——**单行改动也算**）
- 增加 / 修改测试
- 修改构建配置（package.json / requirements.txt / vite.config /
  tsconfig / Dockerfile / Makefile / Alembic migration 等）
- 写实现方案 / 设计文档

### 不需要问（非代码任务）

- 纯讨论 / 问答 / 解释
- 读代码 / 读文档 / 查符号
- 运行命令（git / pytest / npm run / deploy 等，不修改源码）
- 编辑 `AGENTS.md` / `config.toml` / auto-memory / 日报等元配置文件
- 当前 session 已选过工作流且任务连续（新话题需重新问）

---

### 工作流 1：plan → subagent → review → verify

四阶段全部必须执行。选 agent 的原则：先看任务领域和技术栈，找
description 最匹配的 agent；没有精确匹配时用 Codex 内置 `default`
subagent，不要强行套不合适的专项 agent。

#### Plan 阶段

优先用 `workflow-orchestrator` 规划完整执行方案。
需求模糊或方向不清晰时，先用 `agent-organizer` 做任务分解。
纯架构评审或技术选型时，用 `architect-reviewer`。

#### Subagent 执行阶段

按任务的技术栈和功能域派发。多个相互独立的子任务可以在同一条
prompt 里指定并行执行，例如：
"Have typescript-pro fix the type errors. Have qa-expert write
the test plan. Run both in parallel."

| 技术栈 / 场景 | 使用的 agent |
|---|---|
| TypeScript / Node.js | `typescript-pro` |
| React | `react-specialist` |
| Python（通用） | `python-pro` |
| Python / FastAPI | `fastapi-developer` |
| Rust | `rust-engineer` |
| Go | `golang-pro` |
| Next.js | `nextjs-developer` |
| Node.js 服务 | `node-specialist` |
| Java / Spring | `java-architect` |
| SQL / 数据库 | `sql-pro` |
| 前端 UI/UX 实现 | `frontend-developer` |
| UI 视觉设计决策 | `ui-designer` |
| 已复现 UI 小缺陷 | `ui-fixer` |
| 后端 API 实现 | `backend-developer` |
| API 合同设计 | `api-designer` |
| 跨前后端完整功能 | `fullstack-developer` |
| 代码路径梳理 | `code-mapper` |
| 无匹配技术栈 | Codex 内置 `default` subagent |

#### Review 阶段

按风险维度选择 reviewer，多维度风险可并行运行多个：

| 风险维度 | 使用的 agent |
|---|---|
| 代码正确性 / 行为回归 | `reviewer` |
| 代码质量 / 可维护性 | `code-reviewer` |
| 安全漏洞 | `security-auditor` |
| 性能瓶颈 | `performance-engineer` |
| 架构合理性 | `architect-reviewer` |
| 无障碍合规 | `accessibility-tester` |

#### Verify 阶段

声称完成前必须运行以下至少一条，并将通过的输出贴出作为证据。
只看 diff 不算完成。

- `npm test` / `pytest` / `cargo test` / `go test ./...`
- `npm run build` / `tsc --noEmit`
- `npm run lint` / `ruff check` / `cargo clippy`

---

### 工作流 2：Just do it

最小范围直接执行。开始前按顺序应用以下约束：

**调试约束**：任务是 bug / 测试失败 / 非预期行为时，先用
`debugger` 或 `error-detective` 定位根因，再动手修复。

**TDD 约束**：修改测试或添加可测逻辑时，先写测试再写实现。
可用 `test-automator` 生成测试骨架，`qa-expert` 制定测试策略。

**验证约束**：声称完成前必须运行测试 / 构建 / lint 取得通过证据，
只看 diff 不算完成。

只在用户明确要求时才 commit。

---

### 严格规则（违反 = 错误）

- **不得**以任务小为由跳过询问，"看起来很小"不是理由
- **不得**默认进入任何一个工作流
- **不得**先改代码再问，询问必须在前
- 收到用户回复后才能开始任何代码相关操作

<!-- WORKFLOW_END -->

<!-- NO_FALLBACK_START -->
## 不擅自添加兜底策略

编写代码时不要为了"更稳"擅自添加 fallback、silent catch、
默认值吞错、空结果兼容或降级逻辑。除非需求明确要求，
遇到异常应让错误快速暴露，便于定位和修复。
<!-- NO_FALLBACK_END -->
AGENTS_EOF

  ok "AGENTS.md 已写入 → $AGENTS_MD_PATH"

  # 验证：无 Claude Code 专用引用残留
  BAD="AskUserQuestion|superpowers:|voltagent-qa-sec:|voltagent-lang:|voltagent-core-dev:|andrej-karpathy:|CLAUDE\.md|settings\.json"
  if grep -qE "$BAD" "$AGENTS_MD_PATH" 2>/dev/null; then
    err "AGENTS.md 含有 Claude Code 专用引用，请检查："
    grep -nE "$BAD" "$AGENTS_MD_PATH"
    exit 1
  fi
  ok "验证通过：无 Claude Code 专用引用"

  # 验证：agent 名与已安装 .toml 匹配
  ALL_OK=true
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    if ls "$AGENTS_DIR/${name}.toml" &>/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} $name"
    else
      echo -e "  ${RED}✗${NC} $name — .toml 未安装"
      ALL_OK=false
    fi
  done <<< "$(grep -oP '`[a-z][a-z0-9-]+`' "$AGENTS_MD_PATH" \
    | tr -d '`' \
    | grep -vE '^(npm|pytest|cargo|go|tsc|ruff|node|git|default|worker|explorer|clippy)$' \
    | sort -u)"
  $ALL_OK && ok "所有 agent 名称均有对应 .toml" \
    || warn "部分 agent 未安装，请检查上方输出"
fi

# ── 4. 完成 ───────────────────────────────────────────────────────────────────
step "4/4" "完成"

echo ""
if ! $DRY_RUN && [ -d "$AGENTS_DIR" ]; then
  TOTAL=$(ls "$AGENTS_DIR"/*.toml 2>/dev/null | wc -l | tr -d ' ')
  echo -e "${BOLD}已安装 agents：${TOTAL} 个${NC}"
  ls "$AGENTS_DIR"/*.toml 2>/dev/null \
    | xargs -I{} basename {} .toml \
    | pr -3 -t -w 72 \
    | while IFS= read -r line; do echo -e "  ${GREEN}·${NC} $line"; done
fi

echo ""
echo -e "${BOLD}文件位置：${NC}"
echo -e "  agents    → ${CYAN}${AGENTS_DIR}/${NC}"
echo -e "  AGENTS.md → ${CYAN}${AGENTS_MD_PATH}${NC}"
echo ""
ok "全部完成，重启 Codex 生效"
