#!/usr/bin/env bash
# =============================================================================
# setup-codex-multiagent.sh
# 一键为 Codex 配置多 agent 环境，对标 Claude Code VoltAgent 三个插件包
#
# 安装的 agent 严格对应三个官方插件包（以 Claude Code plugin.json 为准）：
#   voltagent-core-dev → 01-core-development   (10 agents，design-bridge 无 Codex 版本)
#   voltagent-lang     → 02-language-specialists (30 agents)
#   voltagent-qa-sec   → 04-quality-security    (17 agents)
#   共 57 个
#
# 做了什么：
#   1. clone VoltAgent/awesome-codex-subagents（已存在则 pull 更新）
#   2. 安装 57 个 .toml agent 到 ~/.codex/agents/（或 .codex/agents/）
#   3. 写入 AGENTS.md（有则备份后覆盖，无则新建，纯 Codex 原生指令）
#
# 用法：
#   bash setup-codex-multiagent.sh              # 全局安装
#   bash setup-codex-multiagent.sh --dry-run    # 只预览，不写入
#   bash setup-codex-multiagent.sh --project    # 项目级安装（.codex/）
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
PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))"
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

# voltagent-core-dev：对应 Claude Code plugin.json 的 11 个 agent
# design-bridge 在 Codex 仓库中不存在，跳过，实际安装 10 个
install_agent "voltagent-core-dev  (10 agents，design-bridge 无 Codex 版本)" \
  01-core-development/api-designer.toml \
  01-core-development/backend-developer.toml \
  01-core-development/electron-pro.toml \
  01-core-development/frontend-developer.toml \
  01-core-development/fullstack-developer.toml \
  01-core-development/graphql-architect.toml \
  01-core-development/microservices-architect.toml \
  01-core-development/mobile-developer.toml \
  01-core-development/ui-designer.toml \
  01-core-development/websocket-engineer.toml

# voltagent-lang：对应 Claude Code plugin.json 的全部 30 个 agent
install_agent "voltagent-lang  (30 agents)" \
  02-language-specialists/angular-architect.toml \
  02-language-specialists/cpp-pro.toml \
  02-language-specialists/csharp-developer.toml \
  02-language-specialists/django-developer.toml \
  02-language-specialists/dotnet-core-expert.toml \
  02-language-specialists/dotnet-framework-4.8-expert.toml \
  02-language-specialists/elixir-expert.toml \
  02-language-specialists/expo-react-native-expert.toml \
  02-language-specialists/fastapi-developer.toml \
  02-language-specialists/flutter-expert.toml \
  02-language-specialists/golang-pro.toml \
  02-language-specialists/java-architect.toml \
  02-language-specialists/javascript-pro.toml \
  02-language-specialists/kotlin-specialist.toml \
  02-language-specialists/laravel-specialist.toml \
  02-language-specialists/nextjs-developer.toml \
  02-language-specialists/node-specialist.toml \
  02-language-specialists/php-pro.toml \
  02-language-specialists/powershell-5.1-expert.toml \
  02-language-specialists/powershell-7-expert.toml \
  02-language-specialists/python-pro.toml \
  02-language-specialists/rails-expert.toml \
  02-language-specialists/react-specialist.toml \
  02-language-specialists/rust-engineer.toml \
  02-language-specialists/spring-boot-engineer.toml \
  02-language-specialists/sql-pro.toml \
  02-language-specialists/swift-expert.toml \
  02-language-specialists/symfony-specialist.toml \
  02-language-specialists/typescript-pro.toml \
  02-language-specialists/vue-expert.toml

# voltagent-qa-sec：对应 Claude Code plugin.json 的全部 17 个 agent
install_agent "voltagent-qa-sec  (17 agents)" \
  04-quality-security/accessibility-tester.toml \
  04-quality-security/ad-security-reviewer.toml \
  04-quality-security/ai-writing-auditor.toml \
  04-quality-security/architect-reviewer.toml \
  04-quality-security/chaos-engineer.toml \
  04-quality-security/code-reviewer.toml \
  04-quality-security/compliance-auditor.toml \
  04-quality-security/debugger.toml \
  04-quality-security/error-detective.toml \
  04-quality-security/gdpr-ccpa-compliance.toml \
  04-quality-security/penetration-tester.toml \
  04-quality-security/performance-engineer.toml \
  04-quality-security/powershell-security-hardening.toml \
  04-quality-security/qa-expert.toml \
  04-quality-security/security-auditor.toml \
  04-quality-security/test-automator.toml \
  04-quality-security/ui-ux-tester.toml

echo ""
if $DRY_RUN; then
  ok "agents 安装预览：${INSTALLED} 个计划，${SKIPPED} 个未找到"
else
  ok "agents 安装完成：${INSTALLED} 个成功，${SKIPPED} 个未找到"
fi

if ! $DRY_RUN && [ -d "$AGENTS_DIR" ]; then
  TOTAL=$(ls "$AGENTS_DIR"/*.toml 2>/dev/null | wc -l | tr -d ' ')
  echo -e "\n${BOLD}已安装 ${TOTAL} 个 agent：${NC}"
  ls "$AGENTS_DIR"/*.toml 2>/dev/null \
    | xargs -I{} basename {} .toml \
    | pr -3 -t -w 72 \
    | while IFS= read -r line; do echo -e "  ${GREEN}·${NC} $line"; done
fi

# ── 3. 写入 AGENTS.md ────────────────────────────────────────────────────────
# 无论用户有没有 AGENTS.md，跑完都会有一份正确的：
#   · 已有文件 → 备份后覆盖
#   · 没有文件 → 直接新建
# 内容：纯 Codex 原生指令，无任何 Claude Code 专用引用
#   · 无 AskUserQuestion / superpowers:* / voltagent-xxx:* 引用
#   · 所有 agent 名与已安装的 .toml name 字段精确匹配
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
## Codex Multi-Agent Workflow

本文件是 Claude Code 多 agent 协作规则的 Codex 适配版。目标是保留
"先选工作流、再按需派发专项 agent、最后 review 与 verify" 的协作结构，
但所有执行方式必须使用 Codex 原生概念：AGENTS.md、custom agents、
subagents，以及内置 `default` / `worker` / `explorer`。

### 任务开始前必须选择工作流

任何代码任务开始前，必须先询问用户选择工作流。即使是单行修改、
typo fix、显而易见的改动，也必须先问。

询问时输出以下内容，然后停止，等待用户回复后再进行任何代码相关操作：

```
选择工作流：

1. plan -> subagent -> review -> verify（完整多 agent 流水线）
2. Just do it（直接执行，最后验证）

请回复 1 或 2。
```

用户回复 `1` 时，视为本任务已明确授权使用 Codex subagents / parallel
agents。用户回复 `2` 时，不主动使用 subagents，除非用户后续明确要求。

### 触发场景

满足任一条，必须先询问工作流：

- 写新代码，包括新函数、新文件、新模块。
- 修改已有代码，包括编辑、重构、修 bug、改风格；单行改动也算。
- 增加或修改测试。
- 修改构建、依赖、类型、容器、迁移等配置。
- 编写实现方案、设计文档、迁移计划或重构计划。

以下场景不需要询问：

- 纯讨论、问答、解释。
- 只读代码、读文档、查找符号。
- 运行不修改源码的命令。
- 编辑 AGENTS.md、config.toml、auto-memory、日报等元配置或元数据文件。
- 当前 session 已选过工作流，且仍是同一个连续任务。

### 工作流 1：plan -> subagent -> review -> verify

四阶段全部必须执行。

#### Plan 阶段

主 agent 先阅读上下文并制定计划。计划必须说明：

- 本任务需要哪些文件或模块。
- 哪些工作适合交给 subagent 并行处理。
- 哪些工作必须由主 agent 在关键路径上完成。
- 预计使用哪些 custom agents；没有合适专项 agent 时使用 `default`、
  `worker` 或 `explorer`。

纯架构权衡或技术选型优先使用 `architect-reviewer` 参与分析。代码路径梳理和影响面分析优先使用 `explorer`。

#### Subagent 执行阶段

用户选择工作流 1 后，可以按任务领域显式 spawn subagents。选择原则：先看
任务技术栈和职责，再选择 description 最匹配的 custom agent；不要强行套用
不相关的专项 agent。

执行类任务优先使用 `worker` 或对应专项 agent；只读探索优先使用 `explorer`。
多个互不依赖的子任务可以并行派发，但必须避免多个 agent 同时编辑同一文件。

| 技术栈 / 场景 | 优先使用的 agent |
|---|---|
| TypeScript | `typescript-pro` |
| JavaScript | `javascript-pro` |
| React | `react-specialist` |
| Vue | `vue-expert` |
| Angular | `angular-architect` |
| Next.js | `nextjs-developer` |
| Node.js 服务 | `node-specialist` |
| Python 通用 | `python-pro` |
| Python / FastAPI | `fastapi-developer` |
| Python / Django | `django-developer` |
| Rust | `rust-engineer` |
| Go | `golang-pro` |
| Java / Spring | `java-architect` / `spring-boot-engineer` |
| Kotlin | `kotlin-specialist` |
| Swift / iOS | `swift-expert` |
| Flutter | `flutter-expert` |
| React Native / Expo | `expo-react-native-expert` |
| PHP 通用 | `php-pro` |
| Laravel | `laravel-specialist` |
| Symfony | `symfony-specialist` |
| Ruby / Rails | `rails-expert` |
| C# / .NET | `csharp-developer` / `dotnet-core-expert` |
| C++ | `cpp-pro` |
| SQL / 数据库 | `sql-pro` |
| Elixir | `elixir-expert` |
| PowerShell | `powershell-7-expert` / `powershell-5.1-expert` |
| 前端 UI/UX 实现 | `frontend-developer` |
| UI 视觉设计决策 | `ui-designer` |
| 后端 API 实现 | `backend-developer` |
| API 合同设计 | `api-designer` |
| 跨前后端完整功能 | `fullstack-developer` |
| Electron | `electron-pro` |
| 移动端跨平台 | `mobile-developer` |
| GraphQL | `graphql-architect` |
| 微服务架构 | `microservices-architect` |
| WebSocket | `websocket-engineer` |
| 无匹配技术栈 | `default` 或 `worker` |

#### Review 阶段

实现完成后，必须按风险维度选择 reviewer。多维风险可以并行运行多个
review subagents。

| 风险维度 | 优先使用的 agent |
|---|---|
| 代码质量 / 可维护性 | `code-reviewer` |
| 正确性 / 行为回归 | `code-reviewer` / `debugger` |
| 安全漏洞 | `security-auditor` / `penetration-tester` |
| 合规风险 | `compliance-auditor` / `gdpr-ccpa-compliance` |
| 性能瓶颈 | `performance-engineer` |
| 架构合理性 | `architect-reviewer` |
| 无障碍合规 | `accessibility-tester` |
| UI/UX 流程 | `ui-ux-tester` |
| 测试策略 / 覆盖缺口 | `qa-expert` / `test-automator` |

Review 发现的问题由主 agent 汇总判断；只修与当前任务相关的问题，不做无关
重构。

#### Verify 阶段

声称完成前必须运行最小必要验证，并说明验证结果。可根据项目选择测试、构建、
lint、类型检查或更窄的目标命令。只看 diff 不算完成。

如果无法验证，必须说明原因和剩余风险。

### 工作流 2：Just do it

在最小范围内由主 agent 直接执行。默认不 spawn subagents。

开始前仍需应用以下约束：

- 任务是 bug、测试失败或非预期行为时，先定位根因，再修复。必要时可在用户
  明确同意后使用 `debugger` 或 `error-detective`。
- 修改测试或添加可测逻辑时，优先先写测试再写实现。必要时可在用户明确同意后
  使用 `test-automator` 或 `qa-expert`。
- 声称完成前必须运行最小必要验证；无法验证时说明原因。
- 只在用户明确要求时 commit。

### Codex 适配边界

- 不使用 Claude 专用工具、插件命名空间或 skill 名称。
- custom agent 名称使用 `.codex/agents/*.toml` 中的 name 字段；文件名只作为
  简单约定，最终以 name 为准。
- Codex 内置 agents 只有 `default`、`worker`、`explorer`。不要引用不存在的
  内置 agent。
- subagents 只在用户选择工作流 1 或后续明确要求时使用。
- 保持改动小范围、可验证、可回滚；不要引入无关重构、依赖升级或目录迁移。

### 严格规则

- 不得以任务小为由跳过询问。
- 不得默认进入任何一个工作流。
- 不得先改代码再问。
- 收到用户回复后才能开始代码相关操作。

<!-- WORKFLOW_END -->

<!-- NO_FALLBACK_START -->
## 不擅自添加兜底策略

编写代码时不要为了“更稳”擅自添加 fallback、silent catch、默认值吞错、
空结果兼容或降级逻辑。除非需求明确要求，遇到异常应让错误快速暴露，
便于定位和修复。
<!-- NO_FALLBACK_END -->

<!-- LANGUAGE_START -->
## 语言偏好

**默认使用中文回复用户**——包括正文、总结、提问、进度更新等所有面向用户的文本，不论任务涉及的代码、子 agent 或工具返回内容是什么语言。

- 派发给 Agent/subagent 的执行结果、审查意见即使原文是英文，转述给用户时必须翻译改写成中文，不要直接搬运英文原文。
- 代码、命令、路径、协议名、库名等技术对象保持英文原文，不强行翻译。
- 仅当用户主动用英文提问，或明确要求用英文回复时，才切换成英文。
<!-- LANGUAGE_END -->
AGENTS_EOF

  ok "AGENTS.md 已写入 → $AGENTS_MD_PATH"

  # 验证：无 Claude Code 专用引用
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
echo -e "${BOLD}文件位置：${NC}"
echo -e "  agents    → ${CYAN}${AGENTS_DIR}/${NC}"
echo -e "  AGENTS.md → ${CYAN}${AGENTS_MD_PATH}${NC}"
echo ""
ok "全部完成，重启 Codex 生效"
