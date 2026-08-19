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
info() { echo -e "${BLUE}→${NC}  $*"; }
warn() { echo -e "${YELLOW}!${NC}  $*"; }
err() { echo -e "${RED}✗${NC}  $*" >&2; }
step() { echo -e "\n${BOLD}${CYAN}[$1]${NC} $2"; }

DRY_RUN=false
PROJECT_SCOPE=false
FORCE=false
CODEX_HOME_OVERRIDE=""

usage() {
  cat <<'USAGE'
用法: bash setup-codex-workflow.sh [--dry-run] [--project] [--force] [--codex-home=PATH]

选项:
  --dry-run          只预览，不写入文件
  --project          写入当前 Git 项目的 AGENTS.md；默认写入 ~/.codex/AGENTS.md
  --force            允许覆盖目标 AGENTS.md；覆盖前会生成 .bak 备份
  --codex-home=PATH  指定 Codex home；默认使用 $CODEX_HOME 或 ~/.codex
  --help, -h         显示帮助
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --project) PROJECT_SCOPE=true ;;
    --force) FORCE=true ;;
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_AGENTS="$SCRIPT_DIR/AGENTS.md"

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
echo -e "  安装范围 : ${CYAN}${SCOPE_LABEL}${NC}"
$FORCE && warn "--force 已启用：允许覆盖目标 AGENTS.md"
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

if [ -e "$TARGET_FILE" ] && ! $FORCE; then
  if $DRY_RUN; then
    warn "目标已存在；真实安装会停止: $TARGET_FILE"
    warn "确认要覆盖时请加 --force；或使用 --project 写入项目级 AGENTS.md"
    exit 0
  else
    err "目标已存在: $TARGET_FILE"
    err "确认要覆盖时请加 --force；或使用 --project 写入项目级 AGENTS.md"
    exit 1
  fi
fi

step "2/3" "写入 AGENTS.md"
if [ -e "$TARGET_FILE" ] && ! $DRY_RUN; then
  BACKUP_FILE="${TARGET_FILE}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$TARGET_FILE" "$BACKUP_FILE"
  ok "已备份旧文件: $BACKUP_FILE"
fi

run cp "$SOURCE_AGENTS" "$TARGET_FILE"
if $DRY_RUN; then
  ok "预览写入: $TARGET_FILE"
else
  ok "已写入: $TARGET_FILE"
fi

step "3/3" "下一步"
echo "继续安装 Codex custom agents："
echo ""
echo "  bash ${SCRIPT_DIR}/setup-codex-subagents-v1.sh"
echo ""
echo "安装完成后重启或刷新 Codex 会话。"
echo "如果使用项目级规则，也请在同一个项目根目录执行 subagents 安装："
echo ""
echo "  bash ${SCRIPT_DIR}/setup-codex-subagents-v1.sh --project"
echo ""
ok "安装流程完成"
