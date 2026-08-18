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
LIST_ONLY=false
PLUGINS_CSV=""
PLUGIN_SCOPE="user"

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

usage() {
  cat <<'USAGE'
用法: bash setup-claude-code-subagents.sh [--dry-run] [--list] [--plugins=a,b,c] [--scope=user|project|local]

选项:
  --dry-run        只预览，不写入文件
  --list           列出默认安装的 Claude Code plugins
  --plugins=a,b,c  只安装指定 plugin；不传则安装全部 VoltAgent Claude Code plugins
  --scope=VALUE    Claude Code plugin 安装范围：user、project 或 local；默认 user
  --help, -h       显示帮助
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --list) LIST_ONLY=true ;;
    --plugins)
      err "--plugins 需要使用 --plugins=a,b,c 形式"
      usage
      exit 1
      ;;
    --plugins=*)
      PLUGINS_CSV="${arg#--plugins=}"
      if [ -z "$PLUGINS_CSV" ]; then
        err "--plugins 不能为空"
        exit 1
      fi
      ;;
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
if [ -n "$PLUGINS_CSV" ]; then
  IFS=',' read -ra REQUESTED_PLUGINS <<< "$PLUGINS_CSV"
  for plugin in "${REQUESTED_PLUGINS[@]}"; do
    if [ -z "$plugin" ]; then
      err "--plugins 包含空名称"
      exit 1
    fi
    if ! plugin_known "$plugin"; then
      err "未知 plugin: $plugin"
      err "可用列表可通过 --list 查看"
      exit 1
    fi
    SELECTED_PLUGINS+=("$plugin")
  done
else
  SELECTED_PLUGINS=("${ALL_PLUGINS[@]}")
fi

if $LIST_ONLY; then
  printf '%s\n' "${ALL_PLUGINS[@]}"
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
echo "║   VoltAgent Claude Code Subagents 安装              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
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
elif claude plugin marketplace list | grep -qE "^[[:space:]]*❯ ${MARKETPLACE_NAME}$"; then
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
  elif echo "$INSTALLED_LIST" | grep -qE "^[[:space:]]*❯ ${plugin_ref}$"; then
    info "更新 ${plugin_ref}"
    run claude plugin update "$plugin_ref"
  else
    info "安装 ${plugin_ref}"
    run claude plugin install --scope "$PLUGIN_SCOPE" "$plugin_ref"
  fi
done

step "3/3" "下一步"
echo "在 Claude Code 中确认插件状态："
echo ""
echo "  /plugin"
echo ""
echo "刷新插件："
echo ""
echo "  /reload-plugins"
echo ""
echo "可测试："
echo ""
echo "  Use voltagent-lang:typescript-pro to inspect this TypeScript code."
echo "  Use voltagent-qa-sec:code-reviewer to review the current diff."
echo ""
ok "安装流程完成"
