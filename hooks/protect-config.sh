#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
file_path="$(
  printf '%s' "$payload" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(data.get("tool_input", {}).get("file_path", ""))
'
)"

if [[ -z "${file_path}" ]]; then
  exit 0
fi

case "$file_path" in
  */CLAUDE.md|CLAUDE.md|\
  */settings.json|settings.json|\
  */.claude/settings.json|.claude/settings.json|\
  */.claude/settings.local.json|.claude/settings.local.json|\
  */.claude/rules/*|.claude/rules/*|\
  */.claude/commands/*|.claude/commands/*|\
  */docs/design/INDEX.md|docs/design/INDEX.md|\
  */pyproject.toml|pyproject.toml|\
  */alembic.ini|alembic.ini|\
  */package.json|package.json|\
  */package-lock.json|package-lock.json|\
  */pnpm-lock.yaml|pnpm-lock.yaml|\
  */yarn.lock|yarn.lock|\
  */eslint.config.*|eslint.config.*|\
  */.eslintrc|.eslintrc|\
  */.eslintrc.*|.eslintrc.*|\
  */tsconfig.json|tsconfig.json|\
  */tsconfig.*.json|tsconfig.*.json|\
  */vite.config.*|vite.config.*|\
  */next.config.*|next.config.*|\
  */tailwind.config.*|tailwind.config.*|\
  */prettier.config.*|prettier.config.*|\
  */.prettierrc|.prettierrc|\
  */.prettierrc.*|.prettierrc.*|\
  */ruff.toml|ruff.toml|\
  */mypy.ini|mypy.ini)
    python3 - "$file_path" <<'PY'
import json
import sys

path = sys.argv[1]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": (
            f"准备修改关键配置或控制文件: {path}. "
            "请确认这是有意为之，而不是通过改配置绕过实现或验证。"
        ),
    }
}, ensure_ascii=False))
PY
    ;;
esac
