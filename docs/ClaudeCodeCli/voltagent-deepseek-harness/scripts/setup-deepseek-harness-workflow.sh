#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC}  $*"; }
warn() { echo -e "${YELLOW}!${NC}  $*"; }
err() { echo -e "${RED}✗${NC}  $*" >&2; }
step() { echo -e "\n${BOLD}${CYAN}[$1]${NC} $2"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false
PROJECT_SCOPE=false
FORCE=false
VERIFY=false
CHECK_PROFILE=false
PRESET_DIR_VALUE="${DSH_PRESET_DIR:-voltagent-roles-lite}"
DSH_HOME_OVERRIDE=""
DSH_PACKAGE="@deepseek-ai/dsh@0.1.0-rc.7"

expand_leading_tilde() {
  case "$1" in
    "~") echo "$HOME" ;;
    "~/"*) echo "$HOME/${1#~/}" ;;
    *) echo "$1" ;;
  esac
}

resolve_preset_dir() {
  local value
  value="$(expand_leading_tilde "$1")"
  case "$value" in
    /*) echo "$value" ;;
    *) echo "$SCRIPT_DIR/$value" ;;
  esac
}

preset_display_name() {
  case "$(basename "$1")" in
    *-full) echo "专家角色全量模式" ;;
    *-lite) echo "专家角色精简模式" ;;
    *) echo "专家角色模式" ;;
  esac
}

usage() {
  cat <<'USAGE'
用法: bash setup-deepseek-harness-workflow.sh [options]

选项:
  --preset-dir=PATH  模式配置目录；默认 $DSH_PRESET_DIR 或 voltagent-roles-lite
  --dry-run          只预览，不写入文件
  --project          写入当前 Git 项目的 AGENTS.md；默认写入 ~/.dsh/AGENTS.md
  --force            显式确认覆盖内容不同的 AGENTS.md；覆盖前会生成 .bak 备份
  --verify           写入后运行 dsh web --dump-config 并检查 subagent/workflow 关键行
  --check-profile    只检查 dsh web profile，不写入 AGENTS.md
  --dsh-home=PATH    指定 DeepSeek Harness home；默认使用 $DSH_HOME 或 ~/.dsh
  --dsh-package=SPEC 指定 npx 包版本；默认 @deepseek-ai/dsh@0.1.0-rc.7
  --help, -h         显示帮助

示例:
  # 推荐：安装 lite 工作流规则到 ~/.dsh/AGENTS.md
  ./setup-deepseek-harness-workflow.sh --preset-dir=voltagent-roles-lite

  # 安装默认专家角色工作流规则
  ./setup-deepseek-harness-workflow.sh --preset-dir=voltagent-roles

  # 安装全量专家角色工作流规则
  ./setup-deepseek-harness-workflow.sh --preset-dir=voltagent-roles-full

  # 写入当前 Git 项目的 AGENTS.md，而不是 ~/.dsh/AGENTS.md
  ./setup-deepseek-harness-workflow.sh --preset-dir=voltagent-roles-lite --project

  # 预览安装，不写入文件
  ./setup-deepseek-harness-workflow.sh --preset-dir=voltagent-roles-lite --dry-run

  # 目标内容不同时显式确认覆盖，覆盖前会生成 .bak 备份
  ./setup-deepseek-harness-workflow.sh --preset-dir=voltagent-roles-lite --force

  # 只检查 dsh web profile 是否包含 subagent/workflow 关键配置
  ./setup-deepseek-harness-workflow.sh --check-profile
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --preset-dir=*) PRESET_DIR_VALUE="${arg#--preset-dir=}" ;;
    --dry-run) DRY_RUN=true ;;
    --project) PROJECT_SCOPE=true ;;
    --force) FORCE=true ;;
    --verify) VERIFY=true ;;
    --check-profile) CHECK_PROFILE=true ;;
    --dsh-home=*)
      DSH_HOME_OVERRIDE="${arg#--dsh-home=}"
      if [ -z "$DSH_HOME_OVERRIDE" ]; then
        err "--dsh-home 不能为空"
        exit 1
      fi
      ;;
    --dsh-package=*)
      DSH_PACKAGE="${arg#--dsh-package=}"
      if [ -z "$DSH_PACKAGE" ]; then
        err "--dsh-package 不能为空"
        exit 1
      fi
      ;;
    --help|-h) usage; exit 0 ;;
    *) err "未知参数: $arg"; usage; exit 1 ;;
  esac
done

PRESET_DIR="$(resolve_preset_dir "$PRESET_DIR_VALUE")"
SOURCE_AGENTS="$PRESET_DIR/AGENTS.md"
PRESET_NAME="$(preset_display_name "$PRESET_DIR")"

if [ ! -d "$PRESET_DIR" ]; then
  err "未找到 preset 配置目录: $PRESET_DIR"
  exit 1
fi

if [ ! -f "$SOURCE_AGENTS" ]; then
  err "未找到模板文件: $SOURCE_AGENTS"
  exit 1
fi

if [ -n "$DSH_HOME_OVERRIDE" ]; then
  TARGET_DSH_HOME="$DSH_HOME_OVERRIDE"
elif [ -n "${DSH_HOME:-}" ]; then
  TARGET_DSH_HOME="$DSH_HOME"
else
  TARGET_DSH_HOME="$HOME/.dsh"
fi

if $PROJECT_SCOPE; then
  PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"
  TARGET_FILE="$PROJECT_ROOT/AGENTS.md"
  SCOPE_LABEL="项目级（${TARGET_FILE}）"
else
  TARGET_FILE="$TARGET_DSH_HOME/AGENTS.md"
  SCOPE_LABEL="全局（${TARGET_FILE}）"
fi

run() {
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} $*"
  else
    "$@"
  fi
}

check_profile() {
  step "profile" "检查 dsh web profile"
  if ! command -v npx >/dev/null 2>&1; then
    err "未检测到 npx，无法检查 dsh web profile"
    exit 1
  fi
  TMP_CONFIG="$(mktemp)"
  trap 'rm -f "$TMP_CONFIG"' EXIT
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} npx ${DSH_PACKAGE} web --dump-config > $TMP_CONFIG"
    return
  fi
  if [ -n "$DSH_HOME_OVERRIDE" ]; then
    DSH_HOME="$TARGET_DSH_HOME" npx "$DSH_PACKAGE" web --dump-config > "$TMP_CONFIG"
  else
    npx "$DSH_PACKAGE" web --dump-config > "$TMP_CONFIG"
  fi
  grep -E 'id: tool-subagent$|toolName: subagent$' "$TMP_CONFIG" >/dev/null
  grep -E 'id: tool-subagent-fork$|toolName: subagent_fork$' "$TMP_CONFIG" >/dev/null
  grep -E 'id: tool-workflow$|name: .+dsh-tool-workflow' "$TMP_CONFIG" >/dev/null
  grep -E 'id: agent-presets$|default: standard' "$TMP_CONFIG" >/dev/null
  ok "dsh web profile 中找到 subagent/workflow 相关配置"
}

echo -e "${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   DeepSeek Harness Multi-Agent Workflow 安装              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Preset dir : ${CYAN}${PRESET_DIR}${NC}"
echo -e "  Mode       : ${CYAN}${PRESET_NAME}${NC}"
echo -e "  安装范围 : ${CYAN}${SCOPE_LABEL}${NC}"
$FORCE && warn "--force 已启用：允许覆盖内容不同的目标 AGENTS.md"
$CHECK_PROFILE && echo -e "  模式     : ${CYAN}只检查 profile，不写入 AGENTS.md${NC}"
$DRY_RUN && warn "DRY-RUN 模式，不会写入任何文件"

step "0/3" "前置检查"
if command -v node >/dev/null 2>&1; then
  ok "node $(node --version)"
else
  warn "未检测到 node；运行 DeepSeek Harness 需要 Node.js 和 npx"
fi

if command -v npx >/dev/null 2>&1; then
  ok "npx 已安装"
else
  warn "未检测到 npx；无法直接启动 @deepseek-ai/dsh"
fi

if command -v git >/dev/null 2>&1; then
  ok "git 已安装"
else
  warn "未检测到 git；项目级安装会退回当前目录"
fi

if $CHECK_PROFILE; then
  check_profile
  ok "profile 检查完成"
  exit 0
fi

step "1/3" "准备目标位置"
TARGET_DIR="$(dirname "$TARGET_FILE")"
run mkdir -p "$TARGET_DIR"

step "2/3" "写入 AGENTS.md"
TMP_EXPECTED=""
ALREADY_CURRENT=false
if $DRY_RUN && [ -e "$TARGET_FILE" ]; then
  warn "目标已存在；真实执行会先比较内容，相同则 no-op，内容不同且未加 --force 会停止"
fi
if ! $DRY_RUN; then
  TMP_EXPECTED="${TARGET_FILE}.expected.$$"
  cp "$SOURCE_AGENTS" "$TMP_EXPECTED"
fi

if [ -e "$TARGET_FILE" ] && ! $DRY_RUN; then
  if cmp -s "$TMP_EXPECTED" "$TARGET_FILE"; then
    [ -n "$TMP_EXPECTED" ] && rm -f "$TMP_EXPECTED"
    TMP_EXPECTED=""
    ALREADY_CURRENT=true
    ok "目标已是最新: $TARGET_FILE"
  elif ! $FORCE; then
    [ -n "$TMP_EXPECTED" ] && rm -f "$TMP_EXPECTED"
    err "目标已存在且内容不同: $TARGET_FILE"
    err "确认要覆盖内容时请加 --force；或使用 --project 写入项目级 AGENTS.md"
    exit 1
  else
    BACKUP_FILE="${TARGET_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$TARGET_FILE" "$BACKUP_FILE"
    ok "已备份旧文件: $BACKUP_FILE"
  fi
fi

if $ALREADY_CURRENT; then
  :
else
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} install $SOURCE_AGENTS > $TARGET_FILE"
  else
    mv "$TMP_EXPECTED" "$TARGET_FILE"
    TMP_EXPECTED=""
  fi
fi
[ -n "$TMP_EXPECTED" ] && rm -f "$TMP_EXPECTED"

if $DRY_RUN; then
  ok "预览写入: $TARGET_FILE"
elif $ALREADY_CURRENT; then
  ok "无需写入: $TARGET_FILE"
else
  ok "已写入: $TARGET_FILE"
fi

step "3/3" "下一步"
echo "启动 DeepSeek Harness Web："
echo ""
echo "  npx ${DSH_PACKAGE} web"
echo ""
echo "验证 profile 是否包含 subagent/workflow 工具："
echo ""
echo "  npx ${DSH_PACKAGE} web --dump-config > /tmp/dsh-web-config.yml"
echo "  grep -E 'id: tool-subagent$|toolName: subagent$' /tmp/dsh-web-config.yml"
echo "  grep -E 'id: tool-subagent-fork$|toolName: subagent_fork$' /tmp/dsh-web-config.yml"
echo "  grep -E 'id: tool-workflow$|name: .+dsh-tool-workflow' /tmp/dsh-web-config.yml"
echo "  grep -E 'id: agent-presets$|default: standard' /tmp/dsh-web-config.yml"
echo ""
echo "Web UI 中选择「${PRESET_NAME}」复现固定角色子 agent。"
echo "不要用「极简模式」复现多 agent 工作流。"
echo "如果已有 dsh web 会话正在运行，请重启或新建会话后再验证 AGENTS.md 行为。"

if $VERIFY; then
  check_profile
fi

ok "安装流程完成"
