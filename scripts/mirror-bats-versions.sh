#!/usr/bin/env bash
# Run scripts/mirror-bats.sh for the bats version test/.prototools pins, the
# latest upstream release, and any versions in EXTRA_VERSIONS (space-separated).
# Used by .github/workflows/mirror-bats.yml.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pinned="$(sed -n 's/^bats = "\([0-9][^"]*\)"$/\1/p' "$root/test/.prototools")"
if [[ -z "$pinned" ]]; then
    echo "error: test/.prototools pins no bats version" >&2
    exit 1
fi
latest="$(gh release view --repo bats-core/bats-core --json tagName --jq .tagName)"
read -r -a extra <<<"${EXTRA_VERSIONS:-}"

mapfile -t versions < <(printf '%s\n' "$pinned" "${latest#v}" "${extra[@]}" | sort -u)
exec "$root/scripts/mirror-bats.sh" "${versions[@]}"
