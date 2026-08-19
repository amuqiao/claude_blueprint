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
LIST_ONLY=false
VERIFY=false
PLUGIN_SCOPE="user"
PRESET_DIR_VALUE="${CLAUDE_PRESET_DIR:-voltagent-roles-lite}"

MARKETPLACE_REPO="VoltAgent/awesome-claude-code-subagents"
MARKETPLACE_NAME="voltagent-subagents"

ALL_PLUGINS=(
  voltagent-core-dev
  voltagent-lang
  voltagent-infra
  voltagent-qa-sec
  voltagent-data-ai
  voltagent-dev-exp
  voltagent-domains
  voltagent-biz
  voltagent-meta
  voltagent-research
)

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
    *-full) echo "专家插件全量模式" ;;
    *-lite) echo "专家插件精简模式" ;;
    *) echo "专家插件模式" ;;
  esac
}

usage() {
  cat <<'USAGE'
用法: bash setup-claude-code-voltagent-plugins.sh [options]

选项:
  --preset-dir=PATH  模式配置目录；默认 $CLAUDE_PRESET_DIR 或 voltagent-roles-lite
  --dry-run          只预览，不安装或更新 plugin
  --list             列出当前模式将安装的 plugins，不执行安装
  --scope=VALUE      Claude Code plugin 安装范围：user、project 或 local；默认 user
  --verify           安装后检查 marketplace 和 plugin 命令是否可用
  --help, -h         显示帮助

输入:
  <preset-dir>/PLUGIN_ALLOWLIST.txt

示例:
  # 推荐：安装 lite 专家插件
  ./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite

  # 安装默认专家插件
  ./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles

  # 安装全量专家插件
  ./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-full

  # 预览安装，不写入 ~/.claude
  ./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite --dry-run

  # 只列出当前模式会安装哪些 plugins
  ./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite --list

  # 安装到项目级 plugin scope
  ./setup-claude-code-voltagent-plugins.sh --preset-dir=voltagent-roles-lite --scope=project
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --preset-dir=*) PRESET_DIR_VALUE="${arg#--preset-dir=}" ;;
    --dry-run) DRY_RUN=true ;;
    --list) LIST_ONLY=true ;;
    --verify) VERIFY=true ;;
    --scope=*)
      PLUGIN_SCOPE="${arg#--scope=}"
      case "$PLUGIN_SCOPE" in
        user|project|local) ;;
        *) err "--scope 只能是 user、project 或 local"; exit 1 ;;
      esac
      ;;
    --help|-h) usage; exit 0 ;;
    *) err "未知参数: $arg"; usage; exit 1 ;;
  esac
done

PRESET_DIR="$(resolve_preset_dir "$PRESET_DIR_VALUE")"
PRESET_NAME="$(preset_display_name "$PRESET_DIR")"
PLUGIN_ALLOWLIST="$PRESET_DIR/PLUGIN_ALLOWLIST.txt"

if [ ! -d "$PRESET_DIR" ]; then
  err "未找到 preset 配置目录: $PRESET_DIR"
  exit 1
fi

if [ ! -f "$PLUGIN_ALLOWLIST" ]; then
  err "未找到 PLUGIN_ALLOWLIST.txt: $PLUGIN_ALLOWLIST"
  err "当前安装入口要求每个 preset 配置目录显式声明 plugin 清单，避免缺文件时意外安装全量 plugins"
  exit 1
fi

plugin_known() {
  local candidate="$1"
  local plugin
  for plugin in "${ALL_PLUGINS[@]}"; do
    if [ "$plugin" = "$candidate" ]; then
      return 0
    fi
  done
  return 1
}

SELECTED_PLUGINS=()
while IFS= read -r raw_line || [ -n "$raw_line" ]; do
  line="${raw_line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [ -z "$line" ] && continue
  if ! plugin_known "$line"; then
    err "PLUGIN_ALLOWLIST.txt 中存在未知 plugin: $line"
    err "文件: $PLUGIN_ALLOWLIST"
    exit 1
  fi
  SELECTED_PLUGINS+=("$line")
done < "$PLUGIN_ALLOWLIST"

if [ "${#SELECTED_PLUGINS[@]}" -eq 0 ]; then
  err "PLUGIN_ALLOWLIST.txt 为空: $PLUGIN_ALLOWLIST"
  exit 1
fi

if $LIST_ONLY; then
  printf '%s\n' "${SELECTED_PLUGINS[@]}"
  exit 0
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
echo "║   Claude Code VoltAgent Plugins 安装                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Preset dir : ${CYAN}${PRESET_DIR}${NC}"
echo -e "  Mode       : ${CYAN}${PRESET_NAME}${NC}"
echo -e "  Allowlist  : ${CYAN}${PLUGIN_ALLOWLIST}${NC}"
echo -e "  marketplace : ${CYAN}${MARKETPLACE_REPO}${NC}"
echo -e "  plugins     : ${CYAN}${SELECTED_PLUGINS[*]}${NC}"
echo -e "  scope       : ${CYAN}${PLUGIN_SCOPE}${NC}"
$DRY_RUN && warn "DRY-RUN 模式，不会写入任何文件"

step "0/3" "前置检查"
if command -v claude >/dev/null 2>&1; then
  ok "claude $(claude --version 2>/dev/null | head -1 || echo '已安装')"
else
  err "需要 claude 命令；请先安装并登录 Claude Code"
  exit 1
fi

if command -v git >/dev/null 2>&1; then
  ok "git 已安装"
else
  warn "未检测到 git；claude plugin marketplace add 可能仍会自行处理"
fi

step "1/3" "注册或更新 marketplace"
if $DRY_RUN; then
  echo -e "  ${YELLOW}[dry-run]${NC} 如果 marketplace ${MARKETPLACE_NAME} 已存在则 update，否则 add ${MARKETPLACE_REPO}"
elif claude plugin marketplace list | grep -qE "^[[:space:]]*❯ ${MARKETPLACE_NAME}$|^[[:space:]]*${MARKETPLACE_NAME}[[:space:]]"; then
  run claude plugin marketplace update "$MARKETPLACE_NAME"
else
  run claude plugin marketplace add "$MARKETPLACE_REPO"
fi

step "2/3" "安装 plugins"
INSTALLED_LIST=""
if ! $DRY_RUN; then
  INSTALLED_LIST="$(claude plugin list)"
fi

for plugin in "${SELECTED_PLUGINS[@]}"; do
  plugin_ref="${plugin}@${MARKETPLACE_NAME}"
  if $DRY_RUN; then
    info "安装或更新 ${plugin_ref}"
    echo -e "  ${YELLOW}[dry-run]${NC} 如果已安装则 claude plugin update ${plugin_ref}"
    echo -e "  ${YELLOW}[dry-run]${NC} 如果未安装则 claude plugin install --scope ${PLUGIN_SCOPE} ${plugin_ref}"
  elif echo "$INSTALLED_LIST" | grep -qE "^[[:space:]]*❯ ${plugin_ref}$|^[[:space:]]*${plugin_ref}[[:space:]]"; then
    info "更新 ${plugin_ref}"
    run claude plugin update "$plugin_ref"
  else
    info "安装 ${plugin_ref}"
    run claude plugin install --scope "$PLUGIN_SCOPE" "$plugin_ref"
  fi
done

if $VERIFY; then
  step "verify" "检查 Claude Code plugin 命令"
  claude plugin marketplace list >/dev/null
  claude plugin list >/dev/null
  ok "plugin marketplace/list 命令可用"
fi

step "3/3" "下一步"
echo "在 Claude Code 中刷新插件："
echo ""
echo "  /reload-plugins"
echo ""
echo "确认插件状态："
echo ""
echo "  /plugin"
echo ""
echo "可测试："
echo ""
echo "  Use voltagent-lang:typescript-pro to inspect this TypeScript code."
echo "  Use voltagent-qa-sec:code-reviewer to review the current diff."
echo ""
ok "安装流程完成"
