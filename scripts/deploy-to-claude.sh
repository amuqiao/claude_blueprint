#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="$HOME/.claude"
DRY_RUN=0
MANIFEST_FILE="${SOURCE_ROOT}/deploy-manifest.txt"
MANAGED_PATHS=()

usage() {
  cat <<'EOF'
Usage:
  bash scripts/deploy-to-claude.sh [--target <dir>] [--dry-run]
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$cmd" >&2
    exit 1
  fi
}

load_manifest() {
  if [[ ! -f "$MANIFEST_FILE" ]]; then
    printf 'Deploy manifest not found: %s\n' "$MANIFEST_FILE" >&2
    exit 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [[ -z "$line" || "${line:0:1}" == "#" ]]; then
      continue
    fi
    line="${line%/}"
    MANAGED_PATHS+=("$line")
  done < "$MANIFEST_FILE"

  if [[ "${#MANAGED_PATHS[@]}" -eq 0 ]]; then
    printf 'Deploy manifest is empty: %s\n' "$MANIFEST_FILE" >&2
    exit 1
  fi
}

print_plan_entry() {
  local status="$1"
  local rel="$2"
  printf '  %-10s %s\n' "$status" "$rel"
}

plan_file() {
  local src="$1"
  local rel="${src#${SOURCE_ROOT}/}"
  local dest="${TARGET_DIR}/${rel}"

  if [[ ! -e "$dest" ]]; then
    print_plan_entry "NEW" "$rel"
    return
  fi

  if cmp -s "$src" "$dest"; then
    print_plan_entry "UNCHANGED" "$rel"
  else
    print_plan_entry "UPDATE" "$rel"
  fi
}

plan_directory() {
  local src_dir="$1"
  local rel_dir="${src_dir#${SOURCE_ROOT}/}"
  local dest_dir="${TARGET_DIR}/${rel_dir}"

  if [[ ! -d "$dest_dir" ]]; then
    print_plan_entry "MKDIR" "$rel_dir/"
  fi

  while IFS= read -r path; do
    local rel="${path#${SOURCE_ROOT}/}"
    local dest="${TARGET_DIR}/${rel}"
    if [[ -d "$path" ]]; then
      if [[ ! -d "$dest" ]]; then
        print_plan_entry "MKDIR" "${rel}/"
      fi
    elif [[ -f "$path" ]]; then
      plan_file "$path"
    fi
  done < <(find "$src_dir" -mindepth 1 | sort)
}

show_plan() {
  printf 'Sync plan:\n'
  for path in "${MANAGED_PATHS[@]}"; do
    local src="${SOURCE_ROOT}/${path}"
    if [[ ! -e "$src" ]]; then
      continue
    fi
    if [[ -d "$src" ]]; then
      plan_directory "$src"
    elif [[ -f "$src" ]]; then
      plan_file "$src"
    fi
  done
  printf '\n'
}

run_rsync() {
  local src="$1"
  local dest="$2"
  local -a args=(-a)
  printf '+ sync %s -> %s\n' "${src#${SOURCE_ROOT}/}" "$dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    args+=(-n)
  fi
  rsync "${args[@]}" "$src" "$dest"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_cmd rsync
load_manifest

if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "$TARGET_DIR"
else
  printf '+ mkdir -p %q\n' "$TARGET_DIR"
fi

printf 'Source repo: %s\n' "$SOURCE_ROOT"
printf 'Target dir:  %s\n' "$TARGET_DIR"
printf 'Manifest:    %s\n' "$MANIFEST_FILE"
printf '\nManaged paths:\n'
for path in "${MANAGED_PATHS[@]}"; do
  printf '  - %s\n' "$path"
done
printf '\n'

show_plan

for path in "${MANAGED_PATHS[@]}"; do
  src="${SOURCE_ROOT}/${path}"
  if [[ ! -e "$src" ]]; then
    continue
  fi
  run_rsync "$src" "$TARGET_DIR/"
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '\nDry run only. No files were changed.\n'
else
  printf '\nDeploy finished.\n'
  printf 'Target: %s\n' "$TARGET_DIR"
fi
