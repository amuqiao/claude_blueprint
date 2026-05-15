#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOCK_FILE="${SOURCE_ROOT}/plugin-install-plan.md"
MODE="plan"
GROUP="core"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/show-plugin-install-commands.sh [--plan <file>] [--prompt] [--extended|--experimental|--all|--extended-only|--experimental-only]

Modes:
  default   Print the plugin install plan and the exact Claude TUI commands.
  --prompt  Print only a paste-ready prompt block for Claude TUI.

Groups:
  default             Output core plugins only.
  --extended          Output core + extended plugins.
  --experimental      Output core + extended + experimental plugins.
  --all               Alias of --experimental.
  --extended-only     Output extended plugins only.
  --experimental-only Output experimental plugins only.
EOF
  printf '\nThis script only shows commands. It does not install plugins by itself.\n'
}

extract_section() {
  local heading="$1"
  awk -v heading="$heading" '
    $0 == "## " heading { in_section=1; next }
    /^## / && in_section { exit }
    in_section { print }
  ' "$LOCK_FILE"
}

extract_backtick_items() {
  sed -n 's/^[[:space:]]*-[[:space:]]*`\([^`][^`]*\)`[[:space:]]*$/\1/p'
}

extract_list_items() {
  sed -n 's/^[[:space:]]*-[[:space:]]*\(.*\)$/\1/p'
}

section_items() {
  local heading="$1"
  extract_section "$heading" | extract_backtick_items
}

section_list_items() {
  local heading="$1"
  extract_section "$heading" | extract_list_items
}

count_items() {
  local items="$1"
  local count=0
  local item

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    count=$((count + 1))
  done <<EOF
$items
EOF

  printf '%s' "$count"
}

filter_notes() {
  local selected_plugins="$1"
  local filtered=""
  local note
  local plugin_name

  while IFS= read -r note; do
    [[ -z "$note" ]] && continue

    if [[ "$note" == '`Core`'* && "$GROUP" != "extended_only" && "$GROUP" != "experimental_only" ]]; then
      filtered="${filtered}${note}"$'\n'
      continue
    fi
    if [[ "$note" == '`Extended`'* && ( "$GROUP" == "extended" || "$GROUP" == "experimental" || "$GROUP" == "all" || "$GROUP" == "extended_only" ) ]]; then
      filtered="${filtered}${note}"$'\n'
      continue
    fi
    if [[ "$note" == '`Experimental`'* && ( "$GROUP" == "experimental" || "$GROUP" == "all" || "$GROUP" == "experimental_only" ) ]]; then
      filtered="${filtered}${note}"$'\n'
      continue
    fi

    if [[ "$note" =~ ^\`([^\`]+)\` ]]; then
      plugin_name="${BASH_REMATCH[1]}"
      if [[ "$selected_plugins" == *"${plugin_name}@"* ]]; then
        filtered="${filtered}${note}"$'\n'
      fi
    fi
  done <<EOF
$NOTES_ITEMS
EOF

  FILTERED_NOTES="${filtered%$'\n'}"
}

print_item_block() {
  local title="$1"
  local items="$2"
  local item

  if [[ -z "$items" ]]; then
    return
  fi

  printf '\n%s:\n' "$title"
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    printf '  - %s\n' "$item"
  done <<EOF
$items
EOF
}

join_item_blocks() {
  local first="$1"
  local second="$2"
  local third="${3-}"

  SELECTED_ITEMS=""

  if [[ -n "$first" ]]; then
    SELECTED_ITEMS="$first"
  fi
  if [[ -n "$second" ]]; then
    if [[ -n "$SELECTED_ITEMS" ]]; then
      SELECTED_ITEMS="${SELECTED_ITEMS}"$'\n'"${second}"
    else
      SELECTED_ITEMS="$second"
    fi
  fi
  if [[ -n "$third" ]]; then
    if [[ -n "$SELECTED_ITEMS" ]]; then
      SELECTED_ITEMS="${SELECTED_ITEMS}"$'\n'"${third}"
    else
      SELECTED_ITEMS="$third"
    fi
  fi
}

load_items() {
  MARKETPLACES="$(section_items "Marketplaces")"
  CORE_ITEMS="$(section_items "Core Plugins")"
  EXTENDED_ITEMS="$(section_items "Extended Plugins")"
  EXPERIMENTAL_ITEMS="$(section_items "Experimental Plugins")"
  NOTES_ITEMS="$(section_list_items "Notes")"

  case "$GROUP" in
    core)
      join_item_blocks "$CORE_ITEMS" ""
      ;;
    extended)
      join_item_blocks "$CORE_ITEMS" "$EXTENDED_ITEMS"
      ;;
    experimental|all)
      join_item_blocks "$CORE_ITEMS" "$EXTENDED_ITEMS" "$EXPERIMENTAL_ITEMS"
      ;;
    extended_only)
      join_item_blocks "$EXTENDED_ITEMS" ""
      ;;
    experimental_only)
      join_item_blocks "$EXPERIMENTAL_ITEMS" ""
      ;;
  esac

  if [[ -z "$CORE_ITEMS" ]]; then
    printf '安装计划中未找到 Core 插件：%s\n' "$LOCK_FILE" >&2
    exit 1
  fi

  if [[ -z "$SELECTED_ITEMS" ]]; then
    EMPTY_SELECTION=1
  else
    EMPTY_SELECTION=0
  fi

  filter_notes "$SELECTED_ITEMS"
}

validate_items() {
  local item

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    if [[ "$item" != *@* ]]; then
      printf '插件条目格式错误：%s\n' "$item" >&2
      printf '文件：%s\n' "$LOCK_FILE" >&2
      printf '期望格式：plugin-name@marketplace\n' >&2
      exit 1
    fi
  done <<EOF
$SELECTED_ITEMS
EOF
}

emit_commands() {
  local marketplace
  local plugin

  while IFS= read -r marketplace; do
    [[ -z "$marketplace" ]] && continue
    if [[ "$marketplace" == "claude-plugins-official" ]]; then
      continue
    fi
    printf '/plugin marketplace add %s\n' "$marketplace"
  done <<EOF
$MARKETPLACES
EOF

  while IFS= read -r plugin; do
    [[ -z "$plugin" ]] && continue
    printf '/plugin install %s\n' "$plugin"
  done <<EOF
$SELECTED_ITEMS
EOF
}

print_plan() {
  local core_count
  local extended_count
  local experimental_count

  core_count="$(count_items "$CORE_ITEMS")"
  extended_count="$(count_items "$EXTENDED_ITEMS")"
  experimental_count="$(count_items "$EXPERIMENTAL_ITEMS")"

  printf '插件安装计划：%s\n' "$LOCK_FILE"
  printf '当前输出层级：%s\n' "$GROUP"
  print_item_block "已声明的插件市场" "$MARKETPLACES"
  printf '\n计划层级概览:\n'
  printf '  - Core：%s 个\n' "$core_count"
  printf '  - Extended：%s 个\n' "$extended_count"
  printf '  - Experimental：%s 个\n' "$experimental_count"
  print_item_block "本次实际输出命令的插件" "$SELECTED_ITEMS"
  print_item_block "本次相关说明" "$FILTERED_NOTES"

  if [[ "$EMPTY_SELECTION" -eq 1 ]]; then
    printf '\n当前所选层级没有插件条目。\n'
    return
  fi

  printf '\n请在 Claude Code session 中执行以下命令：\n'
  emit_commands
}

print_prompt() {
  if [[ "$EMPTY_SELECTION" -eq 1 ]]; then
    printf '当前所选插件层没有条目，无需执行任何 /plugin 命令。\n'
    return
  fi

  printf '请在当前 Claude Code session 中依次执行以下 plugin 安装命令，并在完成后汇报结果。此脚本只展示命令，不会自动安装：\n\n'
  emit_commands
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan)
      LOCK_FILE="$2"
      shift 2
      ;;
    --prompt)
      MODE="prompt"
      shift
      ;;
    --extended)
      GROUP="extended"
      shift
      ;;
    --experimental)
      GROUP="experimental"
      shift
      ;;
    --all)
      GROUP="all"
      shift
      ;;
    --extended-only)
      GROUP="extended_only"
      shift
      ;;
    --experimental-only)
      GROUP="experimental_only"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '未知参数：%s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$LOCK_FILE" ]]; then
  printf '未找到插件安装计划文件：%s\n' "$LOCK_FILE" >&2
  exit 1
fi

load_items
if [[ "$EMPTY_SELECTION" -eq 0 ]]; then
  validate_items
fi

if [[ "$MODE" == "prompt" ]]; then
  print_prompt
else
  print_plan
fi
