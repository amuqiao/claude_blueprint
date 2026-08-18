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
LIST_ONLY=false
AGENTS_CSV=""
AGENTS_FILTER_SET=false
FORCE=false

usage() {
  cat <<'USAGE'
用法: bash setup-codex-subagents-v1.sh [--dry-run] [--project] [--list] [--agents=a,b,c] [--force]

选项:
  --dry-run       只预览，不写入文件
  --project       安装到当前 Git 项目的 .codex/agents/，默认安装到 ~/.codex/agents/
  --list          列出上游可安装 agents，不复制文件
  --agents=a,b,c  只安装指定 agent；不传则安装全部 .toml agents
  --force         允许覆盖未登记在本脚本 manifest 中的同名 agent
  --help, -h      显示帮助
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --project) PROJECT_SCOPE=true ;;
    --list) LIST_ONLY=true ;;
    --agents)
      err "--agents 需要使用 --agents=a,b,c 形式"
      usage
      exit 1
      ;;
    --agents=*)
      AGENTS_FILTER_SET=true
      AGENTS_CSV="${arg#--agents=}"
      if [ -z "$AGENTS_CSV" ]; then
        err "--agents 不能为空"
        exit 1
      fi
      ;;
    --force) FORCE=true ;;
    --help|-h) usage; exit 0 ;;
    *) err "未知参数: $arg"; usage; exit 1 ;;
  esac
done

run() {
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} $*"
  else
    "$@"
  fi
}

REPO_URL="https://github.com/VoltAgent/awesome-codex-subagents.git"

if $PROJECT_SCOPE; then
  PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"
  REPO_CACHE="$PROJECT_ROOT/.codex/_awesome-codex-subagents"
  AGENTS_DIR="$PROJECT_ROOT/.codex/agents"
  SCOPE_LABEL="项目级（${AGENTS_DIR}）"
else
  REPO_CACHE="$HOME/.codex/_awesome-codex-subagents"
  AGENTS_DIR="$HOME/.codex/agents"
  SCOPE_LABEL="全局（${AGENTS_DIR}）"
fi

MANIFEST="$AGENTS_DIR/.voltagent-codex-subagents-v1.txt"

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   VoltAgent Codex Subagents v1 安装                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  安装范围 : ${CYAN}${SCOPE_LABEL}${NC}"
$LIST_ONLY && echo -e "  模式     : ${CYAN}只列出 agents${NC}"
[ -n "$AGENTS_CSV" ] && echo -e "  agents   : ${CYAN}${AGENTS_CSV}${NC}"
$FORCE && warn "--force 已启用：允许覆盖同名未登记 agent"
$DRY_RUN && warn "DRY-RUN 模式，不会写入任何文件"

step "0/3" "前置检查"
command -v git >/dev/null 2>&1 || { err "需要 git"; exit 1; }
ok "git 已安装"

if command -v codex >/dev/null 2>&1; then
  ok "codex $(codex --version 2>/dev/null | head -1 || echo '已安装')"
else
  warn "未检测到 codex 命令；仍可安装 agent 文件，重启 Codex 后生效"
fi

step "1/3" "获取 VoltAgent/awesome-codex-subagents"
if [ -d "$REPO_CACHE/.git" ]; then
  info "缓存仓库已存在，更新..."
  run git -C "$REPO_CACHE" pull --ff-only
else
  info "首次 clone..."
  run git clone --depth=1 "$REPO_URL" "$REPO_CACHE"
fi

SRC_DIR="$REPO_CACHE/categories"
if $DRY_RUN && [ ! -d "$SRC_DIR" ]; then
  warn "dry-run 未实际 clone，跳过本地 agent 清单读取"
  if $LIST_ONLY; then
    exit 0
  fi
fi

if ! $DRY_RUN && [ ! -d "$SRC_DIR" ]; then
  err "未找到 categories 目录: $SRC_DIR"
  exit 1
fi

step "2/3" "解析 agent 清单"

if $DRY_RUN && [ ! -d "$SRC_DIR" ]; then
  SELECTED_COUNT="预览"
  SELECTED_LIST=""
else
  ALL_LIST="$(mktemp)"
  SELECTED_LIST="$(mktemp)"
  SELECTED_NAMES="$(mktemp)"
  NAME_LIST="$(mktemp)"
  OLD_MANIFEST="$(mktemp)"
  trap 'rm -f "$ALL_LIST" "$SELECTED_LIST" "$SELECTED_NAMES" "$NAME_LIST" "$OLD_MANIFEST"' EXIT

  find "$SRC_DIR" -type f -name '*.toml' | sort > "$ALL_LIST"
  if [ ! -s "$ALL_LIST" ]; then
    err "未找到任何 .toml agent: $SRC_DIR"
    exit 1
  fi

  while IFS= read -r file; do
    basename "$file" .toml
  done < "$ALL_LIST" | sort > "$NAME_LIST"

  DUPLICATES="$(uniq -d "$NAME_LIST" | tr '\n' ' ')"
  if [ -n "$DUPLICATES" ]; then
    err "发现重复 agent 文件名，停止安装: $DUPLICATES"
    exit 1
  fi

  if $LIST_ONLY; then
    cat "$NAME_LIST"
    exit 0
  fi

  if $AGENTS_FILTER_SET; then
    : > "$SELECTED_LIST"
    IFS=',' read -ra REQUESTED_AGENTS <<< "$AGENTS_CSV"
    for agent in "${REQUESTED_AGENTS[@]}"; do
      if [ -z "$agent" ]; then
        err "--agents 包含空名称"
        exit 1
      fi
      match="$(find "$SRC_DIR" -type f -name "${agent}.toml" | sort)"
      if [ -z "$match" ]; then
        err "未找到 agent: $agent"
        exit 1
      fi
      if [ "$(echo "$match" | wc -l | tr -d ' ')" -ne 1 ]; then
        err "agent 名称不唯一: $agent"
        echo "$match" >&2
        exit 1
      fi
      echo "$match" >> "$SELECTED_LIST"
    done
  else
    cp "$ALL_LIST" "$SELECTED_LIST"
  fi

  while IFS= read -r file; do
    basename "$file"
  done < "$SELECTED_LIST" | sort > "$SELECTED_NAMES"

  while IFS= read -r file; do
    grep -qE '^name[[:space:]]*=' "$file" || { err "缺少 name 字段: $file"; exit 1; }
    grep -qE '^description[[:space:]]*=' "$file" || { err "缺少 description 字段: $file"; exit 1; }
    grep -qE '^(\[instructions\]|developer_instructions[[:space:]]*=)' "$file" || {
      err "缺少 instructions 定义: $file"
      exit 1
    }
  done < "$SELECTED_LIST"

  SELECTED_COUNT="$(wc -l < "$SELECTED_LIST" | tr -d ' ')"
fi

ok "待安装 agents: $SELECTED_COUNT"

step "3/3" "安装 .toml agents"
run mkdir -p "$AGENTS_DIR"

if $DRY_RUN && [ ! -d "$SRC_DIR" ]; then
  echo -e "  ${YELLOW}[dry-run]${NC} 将从 $SRC_DIR 复制 .toml 到 $AGENTS_DIR"
else
  if [ -f "$MANIFEST" ]; then
    cp "$MANIFEST" "$OLD_MANIFEST"
  else
    : > "$OLD_MANIFEST"
  fi

  while IFS= read -r file; do
    name="$(basename "$file")"
    dest="$AGENTS_DIR/$name"
    if [ -e "$dest" ] && ! grep -Fxq "$name" "$OLD_MANIFEST" && ! $FORCE; then
      err "目标已存在且未登记为本脚本安装: $dest"
      err "如确认要覆盖，请重新运行并加 --force"
      exit 1
    fi
  done < "$SELECTED_LIST"

  while IFS= read -r old_file; do
    [ -z "$old_file" ] && continue
    if ! grep -Fxq "$old_file" "$SELECTED_NAMES"; then
      stale="$AGENTS_DIR/$old_file"
      if [ -e "$stale" ]; then
        run rm "$stale"
      fi
    fi
  done < "$OLD_MANIFEST"

  if ! $DRY_RUN; then
    : > "$MANIFEST"
  fi

  while IFS= read -r file; do
    dest="$AGENTS_DIR/$(basename "$file")"
    run cp "$file" "$dest"
    if ! $DRY_RUN; then
      basename "$file" >> "$MANIFEST"
    fi
  done < "$SELECTED_LIST"
fi

echo ""
echo -e "${BOLD}文件位置：${NC}"
echo -e "  agents   → ${CYAN}${AGENTS_DIR}/${NC}"
echo -e "  manifest → ${CYAN}${MANIFEST}${NC}"
echo ""
ok "安装流程完成；重启或刷新 Codex 后使用"
