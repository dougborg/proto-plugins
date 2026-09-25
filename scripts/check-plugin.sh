#!/usr/bin/env bash
# Install one tool through its plugin in plugins/ at the version pinned in
# test/.prototools, then check that the installed tool reports that version.
#
#   scripts/check-plugin.sh sops
set -euo pipefail

tool="${1:?usage: scripts/check-plugin.sh <tool>}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$root/test"

if [[ ! -f "$root/plugins/$tool.toml" ]]; then
    echo "error: no plugin at plugins/$tool.toml" >&2
    exit 1
fi

# The version pin, not the [plugins.tools] entry of the same name.
version="$(sed -n "s/^$tool = \"\\([0-9][^\"]*\\)\"$/\\1/p" "$test_dir/.prototools")"
if [[ -z "$version" ]]; then
    echo "error: test/.prototools pins no version for $tool" >&2
    exit 1
fi

# The command that prints each tool's version.
case "$tool" in
    fastly | pulumi) version_args=(version) ;;
    *) version_args=(--version) ;;
esac

cd "$test_dir"
proto install "$tool"
output="$(proto run "$tool" -- "${version_args[@]}" 2>&1)"
echo "$output"

if ! grep -qF "$version" <<<"$output"; then
    echo "error: $tool ${version_args[*]} does not report $version" >&2
    exit 1
fi
echo "ok: $tool $version"
