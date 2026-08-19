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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false
PROJECT_SCOPE=false
LIST_ONLY=false
FORCE=false
VERIFY=false
PRESET_DIR_VALUE="${CODEX_PRESET_DIR:-voltagent-roles-lite}"
CODEX_HOME_VALUE="${CODEX_HOME:-$HOME/.codex}"
REPO_URL="https://github.com/VoltAgent/awesome-codex-subagents.git"
REPO_CACHE=""
SOURCE_DIR=""
SOURCE_MODE="git"
STRICT_AWESOME_SOURCE=false
SKIP_INSTALL=false

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

count_source_toml() {
  local source_path="$1"
  if [ -d "$source_path/categories" ]; then
    find "$source_path/categories" -type f -name '*.toml' | wc -l | tr -d ' '
  else
    find "$source_path" -type f -name '*.toml' | wc -l | tr -d ' '
  fi
}

validate_source_dir() {
  local source_path="$1"
  local label="$2"
  if [ ! -d "$source_path" ]; then
    err "未找到 $label 目录: $source_path"
    exit 1
  fi

  if $STRICT_AWESOME_SOURCE && [ ! -d "$source_path/categories" ]; then
    err "$label 不是有效的 awesome-codex-subagents 源码目录: $source_path"
    err "缺少 categories/；请指定 VoltAgent/awesome-codex-subagents 仓库根目录"
    exit 1
  fi

  local role_count
  role_count="$(count_source_toml "$source_path")"
  if [ "$role_count" = "0" ]; then
    err "$label 中未找到 .toml 角色文件: $source_path"
    err "离线源码目录应至少包含 categories/**/*.toml"
    exit 1
  fi
  ok "$label 角色文件: $role_count 个"
}

print_source_revision() {
  local source_path="$1"
  local label="$2"
  command -v git >/dev/null 2>&1 || return 0
  [ -e "$source_path/.git" ] || return 0
  if git -C "$source_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local revision
    revision="$(git -C "$source_path" rev-parse --short HEAD)"
    ok "$label revision: $revision"
  fi
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
用法: bash setup-codex-voltagent-roles.sh [options]

选项:
  --preset-dir=PATH     模式配置目录；默认 $CODEX_PRESET_DIR 或 voltagent-roles-lite
  --dry-run             只预览，不写入 ~/.codex 或项目 .codex
  --project             安装到当前 Git 项目的 .codex/agents/，默认安装到 ~/.codex/agents/
  --force               显式确认覆盖同名未登记 agent
  --verify              安装后检查 codex 命令是否可用
  --list                列出将全量安装的角色，不复制文件
  --repo-url=URL        上游仓库；默认 VoltAgent/awesome-codex-subagents
  --repo-cache=PATH     上游仓库缓存目录；默认 <codex-home>/_awesome-codex-subagents
  --local-source=PATH   离线安装：使用本地 awesome-codex-subagents 源码目录，跳过 git
  --source-dir=PATH     跳过 git clone/pull，直接从该目录读取 .toml 角色
  --codex-home=PATH     Codex home；默认 $CODEX_HOME 或 ~/.codex
  --help, -h            显示帮助

生成位置:
  全局：<codex-home>/agents/*.toml
  项目：<project-root>/.codex/agents/*.toml

示例:
  # 推荐：安装全量专家角色池，使用 lite 工作流路由
  ./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles-lite

  # 安装全量专家角色池，使用默认专家工作流路由
  ./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles

  # 安装全量专家角色池，使用全量专家工作流路由
  ./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles-full

  # 离线安装：从本地 awesome-codex-subagents 源码目录读取角色
  ./setup-codex-voltagent-roles.sh \
    --preset-dir=voltagent-roles-lite \
    --local-source=/Users/admin/Downloads/Code/claude_blueprint/docs/ClaudeCodeCli/awesome-codex-subagents

  # 预览安装，不写入 ~/.codex
  ./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles-lite --dry-run

  # 目标存在同名未登记 agent 时显式确认覆盖
  ./setup-codex-voltagent-roles.sh --preset-dir=voltagent-roles-lite --force
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --preset-dir=*) PRESET_DIR_VALUE="${arg#--preset-dir=}" ;;
    --dry-run) DRY_RUN=true ;;
    --project) PROJECT_SCOPE=true ;;
    --force) FORCE=true ;;
    --verify) VERIFY=true ;;
    --list) LIST_ONLY=true ;;
    --repo-url=*) REPO_URL="${arg#--repo-url=}" ;;
    --repo-cache=*) REPO_CACHE="${arg#--repo-cache=}" ;;
    --local-source=*) SOURCE_DIR="${arg#--local-source=}"; SOURCE_MODE="local"; STRICT_AWESOME_SOURCE=true ;;
    --source-dir=*) SOURCE_DIR="${arg#--source-dir=}"; SOURCE_MODE="local" ;;
    --codex-home=*) CODEX_HOME_VALUE="${arg#--codex-home=}" ;;
    --help|-h) usage; exit 0 ;;
    *) err "未知参数: $arg"; usage; exit 1 ;;
  esac
done

if [ "$SOURCE_MODE" = "local" ] && [ -z "$SOURCE_DIR" ]; then
  err "本地 source 参数不能为空"
  exit 1
fi

PRESET_DIR="$(resolve_preset_dir "$PRESET_DIR_VALUE")"
if [ ! -d "$PRESET_DIR" ]; then
  err "未找到 preset 配置目录: $PRESET_DIR"
  exit 1
fi

PRESET_NAME="$(preset_display_name "$PRESET_DIR")"
ROUTE_ALLOWLIST="$PRESET_DIR/ROUTE_ALLOWLIST.txt"

if [ -n "$SOURCE_DIR" ]; then
  SOURCE_DIR="$(expand_leading_tilde "$SOURCE_DIR")"
fi

CODEX_HOME_VALUE="$(expand_leading_tilde "$CODEX_HOME_VALUE")"

if $PROJECT_SCOPE; then
  PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"
  REPO_CACHE="${REPO_CACHE:-$PROJECT_ROOT/.codex/_awesome-codex-subagents}"
  AGENTS_DIR="$PROJECT_ROOT/.codex/agents"
  SCOPE_LABEL="项目级（${AGENTS_DIR}）"
else
  REPO_CACHE="${REPO_CACHE:-$CODEX_HOME_VALUE/_awesome-codex-subagents}"
  AGENTS_DIR="$CODEX_HOME_VALUE/agents"
  SCOPE_LABEL="全局（${AGENTS_DIR}）"
fi
REPO_CACHE="$(expand_leading_tilde "$REPO_CACHE")"
MANIFEST="$AGENTS_DIR/.voltagent-codex-subagents-v1.txt"
ROUTE_COUNT=""
if [ -f "$ROUTE_ALLOWLIST" ]; then
  ROUTE_COUNT="$(grep -v '^[[:space:]]*#' "$ROUTE_ALLOWLIST" | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')"
fi

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Codex VoltAgent Roles 安装                        ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Preset dir : ${CYAN}${PRESET_DIR}${NC}"
echo -e "  Mode       : ${CYAN}${PRESET_NAME}${NC}"
echo -e "  安装范围 : ${CYAN}${SCOPE_LABEL}${NC}"
echo -e "  安装策略 : ${CYAN}全量安装上游 .toml agents${NC}"
if [ -f "$ROUTE_ALLOWLIST" ]; then
  echo -e "  Route list : ${CYAN}${ROUTE_ALLOWLIST}${NC}"
  echo -e "  路由参考 : ${CYAN}${ROUTE_COUNT}${NC}"
else
  warn "未找到 ROUTE_ALLOWLIST.txt；继续全量安装 agents，但无法显示该模式的路由参考数量"
fi
if [ -n "$SOURCE_DIR" ]; then
  echo -e "  Source mode: ${CYAN}${SOURCE_MODE}${NC}"
  echo -e "  Source dir : ${CYAN}${SOURCE_DIR}${NC}"
else
  echo -e "  Source mode: ${CYAN}git${NC}"
  echo -e "  Repo       : ${CYAN}${REPO_URL}${NC}"
  echo -e "  Repo cache : ${CYAN}${REPO_CACHE}${NC}"
fi
$LIST_ONLY && echo -e "  模式     : ${CYAN}只列出全量安装 roles${NC}"
$FORCE && warn "--force 已启用：允许覆盖同名未登记 agent"
$DRY_RUN && warn "DRY-RUN 模式，不会写入任何文件"

step "0/4" "前置检查"
if command -v codex >/dev/null 2>&1; then
  ok "codex $(codex --version 2>/dev/null | head -1 || echo '已安装')"
else
  warn "未检测到 codex 命令；仍可安装 agent 文件，重启 Codex 后生效"
fi
if [ -n "$SOURCE_DIR" ]; then
  validate_source_dir "$SOURCE_DIR" "source"
  print_source_revision "$SOURCE_DIR" "source"
else
  command -v git >/dev/null 2>&1 || { err "需要 git 获取 VoltAgent/awesome-codex-subagents"; exit 1; }
  ok "git 已安装"
fi
if [ -f "$ROUTE_ALLOWLIST" ]; then
  ok "路由参考清单存在: $ROUTE_COUNT 个"
fi

step "1/4" "获取 VoltAgent/awesome-codex-subagents"
if [ -n "$SOURCE_DIR" ]; then
  ok "使用本地 source 目录，跳过 git clone/pull"
elif [ -d "$REPO_CACHE/.git" ]; then
  info "缓存仓库已存在，更新..."
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} git -C $REPO_CACHE pull --ff-only"
  else
    git -C "$REPO_CACHE" pull --ff-only
  fi
  SOURCE_DIR="$REPO_CACHE"
  STRICT_AWESOME_SOURCE=true
  validate_source_dir "$SOURCE_DIR" "repo cache"
  print_source_revision "$SOURCE_DIR" "repo cache"
elif [ -e "$REPO_CACHE" ]; then
  err "repo cache 路径已存在但不是 git 仓库: $REPO_CACHE"
  err "请换一个 --repo-cache 路径，或手动处理该目录后重试"
  exit 1
elif $DRY_RUN; then
  warn "dry-run 未实际 clone；如果本地没有缓存，后续只展示将执行的动作"
  echo -e "  ${YELLOW}[dry-run]${NC} git clone --depth=1 $REPO_URL $REPO_CACHE"
  SOURCE_DIR="$REPO_CACHE"
  SKIP_INSTALL=true
else
  info "首次 clone..."
  mkdir -p "$(dirname "$REPO_CACHE")"
  git clone --depth=1 "$REPO_URL" "$REPO_CACHE"
  SOURCE_DIR="$REPO_CACHE"
  STRICT_AWESOME_SOURCE=true
  validate_source_dir "$SOURCE_DIR" "repo cache"
  print_source_revision "$SOURCE_DIR" "repo cache"
fi

step "2/4" "解析角色清单"
if $SKIP_INSTALL; then
  SRC_ROOT="$SOURCE_DIR/categories"
  if $LIST_ONLY; then
    warn "dry-run 未实际 clone，无法列出远程角色"
    exit 0
  fi
  ok "待安装 agents: 全量上游角色"
else
  SRC_ROOT="$SOURCE_DIR"
  if [ -d "$SOURCE_DIR/categories" ]; then
    SRC_ROOT="$SOURCE_DIR/categories"
  fi

  ALL_LIST="$(mktemp)"
  SELECTED_LIST="$(mktemp)"
  SELECTED_NAMES="$(mktemp)"
  OLD_MANIFEST="$(mktemp)"
  trap 'rm -f "$ALL_LIST" "$SELECTED_LIST" "$SELECTED_NAMES" "$OLD_MANIFEST"' EXIT

  find "$SRC_ROOT" -type f -name '*.toml' | sort > "$ALL_LIST"
  if [ ! -s "$ALL_LIST" ]; then
    err "未找到任何 .toml agent: $SRC_ROOT"
    exit 1
  fi

  cp "$ALL_LIST" "$SELECTED_LIST"
  SELECTED_COUNT="$(wc -l < "$SELECTED_LIST" | tr -d ' ')"

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

  if $LIST_ONLY; then
    while IFS= read -r file; do
      basename "$file" .toml
    done < "$SELECTED_LIST"
    exit 0
  fi

  ok "待安装 agents: $SELECTED_COUNT"
fi

step "3/4" "安装 .toml agents"
if $SKIP_INSTALL; then
  echo -e "  ${YELLOW}[dry-run]${NC} 将从 $SRC_ROOT 复制全部 .toml 到 $AGENTS_DIR"
else
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} mkdir -p $AGENTS_DIR"
  else
    mkdir -p "$AGENTS_DIR"
  fi

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
      err "确认要覆盖同名未登记 agent 时请加 --force"
      exit 1
    fi
  done < "$SELECTED_LIST"

  while IFS= read -r old_file || [ -n "$old_file" ]; do
    [ -z "$old_file" ] && continue
    if ! grep -Fxq "$old_file" "$SELECTED_NAMES"; then
      stale="$AGENTS_DIR/$old_file"
      if [ -e "$stale" ]; then
        if $DRY_RUN; then
          echo -e "  ${YELLOW}[dry-run]${NC} rm $stale"
        else
          rm "$stale"
        fi
      fi
    fi
  done < "$OLD_MANIFEST"

  if ! $DRY_RUN; then
    : > "$MANIFEST"
  fi

  while IFS= read -r file; do
    dest="$AGENTS_DIR/$(basename "$file")"
    if $DRY_RUN; then
      echo -e "  ${YELLOW}[dry-run]${NC} cp $file $dest"
    else
      cp "$file" "$dest"
      basename "$file" >> "$MANIFEST"
    fi
  done < "$SELECTED_LIST"
fi

step "4/4" "验证结果"
if $SKIP_INSTALL; then
  ok "dry-run 跳过文件验证"
elif $DRY_RUN; then
  ok "dry-run 跳过文件验证"
else
  INSTALLED_COUNT="$(find "$AGENTS_DIR" -maxdepth 1 -type f -name '*.toml' | wc -l | tr -d ' ')"
  MANIFEST_COUNT="$(wc -l < "$MANIFEST" | tr -d ' ')"
  if [ "$MANIFEST_COUNT" != "$SELECTED_COUNT" ]; then
    err "manifest 角色数量不匹配: expected=$SELECTED_COUNT manifest=$MANIFEST_COUNT"
    exit 1
  fi
  ok "manifest 角色数量: $MANIFEST_COUNT / $SELECTED_COUNT"
  ok "当前 agents 目录 .toml 数量: $INSTALLED_COUNT"
fi

if $VERIFY; then
  if command -v codex >/dev/null 2>&1; then
    ok "codex $(codex --version 2>/dev/null | head -1 || echo '已安装')"
  else
    warn "未检测到 codex 命令；agent 文件已准备好，安装 Codex CLI 后重启会话"
  fi
fi

echo ""
echo -e "${BOLD}文件位置：${NC}"
echo -e "  agents   → ${CYAN}${AGENTS_DIR}/${NC}"
echo -e "  manifest → ${CYAN}${MANIFEST}${NC}"
echo ""
ok "安装流程完成；重启或刷新 Codex 后使用"
