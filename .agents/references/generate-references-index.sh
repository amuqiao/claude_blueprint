#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RULES_DIR="${REPO_ROOT}/rules"
OUTPUT_FILE="${REPO_ROOT}/.agents/references/references-index.md"

tmp_file="${OUTPUT_FILE}.tmp"
trap 'rm -f "${tmp_file}"' EXIT

cat <<'EOF' > "${tmp_file}"
# References Index

本文件是当前仓库默认上下文的一部分。

读取要求：

- 在读取仓库根 `AGENTS.md` 后，必须实际读取本文件正文，不能只复述文件路径。
- 本文件用于索引默认参考规则；如需继续展开，应按路径继续读取对应规则文件。

EOF

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

  indexed_rule_file=".agents/rules/$(basename "${rule_file}")"

  printf -- '- description: %s\n' "${description}" >> "${tmp_file}"
  printf -- '- path: `%s`\n\n' "${indexed_rule_file}" >> "${tmp_file}"
done

mv "${tmp_file}" "${OUTPUT_FILE}"
