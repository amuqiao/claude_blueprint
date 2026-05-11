#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="$HOME/.claude"
DRY_RUN=0
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR=""

usage() {
  cat <<'EOF'
Usage:
  bash scripts/backup-claude.sh [--target <dir>] [--dry-run]
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$cmd" >&2
    exit 1
  fi
}

run_cmd() {
  local cmd_str
  printf -v cmd_str '%q ' "$@"
  printf '+ %s\n' "${cmd_str% }"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$@"
  fi
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

BACKUP_DIR="${TARGET_DIR}.backup.${TIMESTAMP}"

require_cmd rsync

if [[ ! -d "$TARGET_DIR" ]]; then
  printf 'Target directory does not exist: %s\n' "$TARGET_DIR" >&2
  exit 1
fi

run_cmd mkdir -p "$BACKUP_DIR"
run_cmd rsync -a "${TARGET_DIR}/" "${BACKUP_DIR}/"

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '\nDry run only. No files were changed.\n'
else
  printf '\nBackup created: %s\n' "$BACKUP_DIR"
fi
