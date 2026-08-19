#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
PRESET_DIR_VALUE="${CODEX_PRESET_DIR:-voltagent-roles-lite}"
CODEX_HOME_OVERRIDE=""

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
用法: bash setup-codex-workflow.sh [options]

选项:
  --preset-dir=PATH   模式配置目录；默认 $CODEX_PRESET_DIR 或 voltagent-roles-lite
  --dry-run           只预览，不写入文件
  --project           写入当前 Git 项目的 AGENTS.md；默认写入 ~/.codex/AGENTS.md
  --force             显式确认覆盖内容不同的 AGENTS.md；覆盖前会生成 .bak 备份
  --verify            写入后检查 codex 命令是否可用
  --codex-home=PATH   指定 Codex home；默认使用 $CODEX_HOME 或 ~/.codex
  --help, -h          显示帮助

示例:
  # 推荐：安装 lite 工作流规则到 ~/.codex/AGENTS.md
  ./setup-codex-workflow.sh --preset-dir=voltagent-roles-lite

  # 安装默认专家角色工作流规则
  ./setup-codex-workflow.sh --preset-dir=voltagent-roles

  # 安装全量专家角色工作流规则
  ./setup-codex-workflow.sh --preset-dir=voltagent-roles-full

  # 写入当前 Git 项目的 AGENTS.md，而不是 ~/.codex/AGENTS.md
  ./setup-codex-workflow.sh --preset-dir=voltagent-roles-lite --project

  # 预览安装，不写入文件
  ./setup-codex-workflow.sh --preset-dir=voltagent-roles-lite --dry-run

  # 目标内容不同时显式确认覆盖，覆盖前会生成 .bak 备份
  ./setup-codex-workflow.sh --preset-dir=voltagent-roles-lite --force
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --preset-dir=*) PRESET_DIR_VALUE="${arg#--preset-dir=}" ;;
    --dry-run) DRY_RUN=true ;;
    --project) PROJECT_SCOPE=true ;;
    --force) FORCE=true ;;
    --verify) VERIFY=true ;;
    --codex-home=*)
      CODEX_HOME_OVERRIDE="${arg#--codex-home=}"
      if [ -z "$CODEX_HOME_OVERRIDE" ]; then
        err "--codex-home 不能为空"
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

if [ -n "$CODEX_HOME_OVERRIDE" ]; then
  TARGET_CODEX_HOME="$CODEX_HOME_OVERRIDE"
elif [ -n "${CODEX_HOME:-}" ]; then
  TARGET_CODEX_HOME="$CODEX_HOME"
else
  TARGET_CODEX_HOME="$HOME/.codex"
fi

if $PROJECT_SCOPE; then
  PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"
  TARGET_FILE="$PROJECT_ROOT/AGENTS.md"
  SCOPE_LABEL="项目级（${TARGET_FILE}）"
else
  TARGET_FILE="$TARGET_CODEX_HOME/AGENTS.md"
  SCOPE_LABEL="全局（${TARGET_FILE}）"
fi

run() {
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} $*"
  else
    "$@"
  fi
}

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Codex Multi-Agent Workflow 安装                   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Preset dir : ${CYAN}${PRESET_DIR}${NC}"
echo -e "  Mode       : ${CYAN}${PRESET_NAME}${NC}"
echo -e "  安装范围 : ${CYAN}${SCOPE_LABEL}${NC}"
$FORCE && warn "--force 已启用：允许覆盖内容不同的目标 AGENTS.md"
$DRY_RUN && warn "DRY-RUN 模式，不会写入任何文件"

step "0/3" "前置检查"
if command -v codex >/dev/null 2>&1; then
  ok "codex $(codex --version 2>/dev/null | head -1 || echo '已安装')"
else
  warn "未检测到 codex 命令；仍可复制 AGENTS.md，安装 Codex CLI 后生效"
fi

if command -v git >/dev/null 2>&1; then
  ok "git 已安装"
else
  warn "未检测到 git；项目级安装会退回当前目录"
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
    rm -f "$TMP_EXPECTED"
    TMP_EXPECTED=""
    ALREADY_CURRENT=true
    ok "目标已是最新: $TARGET_FILE"
  elif ! $FORCE; then
    rm -f "$TMP_EXPECTED"
    TMP_EXPECTED=""
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
elif $DRY_RUN; then
  echo -e "  ${YELLOW}[dry-run]${NC} install $SOURCE_AGENTS > $TARGET_FILE"
else
  mv "$TMP_EXPECTED" "$TARGET_FILE"
  TMP_EXPECTED=""
fi
[ -n "$TMP_EXPECTED" ] && rm -f "$TMP_EXPECTED"

if $DRY_RUN; then
  ok "预览写入: $TARGET_FILE"
elif $ALREADY_CURRENT; then
  ok "无需写入: $TARGET_FILE"
else
  ok "已写入: $TARGET_FILE"
fi

if $VERIFY; then
  step "verify" "检查 Codex CLI"
  if command -v codex >/dev/null 2>&1; then
    ok "codex $(codex --version 2>/dev/null | head -1 || echo '已安装')"
  else
    warn "未检测到 codex 命令；请安装 Codex CLI 后重启会话"
  fi
fi

step "3/3" "下一步"
cat <<EOF
继续安装 Codex custom agents：

  bash ${SCRIPT_DIR}/setup-codex-voltagent-roles.sh --preset-dir=$(basename "$PRESET_DIR")

安装完成后重启或刷新 Codex 会话。
如果使用项目级规则，也请在同一个项目根目录执行 roles 安装：

  bash ${SCRIPT_DIR}/setup-codex-voltagent-roles.sh --preset-dir=$(basename "$PRESET_DIR") --project
EOF

ok "安装流程完成"
