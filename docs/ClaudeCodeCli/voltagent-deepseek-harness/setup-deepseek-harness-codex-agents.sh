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
CONVERTER="$SCRIPT_DIR/convert-codex-agents-to-dsh-preset.py"
PYTHON_BIN="${PYTHON_BIN:-python3}"

DRY_RUN=false
FORCE=false
VERIFY=false
PRESET_ID="codex-roles"
DSH_HOME_VALUE="${DSH_HOME:-$HOME/.dsh}"
STANDARD_PRESET_DIR=""
REPO_URL="https://github.com/VoltAgent/awesome-codex-subagents.git"
REPO_CACHE=""
SOURCE_DIR=""
SKIP_GENERATE=false

usage() {
  cat <<'USAGE'
用法: bash setup-deepseek-harness-codex-agents.sh [options]

选项:
  --dry-run                    只预览，不写入 ~/.dsh
  --force                      允许覆盖已存在的 Harness preset，覆盖前生成 .bak 备份
  --verify                     生成后检查 dsh 命令可用并提示重启 Web UI
  --preset-id=ID               Harness preset id；默认 codex-roles
  --repo-url=URL               上游仓库；默认 VoltAgent/awesome-codex-subagents
  --repo-cache=PATH            上游仓库缓存目录；默认 <dsh-home>/_awesome-codex-subagents
  --source-dir=PATH            跳过 git clone/pull，直接从该目录读取 .toml 角色
  --codex-agents-dir=PATH      兼容旧参数；等同 --source-dir=PATH
  --dsh-home=PATH              DeepSeek Harness home；默认 $DSH_HOME 或 ~/.dsh
  --standard-preset-dir=PATH   dsh 内置 standard preset 目录；默认自动定位全局 dsh 安装
  --help, -h                   显示帮助

生成位置:
  <dsh-home>/.agent-presets/<preset-id>/
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --verify) VERIFY=true ;;
    --preset-id=*) PRESET_ID="${arg#--preset-id=}" ;;
    --repo-url=*) REPO_URL="${arg#--repo-url=}" ;;
    --repo-cache=*) REPO_CACHE="${arg#--repo-cache=}" ;;
    --source-dir=*) SOURCE_DIR="${arg#--source-dir=}" ;;
    --codex-agents-dir=*) SOURCE_DIR="${arg#--codex-agents-dir=}" ;;
    --dsh-home=*) DSH_HOME_VALUE="${arg#--dsh-home=}" ;;
    --standard-preset-dir=*) STANDARD_PRESET_DIR="${arg#--standard-preset-dir=}" ;;
    --help|-h) usage; exit 0 ;;
    *) err "未知参数: $arg"; usage; exit 1 ;;
  esac
done

if [ -z "$REPO_CACHE" ]; then
  REPO_CACHE="$DSH_HOME_VALUE/_awesome-codex-subagents"
fi

echo -e "${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   DeepSeek Harness Expert Role Preset 安装                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  DSH home   : ${CYAN}${DSH_HOME_VALUE}${NC}"
echo -e "  Preset id  : ${CYAN}${PRESET_ID}${NC}"
if [ -n "$SOURCE_DIR" ]; then
  echo -e "  Source dir : ${CYAN}${SOURCE_DIR}${NC}"
else
  echo -e "  Repo       : ${CYAN}${REPO_URL}${NC}"
  echo -e "  Repo cache : ${CYAN}${REPO_CACHE}${NC}"
fi
$DRY_RUN && warn "DRY-RUN 模式，不会写入任何文件"
$FORCE && warn "--force 已启用：允许替换同名 Harness preset"

step "0/4" "前置检查"
if command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  PYTHON_VERSION="$("$PYTHON_BIN" --version)"
  ok "$PYTHON_VERSION"
else
  err "未检测到 $PYTHON_BIN；转换 TOML roles 需要 Python 3"
  exit 1
fi

if [ -f "$CONVERTER" ]; then
  ok "转换器存在: $CONVERTER"
else
  err "未找到转换器: $CONVERTER"
  exit 1
fi

if [ -n "$SOURCE_DIR" ]; then
  if [ -d "$SOURCE_DIR" ]; then
    ok "source 目录存在"
  else
    err "未找到 source 目录: $SOURCE_DIR"
    exit 1
  fi
else
  command -v git >/dev/null 2>&1 || { err "需要 git 获取 VoltAgent/awesome-codex-subagents"; exit 1; }
  ok "git 已安装"
fi

step "1/4" "获取 VoltAgent/awesome-codex-subagents"
if [ -n "$SOURCE_DIR" ]; then
  ok "使用显式 source 目录，跳过 git clone/pull"
elif $DRY_RUN && [ ! -d "$REPO_CACHE/.git" ]; then
  warn "dry-run 未实际 clone；如果本地没有缓存，后续只展示将执行的动作"
  echo -e "  ${YELLOW}[dry-run]${NC} git clone --depth=1 $REPO_URL $REPO_CACHE"
  SOURCE_DIR="$REPO_CACHE"
  SKIP_GENERATE=true
elif [ -d "$REPO_CACHE/.git" ]; then
  info "缓存仓库已存在，更新..."
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[dry-run]${NC} git -C $REPO_CACHE pull --ff-only"
  else
    git -C "$REPO_CACHE" pull --ff-only
  fi
  SOURCE_DIR="$REPO_CACHE"
else
  info "首次 clone..."
  mkdir -p "$(dirname "$REPO_CACHE")"
  git clone --depth=1 "$REPO_URL" "$REPO_CACHE"
  SOURCE_DIR="$REPO_CACHE"
fi

step "2/4" "生成 Harness preset"
ARGS=(
  "$CONVERTER"
  "--source-dir=$SOURCE_DIR"
  "--dsh-home=$DSH_HOME_VALUE"
  "--preset-id=$PRESET_ID"
)
$DRY_RUN && ARGS+=("--dry-run")
$FORCE && ARGS+=("--force")
if [ -n "$STANDARD_PRESET_DIR" ]; then
  ARGS+=("--standard-preset-dir=$STANDARD_PRESET_DIR")
fi
if $SKIP_GENERATE; then
  echo -e "  ${YELLOW}[dry-run]${NC} $PYTHON_BIN ${ARGS[*]}"
else
  "$PYTHON_BIN" "${ARGS[@]}"
fi

TARGET_DIR="$("$PYTHON_BIN" - "$DSH_HOME_VALUE" "$PRESET_ID" <<'PY'
from pathlib import Path
import sys
print((Path(sys.argv[1]).expanduser() / ".agent-presets" / sys.argv[2]).resolve())
PY
)"

step "3/4" "验证生成结果"
if $DRY_RUN; then
  ok "dry-run 跳过文件验证"
elif [ -f "$TARGET_DIR/agent.cordis.yml" ] && [ -f "$TARGET_DIR/preset.yml" ]; then
  COUNT="$(find "$TARGET_DIR/agents" -maxdepth 1 -type f -name '*.cordis.yml' ! -name 'index.cordis.yml' | wc -l | tr -d ' ')"
  RUNTIME_ROLE_COUNT="$(grep -c '^- id: tool-subagent-role-' "$TARGET_DIR/agent.cordis.yml")"
  if [ -d "$SOURCE_DIR/categories" ]; then
    SOURCE_COUNT="$(find "$SOURCE_DIR/categories" -type f -name '*.toml' | wc -l | tr -d ' ')"
  else
    SOURCE_COUNT="$(find "$SOURCE_DIR" -type f -name '*.toml' | wc -l | tr -d ' ')"
  fi
  if [ "$COUNT" != "$SOURCE_COUNT" ]; then
    err "生成角色文件数量不匹配: source=$SOURCE_COUNT generated=$COUNT"
    exit 1
  fi
  if [ "$RUNTIME_ROLE_COUNT" != "$SOURCE_COUNT" ]; then
    err "运行时入口角色数量不匹配: source=$SOURCE_COUNT runtime=$RUNTIME_ROLE_COUNT"
    exit 1
  fi
  ok "生成角色文件数量: $COUNT / $SOURCE_COUNT"
  ok "运行时入口角色数量: $RUNTIME_ROLE_COUNT / $SOURCE_COUNT"
  ok "入口文件: $TARGET_DIR/agent.cordis.yml"
  ok "角色索引: $TARGET_DIR/agents/index.cordis.yml"
  ok "映射表: $TARGET_DIR/agent-role-map.md"
else
  err "生成结果不完整: $TARGET_DIR"
  exit 1
fi

if $VERIFY && ! $DRY_RUN; then
  step "verify" "检查 dsh web 是否可用"
  if command -v dsh >/dev/null 2>&1; then
    ok "dsh $(dsh --version)"
    echo "请重启 dsh web，然后在 Web UI 新建会话时选择「专家角色模式」。"
  else
    warn "未检测到全局 dsh；preset 已生成，但无法检查 dsh 命令"
  fi
fi

step "4/4" "下一步"
cat <<EOF
启动或重启 DeepSeek Harness Web：

  dsh web

在 Web UI 新建会话时选择：

  专家角色模式

工具命名规则：

  Upstream role: api-designer
  Harness tool: subagent_api_designer

如需设为默认 preset，可在 Web UI 的 Agent presets 设置里选择默认值，
或编辑 \$DSH_HOME/settings.yaml 的 agent-presets.default。
EOF

ok "安装流程完成"
