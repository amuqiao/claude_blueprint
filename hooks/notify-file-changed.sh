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
  */agents/*.md|agents/*.md|\
  */skills/*/SKILL.md|skills/*/SKILL.md|\
  */commands/*.md|commands/*.md|\
  */templates/*|templates/*|\
  */WHY.md|WHY.md)
    printf '[hook] Updated OS control file: %s\n' "$file_path" >&2
    printf '[hook] Check whether related instructions, settings, and docs still match.\n' >&2
    ;;
  */docs/design/INDEX.md|docs/design/INDEX.md)
    printf '[hook] Updated docs/design/INDEX.md\n' >&2
    printf '[hook] Verify the module sync status matches the current implementation state.\n' >&2
    ;;
  */.claude/settings.json|.claude/settings.json|\
  */.claude/rules/*|.claude/rules/*|\
  */.claude/commands/*|.claude/commands/*)
    printf '[hook] Updated project Claude config: %s\n' "$file_path" >&2
    printf '[hook] Verify the project-level rules still align with CLAUDE.md and real workflows.\n' >&2
    ;;
esac

