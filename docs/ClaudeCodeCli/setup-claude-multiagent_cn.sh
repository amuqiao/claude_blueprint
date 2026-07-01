#!/usr/bin/env bash
# =============================================================================
# setup-claude-multiagent.sh
# 一键为 Claude Code 配置多 agent 环境
#
# 安装的 agent 严格对应三个官方插件包：
#   voltagent-core-dev → categories/01-core-development  (11 agents)
#   voltagent-lang     → categories/02-language-specialists (30 agents)
#   voltagent-qa-sec   → categories/04-quality-security  (17 agents)
#
# 做了什么：
#   1. 安装上述三个插件包的 agent（plugin 方式 或 手动 cp 方式）
#   2. 写入 ~/.claude/CLAUDE.md（有则备份后覆盖，无则新建，根据安装方式生成对应版本）
#
# 用法：
#   bash setup-claude-multiagent.sh              # 交互式选择
#   bash setup-claude-multiagent.sh --plugin     # plugin 方式（推荐）
#   bash setup-claude-multiagent.sh --manual     # 手动 cp 方式
#   bash setup-claude-multiagent.sh --project    # 手动方式装到当前项目
#   bash setup-claude-multiagent.sh --dry-run    # 只预览，不写入
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
MODE=""
DRY_RUN=false
PROJECT_SCOPE=false

for arg in "$@"; do
  case $arg in
    --plugin)  MODE="plugin" ;;
    --manual)  MODE="manual" ;;
    --project) PROJECT_SCOPE=true ;;
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      echo "用法: bash setup-claude-multiagent.sh [方式] [选项]"
      echo "  --plugin    用 claude plugin 命令安装（推荐）"
      echo "  --manual    clone 仓库后 cp .md 文件"
      echo "  --project   手动方式专用：装到 .claude/agents/（当前项目）"
      echo "  --dry-run   只预览，不写入任何文件"
      exit 0 ;;
  esac
done

run() { $DRY_RUN && echo -e "  ${YELLOW}[dry-run]${NC} $*" || "$@"; }

# ── 头部 ──────────────────────────────────────────────────────────────────────
echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Claude Code 多 agent 一键配置                     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
$DRY_RUN && warn "DRY-RUN 模式，不会写入任何文件"

# ── 0. 前置检查 ───────────────────────────────────────────────────────────────
step "0/3" "前置检查"

command -v git &>/dev/null && ok "git 已安装" || { err "需要 git，请先安装"; exit 1; }

CLAUDE_BIN="claude"
CLAUDE_AVAILABLE=false
if command -v "$CLAUDE_BIN" &>/dev/null; then
  CLAUDE_AVAILABLE=true
  ok "claude $(claude --version 2>/dev/null | head -1 || echo '已安装')"
else
  warn "未检测到 claude 命令（安装：npm install -g @anthropic-ai/claude-code）"
  if [ "$MODE" = "plugin" ] && ! $DRY_RUN; then
    err "--plugin 方式需要 claude 命令"; exit 1
  fi
fi

# ── 1. 选择安装方式 ───────────────────────────────────────────────────────────
step "1/3" "选择安装方式"

if [ -z "$MODE" ]; then
  echo ""
  echo -e "  ${YELLOW}1)${NC} ${BOLD}Plugin 方式${NC}（推荐）"
  echo -e "     通过 claude plugin 命令安装，支持版本管理和随时开关"
  echo ""
  echo -e "  ${YELLOW}2)${NC} ${BOLD}手动 cp 方式${NC}"
  echo -e "     clone 仓库后复制 .md 文件，离线可用"
  echo ""
  ! $CLAUDE_AVAILABLE && echo -e "  ${YELLOW}（未检测到 claude 命令，Plugin 方式不可用）${NC}\n"
  read -rp "  请输入 1 或 2：" choice
  case $choice in
    1)
      if ! $CLAUDE_AVAILABLE && ! $DRY_RUN; then
        err "未检测到 claude 命令，不能使用 Plugin 方式"
        exit 1
      fi
      MODE="plugin" ;;
    2) MODE="manual" ;;
    *) err "无效输入"; exit 1 ;;
  esac
fi

echo -e "  安装方式: ${CYAN}${MODE}${NC}"
if [ "$MODE" = "manual" ]; then
  $PROJECT_SCOPE \
    && echo -e "  安装范围: ${CYAN}项目级（.claude/agents/）${NC}" \
    || echo -e "  安装范围: ${CYAN}全局（~/.claude/agents/）${NC}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 方式 A：Plugin
# 直接安装三个官方插件包，claude plugin 命令自动处理 agent 列表
# ─────────────────────────────────────────────────────────────────────────────
if [ "$MODE" = "plugin" ]; then

  step "2/3" "Plugin 安装"

  echo ""
  info "注册 VoltAgent 插件市场..."
  run $CLAUDE_BIN plugin marketplace add VoltAgent/awesome-claude-code-subagents
  ok "marketplace 注册完成"

  echo ""
  info "安装三个插件包..."
  echo ""

  # voltagent-core-dev：11 agents
  # api-designer / backend-developer / design-bridge / electron-pro /
  # frontend-developer / fullstack-developer / graphql-architect /
  # microservices-architect / mobile-developer / ui-designer / websocket-engineer
  echo -e "  ${BOLD}# voltagent-core-dev${NC}  (11 agents)"
  echo -e "    api-designer · backend-developer · frontend-developer · fullstack-developer"
  echo -e "    ui-designer · mobile-developer · graphql-architect · microservices-architect ..."
  run $CLAUDE_BIN plugin install voltagent-core-dev@voltagent-subagents
  $DRY_RUN || ok "voltagent-core-dev 安装完成"

  echo ""
  # voltagent-lang：30 agents
  # angular-architect / cpp-pro / csharp-developer / django-developer /
  # dotnet-core-expert / dotnet-framework-4.8-expert / elixir-expert /
  # expo-react-native-expert / fastapi-developer / flutter-expert / golang-pro /
  # java-architect / javascript-pro / kotlin-specialist / laravel-specialist /
  # nextjs-developer / node-specialist / php-pro / powershell-5.1-expert /
  # powershell-7-expert / python-pro / rails-expert / react-specialist /
  # rust-engineer / spring-boot-engineer / sql-pro / swift-expert /
  # symfony-specialist / typescript-pro / vue-expert
  echo -e "  ${BOLD}# voltagent-lang${NC}  (30 agents)"
  echo -e "    typescript-pro · react-specialist · python-pro · golang-pro · rust-engineer"
  echo -e "    java-architect · nextjs-developer · vue-expert · angular-architect ..."
  run $CLAUDE_BIN plugin install voltagent-lang@voltagent-subagents
  $DRY_RUN || ok "voltagent-lang 安装完成"

  echo ""
  # voltagent-qa-sec：17 agents
  # accessibility-tester / ad-security-reviewer / ai-writing-auditor /
  # architect-reviewer / chaos-engineer / code-reviewer / compliance-auditor /
  # debugger / error-detective / gdpr-ccpa-compliance / penetration-tester /
  # performance-engineer / powershell-security-hardening / qa-expert /
  # security-auditor / test-automator / ui-ux-tester
  echo -e "  ${BOLD}# voltagent-qa-sec${NC}  (17 agents)"
  echo -e "    code-reviewer · security-auditor · architect-reviewer · performance-engineer"
  echo -e "    penetration-tester · debugger · qa-expert · test-automator ..."
  run $CLAUDE_BIN plugin install voltagent-qa-sec@voltagent-subagents
  $DRY_RUN || ok "voltagent-qa-sec 安装完成"

  echo ""
  warn "重启 Claude Code 会话后生效，或在 Claude Code 里运行 /reload-plugins"

# ─────────────────────────────────────────────────────────────────────────────
# 方式 B：手动 cp
# 严格按照三个 plugin.json 的 agents 列表复制，一一对应
# ─────────────────────────────────────────────────────────────────────────────
elif [ "$MODE" = "manual" ]; then

  REPO_CACHE="$HOME/.claude/_awesome-subagents"
  REPO_URL="https://github.com/VoltAgent/awesome-claude-code-subagents.git"
  $PROJECT_SCOPE && AGENTS_DIR=".claude/agents" || AGENTS_DIR="$HOME/.claude/agents"

  step "2/3" "手动安装 → ${AGENTS_DIR}/"

  if [ -d "$REPO_CACHE/.git" ]; then
    info "仓库已存在，pull 更新..."
    $DRY_RUN \
      && echo -e "  ${YELLOW}[dry-run]${NC} git -C $REPO_CACHE pull" \
      || { git -C "$REPO_CACHE" pull --ff-only --quiet && ok "已更新" || warn "pull 失败，使用本地缓存"; }
  else
    info "首次 clone（depth=1）..."
    run git clone --depth=1 "$REPO_URL" "$REPO_CACHE"
    ok "clone 完成 → $REPO_CACHE"
  fi

  run mkdir -p "$AGENTS_DIR"
  SRC="$REPO_CACHE/categories"
  INSTALLED=0; SKIPPED=0

  cp_agent() {
    local label="$1"; shift
    echo -e "\n  ${BOLD}# ${label}${NC}"
    for rel in "$@"; do
      local src="$SRC/$rel" dest="$AGENTS_DIR/$(basename "$rel")"
      if [ -f "$src" ]; then
        run cp "$src" "$dest"
        echo -e "    ${GREEN}+${NC} $(basename "$rel" .md)"
        INSTALLED=$((INSTALLED+1))
      else
        echo -e "    ${YELLOW}?${NC} 未找到: $rel"
        SKIPPED=$((SKIPPED+1))
      fi
    done
  }

  # voltagent-core-dev：严格按 plugin.json agents 列表（11 个）
  # design-bridge 在 Claude Code 仓库里存在但 Codex 仓库没有此文件，此处包含
  cp_agent "voltagent-core-dev  (11 agents)" \
    01-core-development/api-designer.md \
    01-core-development/backend-developer.md \
    01-core-development/design-bridge.md \
    01-core-development/electron-pro.md \
    01-core-development/frontend-developer.md \
    01-core-development/fullstack-developer.md \
    01-core-development/graphql-architect.md \
    01-core-development/microservices-architect.md \
    01-core-development/mobile-developer.md \
    01-core-development/ui-designer.md \
    01-core-development/websocket-engineer.md

  # voltagent-lang：严格按 plugin.json agents 列表（30 个）
  cp_agent "voltagent-lang  (30 agents)" \
    02-language-specialists/angular-architect.md \
    02-language-specialists/cpp-pro.md \
    02-language-specialists/csharp-developer.md \
    02-language-specialists/django-developer.md \
    02-language-specialists/dotnet-core-expert.md \
    02-language-specialists/dotnet-framework-4.8-expert.md \
    02-language-specialists/elixir-expert.md \
    02-language-specialists/expo-react-native-expert.md \
    02-language-specialists/fastapi-developer.md \
    02-language-specialists/flutter-expert.md \
    02-language-specialists/golang-pro.md \
    02-language-specialists/java-architect.md \
    02-language-specialists/javascript-pro.md \
    02-language-specialists/kotlin-specialist.md \
    02-language-specialists/laravel-specialist.md \
    02-language-specialists/nextjs-developer.md \
    02-language-specialists/node-specialist.md \
    02-language-specialists/php-pro.md \
    02-language-specialists/powershell-5.1-expert.md \
    02-language-specialists/powershell-7-expert.md \
    02-language-specialists/python-pro.md \
    02-language-specialists/rails-expert.md \
    02-language-specialists/react-specialist.md \
    02-language-specialists/rust-engineer.md \
    02-language-specialists/spring-boot-engineer.md \
    02-language-specialists/sql-pro.md \
    02-language-specialists/swift-expert.md \
    02-language-specialists/symfony-specialist.md \
    02-language-specialists/typescript-pro.md \
    02-language-specialists/vue-expert.md

  # voltagent-qa-sec：严格按 plugin.json agents 列表（17 个）
  cp_agent "voltagent-qa-sec  (17 agents)" \
    04-quality-security/accessibility-tester.md \
    04-quality-security/ad-security-reviewer.md \
    04-quality-security/ai-writing-auditor.md \
    04-quality-security/architect-reviewer.md \
    04-quality-security/chaos-engineer.md \
    04-quality-security/code-reviewer.md \
    04-quality-security/compliance-auditor.md \
    04-quality-security/debugger.md \
    04-quality-security/error-detective.md \
    04-quality-security/gdpr-ccpa-compliance.md \
    04-quality-security/penetration-tester.md \
    04-quality-security/performance-engineer.md \
    04-quality-security/powershell-security-hardening.md \
    04-quality-security/qa-expert.md \
    04-quality-security/security-auditor.md \
    04-quality-security/test-automator.md \
    04-quality-security/ui-ux-tester.md

  echo ""
  ok "安装完成：${INSTALLED} 个成功，${SKIPPED} 个未找到"

  if ! $DRY_RUN && [ -d "$AGENTS_DIR" ]; then
    TOTAL=$(find "$AGENTS_DIR" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
    echo -e "\n${BOLD}已安装 ${TOTAL} 个 agent：${NC}"
    if [ "$TOTAL" -gt 0 ]; then
      find "$AGENTS_DIR" -maxdepth 1 -type f -name '*.md' -exec basename {} .md \; \
        | sort \
        | pr -3 -t -w 72 \
        | while IFS= read -r line; do echo -e "  ${GREEN}·${NC} $line"; done
    fi
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# 最后一步：写入 ~/.claude/CLAUDE.md
# 有则备份后覆盖，无则新建
# plugin 版：保留 voltagent-xxx: 命名空间（插件自带命名空间，直接生效）
# manual 版：去掉 voltagent-xxx: 命名空间（手动装的 agent 无命名空间）
# ─────────────────────────────────────────────────────────────────────────────
step "3/3" "写入 ~/.claude/CLAUDE.md"

CLAUDE_MD="$HOME/.claude/CLAUDE.md"

if $DRY_RUN; then
  if [ -f "$CLAUDE_MD" ]; then
    echo -e "  ${YELLOW}[dry-run]${NC} 检测到已有 CLAUDE.md → 将备份后覆盖"
    echo -e "  ${YELLOW}[dry-run]${NC} 备份 → ${CLAUDE_MD}.backup.<时间戳>"
  else
    echo -e "  ${YELLOW}[dry-run]${NC} 未检测到 CLAUDE.md → 将新建"
  fi
  echo -e "  ${YELLOW}[dry-run]${NC} 写入 ${CLAUDE_MD}（${MODE} 版本）"
else
  mkdir -p "$HOME/.claude"
  if [ -f "$CLAUDE_MD" ]; then
    BAK="${CLAUDE_MD}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CLAUDE_MD" "$BAK"
    warn "已有 CLAUDE.md，备份 → $BAK"
    info "覆盖写入新版本..."
  else
    info "新建 CLAUDE.md..."
  fi

  # CLAUDE.md 正文单一来源：以 plugin 形态（带 voltagent-xxx: 命名空间）为准维护
  # plugin 模式原样写入；manual 模式经 sed 剥离命名空间前缀后写入
  CLAUDE_BODY=$(cat << 'CLAUDE_EOF'
<!-- WORKFLOW_START -->
## 工作流偏好

**在动任何代码之前，你必须通过 `AskUserQuestion` 工具询问用户使用哪种工作流。没有例外——哪怕是单行修改、拼写修正或"显而易见"的改动。**

### 触发场景（命中任意一条 → 必须询问，且必须在动代码之前询问）

- 编写新代码（新函数 / 文件 / 模块）
- 修改现有代码（编辑、重构、修 bug、风格调整——**单行字符串改动也算**）
- 新增 / 修改测试
- 修改构建配置（package.json / requirements.txt / vite.config / tsconfig / Dockerfile / Makefile / Alembic migration 等）
- 编写实现计划 / 设计文档（plan 工作流的第一步本身就是写计划）

### 无需询问（不属于代码任务）

- 纯讨论 / 问答 / 解释（"X 是什么"、"该用哪个库"）
- 阅读代码 / 阅读文档 / 查符号
- 运行命令（git / pytest / npm run / deploy 等——不修改源码）
- 编辑 `CLAUDE.md` / `settings.json` / auto-memory / 日报等 meta-config / 元数据文件
- 用户已**在当前 session 中**明确选定工作流，且仍处于同一连续任务内（新话题需重新询问）

### 两个选项

1. **plan → subagent → review → verify**：四个阶段全部必做；每个阶段按任务性质挑选最合适的 agent。选择原则：先看任务领域（语言 / 技术栈 / 功能），再看是否有 agent 的描述匹配；没有精确匹配时回退到通用 agent——不要硬套不合适的专精 agent。
   - **Plan**：纯架构权衡用 `voltagent-qa-sec:architect-reviewer`；一般规划用内置的 `Plan` agent。
   - **Subagent（执行）**：按技术栈和领域派发专精 agent。语言类专精走  `voltagent-lang:*`，比如 `voltagent-lang:typescript-pro` / `voltagent-lang:react-specialist` / `voltagent-lang:python-pro` / `voltagent-lang:rust-engineer` / `voltagent-lang:golang-pro` / `voltagent-lang:nextjs-developer`；功能类专精如 `voltagent-core-dev:frontend-developer` / `voltagent-core-dev:backend-developer` / `voltagent-core-dev:fullstack-developer` / `voltagent-core-dev:api-designer`；都不匹配时用内置的 `general-purpose` agent。多个独立子任务可并行时，一次性派发。
   - **Review**：按风险维度挑选 reviewer；多维度风险就并行跑多个。代码质量 → `voltagent-qa-sec:code-reviewer`；安全 → `voltagent-qa-sec:security-auditor` / `voltagent-qa-sec:penetration-tester`；性能 → `voltagent-qa-sec:performance-engineer`；架构 → `voltagent-qa-sec:architect-reviewer`；可访问性 → `voltagent-qa-sec:accessibility-tester`。
   - **Verify**：宣布完成前，你必须运行 tests / build / lint / type-check 拿到通过的证据。只凭 diff 判断成功是不允许的。
2. **Just do it（直接做）**：跳过完整的 plan/subagent 工作流，以任务所需的最小范围直接执行。
   - 当任务是 bug / 测试失败 / 异常行为时：先用 `voltagent-qa-sec:debugger` 或 `voltagent-qa-sec:error-detective` 定位根因再动手。
   - 当修改测试或新增可测逻辑时：先写测试再写实现；需要时用 `voltagent-qa-sec:test-automator`。
   - 宣布完成前，你必须运行 tests / build / lint 拿到证据；只凭 diff 判断成功是不允许的。
   - 只在用户明确要求时才提交。

### 严格规则（违反即错误）

- **不要**凭自己对任务大小的判断跳过询问。"看起来很小"不是跳过的理由。
- **不要**默认进入任一工作流。
- **不要**先改代码再询问。必须先询问。
- **你必须使用** `AskUserQuestion` 工具来询问——不要用纯文本（用户点击选择更方便，且该工具会留下痕迹）。
- 只有在用户回复之后，才开始任何代码相关操作（Read / Edit / Write 等）。
<!-- WORKFLOW_END -->

<!-- NO_FALLBACK_START -->
## 不擅自添加兜底策略

编写代码时不要为了"更稳"擅自添加 fallback、silent catch、默认值吞错、空结果兼容或降级逻辑。除非需求明确要求，遇到异常应让错误快速暴露，便于定位和修复。
<!-- NO_FALLBACK_END -->
CLAUDE_EOF
)

  if [ "$MODE" = "plugin" ]; then
    printf '%s\n' "$CLAUDE_BODY" > "$CLAUDE_MD"
  else
    # manual 版：先转换命名空间集合文案，再剥离具体 agent 的命名空间前缀
    printf '%s\n' "$CLAUDE_BODY" \
      | sed -E \
          -e 's/语言类专精走  `voltagent-lang:\*`，比如/语言类专精走已安装的 agent，比如/' \
          -e 's/voltagent-[a-z-]+://g' \
      > "$CLAUDE_MD"
  fi

  ok "CLAUDE.md 已写入 → $CLAUDE_MD"

  if [ "$MODE" = "manual" ]; then
    RESIDUAL=$(awk '
      {
        line = $0
        while (match(line, /voltagent-[a-z-]+:[a-z-]+/)) {
          count++
          line = substr(line, RSTART + RLENGTH)
        }
      }
      END { print count + 0 }
    ' "$CLAUDE_MD")
    [ "$RESIDUAL" -eq 0 ] \
      && ok "验证通过：CLAUDE.md 无 voltagent 命名空间残留" \
      || { err "CLAUDE.md 仍含 ${RESIDUAL} 处 voltagent 命名空间"; exit 1; }
  fi
fi

echo ""
ok "全部完成，重启 Claude Code 生效"
