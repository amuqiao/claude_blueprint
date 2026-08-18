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

DRY_RUN=false
PROJECT_SCOPE=false
FORCE=false
CLAUDE_HOME_OVERRIDE=""

usage() {
  cat <<'USAGE'
用法: bash setup-claude-code-workflow.sh [--dry-run] [--project] [--force] [--claude-home=PATH]

选项:
  --dry-run            只预览，不写入文件
  --project            写入当前 Git 项目的 CLAUDE.md；默认写入 ~/.claude/CLAUDE.md
  --force              允许覆盖目标 CLAUDE.md；覆盖前会生成 .bak 备份
  --claude-home=PATH   指定 Claude home；默认使用 $CLAUDE_HOME 或 ~/.claude
  --help, -h           显示帮助
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --project) PROJECT_SCOPE=true ;;
    --force) FORCE=true ;;
    --claude-home=*)
      CLAUDE_HOME_OVERRIDE="${arg#--claude-home=}"
      if [ -z "$CLAUDE_HOME_OVERRIDE" ]; then
        err "--claude-home 不能为空"
        exit 1
      fi
      ;;
    --help|-h) usage; exit 0 ;;
    *) err "未知参数: $arg"; usage; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CLAUDE="$SCRIPT_DIR/CLAUDE.md"

if [ ! -f "$SOURCE_CLAUDE" ]; then
  err "未找到模板文件: $SOURCE_CLAUDE"
  exit 1
fi

if [ -n "$CLAUDE_HOME_OVERRIDE" ]; then
  TARGET_CLAUDE_HOME="$CLAUDE_HOME_OVERRIDE"
elif [ -n "${CLAUDE_HOME:-}" ]; then
  TARGET_CLAUDE_HOME="$CLAUDE_HOME"
else
  TARGET_CLAUDE_HOME="$HOME/.claude"
fi

if $PROJECT_SCOPE; then
  PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"
  TARGET_FILE="$PROJECT_ROOT/CLAUDE.md"
  SCOPE_LABEL="项目级（${TARGET_FILE}）"
else
  TARGET_FILE="$TARGET_CLAUDE_HOME/CLAUDE.md"
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
echo "║   Claude Code Multi-Agent Workflow 安装             ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  安装范围 : ${CYAN}${SCOPE_LABEL}${NC}"
$FORCE && warn "--force 已启用：允许覆盖目标 CLAUDE.md"
$DRY_RUN && warn "DRY-RUN 模式，不会写入任何文件"

step "0/3" "前置检查"
if command -v claude >/dev/null 2>&1; then
  ok "claude $(claude --version 2>/dev/null | head -1 || echo '已安装')"
else
  warn "未检测到 claude 命令；仍可复制 CLAUDE.md，安装 Claude Code 后生效"
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
    warn "确认要覆盖时请加 --force；或使用 --project 写入项目级 CLAUDE.md"
    exit 0
  else
    err "目标已存在: $TARGET_FILE"
    err "确认要覆盖时请加 --force；或使用 --project 写入项目级 CLAUDE.md"
    exit 1
  fi
fi

step "2/3" "写入 CLAUDE.md"
if [ -e "$TARGET_FILE" ] && ! $DRY_RUN; then
  BACKUP_FILE="${TARGET_FILE}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$TARGET_FILE" "$BACKUP_FILE"
  ok "已备份旧文件: $BACKUP_FILE"
fi

run cp "$SOURCE_CLAUDE" "$TARGET_FILE"
if $DRY_RUN; then
  ok "预览写入: $TARGET_FILE"
else
  ok "已写入: $TARGET_FILE"
fi

step "3/3" "下一步"
echo "继续安装 Claude Code plugins："
echo ""
echo "  bash ${SCRIPT_DIR}/setup-claude-code-subagents.sh"
echo ""
echo "安装完成后重启 Claude Code，或在 Claude Code 中运行 /reload-plugins。"
ok "安装流程完成"
