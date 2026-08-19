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
CONVERTER="$SCRIPT_DIR/../common/convert-codex-agents-to-dsh-preset.py"
PYTHON_BIN="${PYTHON_BIN:-python3}"

DRY_RUN=false
FORCE=false
VERIFY=false
PRESET_ID="codex-roles-full"
DSH_HOME_VALUE="${DSH_HOME:-$HOME/.dsh}"
STANDARD_PRESET_DIR=""
REPO_URL="https://github.com/VoltAgent/awesome-codex-subagents.git"
REPO_CACHE=""
SOURCE_DIR=""
SOURCE_MODE="git"
STRICT_AWESOME_SOURCE=false
SKIP_GENERATE=false

expand_leading_tilde() {
  case "$1" in
    "~") echo "$HOME" ;;
    "~/"*) echo "$HOME/${1#~/}" ;;
    *) echo "$1" ;;
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

usage() {
  cat <<'USAGE'
用法: bash setup-deepseek-harness-codex-agents.sh [options]

选项:
  --dry-run                    只预览，不写入 ~/.dsh
  --force                      允许覆盖已存在的 Harness preset，覆盖前生成 .bak 备份
  --verify                     生成后检查 dsh 命令可用并提示重启 Web UI
  --preset-id=ID               Harness preset id；默认 codex-roles-full
  --repo-url=URL               上游仓库；默认 VoltAgent/awesome-codex-subagents
  --repo-cache=PATH            上游仓库缓存目录；默认 <dsh-home>/_awesome-codex-subagents
  --local-source=PATH          离线安装：使用本地 awesome-codex-subagents 源码目录，跳过 git
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
    --local-source=*) SOURCE_DIR="${arg#--local-source=}"; SOURCE_MODE="local"; STRICT_AWESOME_SOURCE=true ;;
    --source-dir=*) SOURCE_DIR="${arg#--source-dir=}"; SOURCE_MODE="local" ;;
    --codex-agents-dir=*) SOURCE_DIR="${arg#--codex-agents-dir=}"; SOURCE_MODE="local" ;;
    --dsh-home=*) DSH_HOME_VALUE="${arg#--dsh-home=}" ;;
    --standard-preset-dir=*) STANDARD_PRESET_DIR="${arg#--standard-preset-dir=}" ;;
    --help|-h) usage; exit 0 ;;
    *) err "未知参数: $arg"; usage; exit 1 ;;
  esac
done

if [ "$SOURCE_MODE" = "local" ] && [ -z "$SOURCE_DIR" ]; then
  err "本地 source 参数不能为空"
  exit 1
fi

if [ -n "$SOURCE_DIR" ]; then
  SOURCE_DIR="$(expand_leading_tilde "$SOURCE_DIR")"
fi

if [ -z "$REPO_CACHE" ]; then
  REPO_CACHE="$DSH_HOME_VALUE/_awesome-codex-subagents"
fi
REPO_CACHE="$(expand_leading_tilde "$REPO_CACHE")"

echo -e "${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   DeepSeek Harness Full Expert Role Preset 安装           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  DSH home   : ${CYAN}${DSH_HOME_VALUE}${NC}"
echo -e "  Preset id  : ${CYAN}${PRESET_ID}${NC}"
if [ -n "$SOURCE_DIR" ]; then
  echo -e "  Source mode: ${CYAN}${SOURCE_MODE}${NC}"
  echo -e "  Source dir : ${CYAN}${SOURCE_DIR}${NC}"
else
  echo -e "  Source mode: ${CYAN}git${NC}"
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
  validate_source_dir "$SOURCE_DIR" "source"
  print_source_revision "$SOURCE_DIR" "source"
else
  command -v git >/dev/null 2>&1 || { err "需要 git 获取 VoltAgent/awesome-codex-subagents"; exit 1; }
  ok "git 已安装"
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
  SKIP_GENERATE=true
else
  info "首次 clone..."
  mkdir -p "$(dirname "$REPO_CACHE")"
  git clone --depth=1 "$REPO_URL" "$REPO_CACHE"
  SOURCE_DIR="$REPO_CACHE"
  STRICT_AWESOME_SOURCE=true
  validate_source_dir "$SOURCE_DIR" "repo cache"
  print_source_revision "$SOURCE_DIR" "repo cache"
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
  SOURCE_COUNT="$(count_source_toml "$SOURCE_DIR")"
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
    echo "请重启 dsh web，然后在 Web UI 新建会话时选择「专家角色全量模式」。"
  else
    warn "未检测到全局 dsh；preset 已生成，但无法检查 dsh 命令"
  fi
fi

step "4/4" "下一步"
cat <<EOF
启动或重启 DeepSeek Harness Web：

  dsh web

在 Web UI 新建会话时选择：

  专家角色全量模式

工具命名规则：

  Upstream role: api-designer
  Harness tool: subagent_api_designer

如需设为默认 preset，可在 Web UI 的 Agent presets 设置里选择默认值，
或编辑 \$DSH_HOME/settings.yaml 的 agent-presets.default。
EOF

ok "安装流程完成"
