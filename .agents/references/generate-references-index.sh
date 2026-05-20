#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RULES_DIR="${REPO_ROOT}/rules"
OUTPUT_FILE="${REPO_ROOT}/.agents/references/references-index.md"

tmp_file="${OUTPUT_FILE}.tmp"
trap 'rm -f "${tmp_file}"' EXIT

printf '# References Index\n\n' > "${tmp_file}"

find "${RULES_DIR}" -maxdepth 1 -type f -name '*.md' | sort | while IFS= read -r rule_file; do
  description="$(awk '
    BEGIN { in_frontmatter = 0 }
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    in_frontmatter && $0 ~ /^description:[[:space:]]*/ {
      sub(/^description:[[:space:]]*/, "", $0)
      gsub(/^["'\'']|["'\'']$/, "", $0)
      print
      exit
    }
  ' "${rule_file}")"

  if [[ -z "${description}" ]]; then
    echo "error: ${rule_file} 缺少 description" >&2
    exit 1
  fi

  printf -- '- description: %s\n' "${description}" >> "${tmp_file}"
  printf -- '- path: `%s`\n\n' "${rule_file}" >> "${tmp_file}"
done

mv "${tmp_file}" "${OUTPUT_FILE}"
