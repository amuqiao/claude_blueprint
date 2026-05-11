#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
command="$(
  printf '%s' "$payload" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(data.get("tool_input", {}).get("command", ""))
'
)"

if [[ -z "${command}" ]]; then
  exit 0
fi

if [[ "$command" =~ (^|[[:space:][:punct:]])git[[:space:]]+push([[:space:]]|$) ]]; then
  python3 - <<'PY'
import json

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": (
            "git push is blocked by policy. "
            "Pushes stay in the human's hands after manual review."
        ),
    }
}))
PY
fi

