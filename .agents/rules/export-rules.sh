#!/usr/bin/env bash
# Requires: Bash 4.x+
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SOURCE_DIR="${REPO_ROOT}/rules"

TARGET_PROJECT=""
USE_ALL=0
LIST_ONLY=0
SELECTED_TOKENS=()

usage() {
  cat <<'EOF'
用法：
  .agents/rules/export-rules.sh --target /path/to/project
  .agents/rules/export-rules.sh --target /path/to/project --all
  .agents/rules/export-rules.sh --target /path/to/project --rules git.md writing.md
  .agents/rules/export-rules.sh --list
  .agents/rules/export-rules.sh -h

作用：
  从当前仓库的 rules/ 真源目录中选择规则，复制到目标项目的 .agents/rules/ 目录，
  并在终端输出可粘贴到目标项目 AGENTS.md 的 References Index 片段。

运行环境：
  Linux + Bash。依赖常见命令：dirname、find、sort、awk、basename、mkdir、cp。

环境变量：
  本脚本不读取环境变量。

参数：
  -t, --target <path>      目标项目目录。脚本会写入 <path>/.agents/rules/
  -r, --rules <rules...>   指定要复制的规则，支持文件名、无 .md 后缀名称或序号
      --all                复制全部规则
      --list               只列出当前可选规则，不复制文件
  -h, --help               显示本帮助信息

交互模式：
  不传 --rules 或 --all 时，脚本会列出规则并等待输入。
  支持输入序号、文件名或 all，例如：
    1,3,5
    git.md writing.md
    git writing
    all

示例：
  .agents/rules/export-rules.sh --target ~/Code/new-project --rules git.md testing.md
  .agents/rules/export-rules.sh --target ~/Code/new-project --all
  .agents/rules/export-rules.sh --list

执行结果：
  1. 复制选中的规则文件到目标项目 .agents/rules/
  2. 在终端输出 References Index，手动复制到目标项目 AGENTS.md

幂等性和副作用：
  重复执行会覆盖目标项目 .agents/rules/ 中同名规则文件。
  本脚本不删除目标项目中未被本次选择的其他规则文件，不使用锁文件。
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

check_dependencies() {
  local command_name
  for command_name in dirname find sort awk basename mkdir cp; do
    command -v "$command_name" >/dev/null 2>&1 || fail "missing required command: $command_name"
  done
}

require_tty() {
  local reason="$1"
  [[ -t 0 ]] || fail "$reason; pass required values by arguments in non-TTY mode"
}

# 解析命令行参数；不指定规则时稍后进入交互选择。
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target|-t)
      [[ $# -ge 2 ]] || fail "--target requires a project path"
      TARGET_PROJECT="$2"
      shift 2
      ;;
    --all)
      USE_ALL=1
      shift
      ;;
    --rules|-r)
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do
        SELECTED_TOKENS+=("$1")
        shift
      done
      [[ ${#SELECTED_TOKENS[@]} -gt 0 ]] || fail "--rules requires at least one rule"
      ;;
    --list)
      LIST_ONLY=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

if [[ "$USE_ALL" -eq 1 && ${#SELECTED_TOKENS[@]} -gt 0 ]]; then
  fail "use either --all or --rules, not both"
fi

check_dependencies

[[ -d "$SOURCE_DIR" ]] || fail "source rules directory not found: $SOURCE_DIR"

# 规则真源固定为仓库根目录下的 rules/*.md。
RULE_FILES=()
while IFS= read -r file; do
  RULE_FILES+=("$file")
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f -name '*.md' -print | sort)
[[ ${#RULE_FILES[@]} -gt 0 ]] || fail "no rule files found in: $SOURCE_DIR"

# 每条规则必须在 frontmatter 中声明 description，用于生成 AGENTS.md 索引。
description_for() {
  local file="$1"
  local description
  description="$(
    awk '
      NR == 1 && $0 != "---" { exit 2 }
      NR > 1 && $0 == "---" { exit }
      NR > 1 && /^description:[[:space:]]*/ {
        sub(/^description:[[:space:]]*/, "")
        print
        found = 1
        exit
      }
      END {
        if (!found) exit 3
      }
    ' "$file"
  )" || fail "missing frontmatter description: $file"
  [[ -n "$description" ]] || fail "empty frontmatter description: $file"
  printf '%s\n' "$description"
}

print_available_rules() {
  local index=1
  local file
  for file in "${RULE_FILES[@]}"; do
    printf '  %d. %s - %s\n' "$index" "$(basename "$file")" "$(description_for "$file")"
    index=$((index + 1))
  done
}

if [[ "$LIST_ONLY" -eq 1 ]]; then
  printf 'Available rules:\n'
  print_available_rules
  exit 0
fi

# 目标项目可以通过 --target 传入；未传时进入交互输入。
if [[ -z "$TARGET_PROJECT" ]]; then
  require_tty "target project path is required"
  printf 'Target project path: '
  read -r TARGET_PROJECT
fi

[[ -n "$TARGET_PROJECT" ]] || fail "target project path is required"
[[ -d "$TARGET_PROJECT" ]] || fail "target project does not exist: $TARGET_PROJECT"

select_all_rules() {
  SELECTED_RULES=("${RULE_FILES[@]}")
}

select_rules_by_tokens() {
  SELECTED_RULES=()
  local token normalized file found position

  # 支持通过序号、完整文件名或省略 .md 后缀的名称选择规则。
  for token in "$@"; do
    found=0

    if [[ "$token" =~ ^[0-9]+$ ]]; then
      position=$((token - 1))
      if [[ "$position" -lt 0 || "$position" -ge "${#RULE_FILES[@]}" ]]; then
        fail "invalid rule number: $token"
      fi
      file="${RULE_FILES[$position]}"
      found=1
    else
      normalized="$token"
      if [[ "$normalized" != *.md ]]; then
        normalized="${normalized}.md"
      fi

      for file in "${RULE_FILES[@]}"; do
        if [[ "$(basename "$file")" == "$normalized" ]]; then
          found=1
          break
        fi
      done
    fi

    [[ "$found" -eq 1 ]] || fail "unknown rule: $token"

    local existing
    for existing in "${SELECTED_RULES[@]:-}"; do
      if [[ "$existing" == "$file" ]]; then
        continue 2
      fi
    done
    SELECTED_RULES+=("$file")
  done

  [[ ${#SELECTED_RULES[@]} -gt 0 ]] || fail "no rules selected"
}

if [[ "$USE_ALL" -eq 1 ]]; then
  select_all_rules
elif [[ ${#SELECTED_TOKENS[@]} -gt 0 ]]; then
  select_rules_by_tokens "${SELECTED_TOKENS[@]}"
else
  require_tty "rules selection is required"
  printf 'Available rules:\n'
  print_available_rules
  printf '\nSelect rules by number or file name.\n'
  printf 'Examples: 1,3,5 | git.md writing.md | all\n'
  printf 'Rules to include: '
  read -r RAW_SELECTION
  [[ -n "$RAW_SELECTION" ]] || fail "no rules selected"

  if [[ "$RAW_SELECTION" == "all" ]]; then
    select_all_rules
  else
    read -r -a SELECTED_TOKENS <<< "${RAW_SELECTION//,/ }"
    select_rules_by_tokens "${SELECTED_TOKENS[@]}"
  fi
fi

TARGET_RULE_DIR="${TARGET_PROJECT}/.agents/rules"
mkdir -p "$TARGET_RULE_DIR"

# 只把选中的规则复制到目标项目；当前仓库 .agents/rules/ 不保存生成物。
for file in "${SELECTED_RULES[@]}"; do
  cp "$file" "${TARGET_RULE_DIR}/$(basename "$file")"
done

printf '\nCopied rules to: %s\n' "$TARGET_RULE_DIR"
for file in "${SELECTED_RULES[@]}"; do
  printf '  - %s\n' "$(basename "$file")"
done

cat <<'EOF'

----- Copy the following into target AGENTS.md -----

# References Index

本索引用于在新项目的 `AGENTS.md` 中声明需要加载的通用规则。

读取要求：

- 在读取仓库根 `AGENTS.md` 后，必须实际读取本索引正文，不能只复述文件路径。
- 本索引用于定位默认参考规则；如需继续展开，应按路径继续读取对应规则文件。

EOF

for file in "${SELECTED_RULES[@]}"; do
  rule_name="$(basename "$file")"
  description="$(description_for "$file")"
  printf -- '- description: %s\n' "$description"
  printf -- '- path: `.agents/rules/%s`\n\n' "$rule_name"
done

cat <<'EOF'
----- End -----
EOF
