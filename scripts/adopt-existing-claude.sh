#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$HOME/.claude}"
REPO_URL="${2:-https://github.com/amuqiao/claude_blueprint.git}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${TARGET_DIR}.backup.${TIMESTAMP}"
TMP_DIR="$(mktemp -d)"
TMP_REPO="${TMP_DIR}/repo"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$cmd" >&2
    exit 1
  fi
}

require_cmd git
require_cmd rsync

if [[ ! -d "$TARGET_DIR" ]]; then
  printf 'Target directory does not exist: %s\n' "$TARGET_DIR" >&2
  printf 'Use git clone for a fresh install instead.\n' >&2
  exit 1
fi

printf 'Backing up %s -> %s\n' "$TARGET_DIR" "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
rsync -a "${TARGET_DIR}/" "${BACKUP_DIR}/"

printf 'Cloning %s -> %s\n' "$REPO_URL" "$TMP_REPO"
git clone "$REPO_URL" "$TMP_REPO"

if [[ -d "${TARGET_DIR}/.git" ]]; then
  printf 'Moving existing git metadata -> %s/.git.backup.%s\n' "$TARGET_DIR" "$TIMESTAMP"
  mv "${TARGET_DIR}/.git" "${TARGET_DIR}/.git.backup.${TIMESTAMP}"
fi

printf 'Syncing tracked repository files into %s\n' "$TARGET_DIR"
rsync -av --exclude '.git' "${TMP_REPO}/" "${TARGET_DIR}/"

printf 'Installing repository git metadata into %s/.git\n' "$TARGET_DIR"
cp -R "${TMP_REPO}/.git" "${TARGET_DIR}/.git"

printf '\nDone.\n'
printf 'Backup: %s\n' "$BACKUP_DIR"
printf 'Repo:   %s\n' "$REPO_URL"
printf '\nNext steps:\n'
printf '  cd %s\n' "$TARGET_DIR"
printf '  git status\n'
printf '  git pull --ff-only origin main\n'

printf '\nCurrent git status:\n'
git -C "$TARGET_DIR" status --short
