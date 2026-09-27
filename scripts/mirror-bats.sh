#!/usr/bin/env bash
# Mirror bats-core's source archive for each version as a release file of this
# repository, so plugins/bats.toml can download a release file instead of
# GitHub's generated archive.
#
#   scripts/mirror-bats.sh 1.14.0 [1.13.0 ...]
#
# bats publishes no release files, only the tag's source archive, and some
# networks serve release files but refuse archive links (Claude Code cloud
# sessions do, for any repository not attached to the session).
#
# The mirrored file must be byte-for-byte GitHub's archive, or every
# consumer's .protolock checksum breaks. So each version is fetched twice,
# independently: GitHub's archive link, and `git archive` of the tag rebuilt
# here. Only when the two agree is anything published. A tag that upstream
# moves changes both, which is why consumers still need proto's lockfile.
#
# Each version goes to its own release, tagged bats-v{version}, with the file
# named as the plugin expects: bats-core-{version}.tar.gz. A version already
# mirrored is left alone.
#
# DRY_RUN=1 does everything except publish. Needs gh, git, curl and GH_TOKEN.
set -euo pipefail

upstream="bats-core/bats-core"
repo="${GITHUB_REPOSITORY:?set GITHUB_REPOSITORY to owner/name}"
dry_run="${DRY_RUN:-0}"

if (($# == 0)); then
    echo "usage: scripts/mirror-bats.sh <version>..." >&2
    exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

sha256() {
    if command -v sha256sum >/dev/null; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

for version in "$@"; do
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "error: '$version' is not a bats version like 1.14.0" >&2
        exit 1
    fi
    tag="bats-v$version"
    file="bats-core-$version.tar.gz"

    if assets="$(gh release view "$tag" --repo "$repo" --json assets --jq '.assets[].name' 2>/dev/null)"; then
        if grep -qxF "$file" <<<"$assets"; then
            echo "ok: $tag already holds $file"
            continue
        fi
        release_exists=1
    else
        release_exists=0
    fi

    dir="$work/$version"
    mkdir -p "$dir"
    curl -fsSL -o "$dir/$file" \
        "https://github.com/$upstream/archive/refs/tags/v$version.tar.gz"
    git clone --quiet --depth 1 --branch "v$version" \
        "https://github.com/$upstream" "$dir/src" 2>/dev/null
    git -C "$dir/src" archive --format=tar --prefix="bats-core-$version/" "v$version" |
        gzip -n >"$dir/rebuilt.tar.gz"

    downloaded="$(sha256 "$dir/$file")"
    rebuilt="$(sha256 "$dir/rebuilt.tar.gz")"
    if [[ "$downloaded" != "$rebuilt" ]]; then
        echo "error: bats $version: GitHub's archive ($downloaded) differs from git archive of the tag ($rebuilt)" >&2
        exit 1
    fi
    echo "bats $version: GitHub's archive matches git archive of the tag, sha256:$downloaded"

    notes="Mirror of https://github.com/$upstream/archive/refs/tags/v$version.tar.gz for plugins/bats.toml.

sha256:$downloaded, identical to \`git archive --format=tar --prefix=bats-core-$version/ v$version | gzip -n\` of the upstream tag."

    if [[ "$dry_run" == 1 ]]; then
        echo "dry run: would publish $file to $tag"
    elif ((release_exists)); then
        gh release upload "$tag" "$dir/$file" --repo "$repo"
        echo "ok: uploaded $file to the existing $tag"
    else
        # --latest=false keeps release-please's v* release as the latest one.
        gh release create "$tag" "$dir/$file" --repo "$repo" --latest=false \
            --title "bats $version (mirror)" --notes "$notes"
        echo "ok: published $file as $tag"
    fi
done
