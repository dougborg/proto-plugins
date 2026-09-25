# proto-plugins

[proto](https://moonrepo.dev/proto) [TOML plugins](https://moonrepo.dev/docs/proto/non-wasm-plugin) for tools that proto does not cover itself.
Each plugin installs the upstream project's own release for macOS and Linux, on x64 and arm64.

## Plugins

| Plugin | Tool | Executables | Download verified by |
| --- | --- | --- | --- |
| [`sops`](plugins/sops.toml) | [sops](https://github.com/getsops/sops), the editor for encrypted files | `sops` | the release's `sops-v{version}.checksums.txt` |
| [`pulumi`](plugins/pulumi.toml) | the [Pulumi](https://github.com/pulumi/pulumi) CLI | `pulumi`, with its language hosts on `PATH` | the release's `pulumi-{version}-checksums.txt` |
| [`shellcheck`](plugins/shellcheck.toml) | [ShellCheck](https://github.com/koalaman/shellcheck), the shell script linter | `shellcheck` | proto's lockfile only |
| [`shfmt`](plugins/shfmt.toml) | [shfmt](https://github.com/mvdan/sh), the shell formatter | `shfmt` | proto's lockfile only |
| [`bats`](plugins/bats.toml) | [Bats](https://github.com/bats-core/bats-core), the Bash testing system, from the tag's source archive | `bats` | proto's lockfile only |
| [`age`](plugins/age.toml) | [age](https://github.com/FiloSottile/age), the file encryption tool | `age`, `age-keygen` | proto's lockfile only |
| [`fastly`](plugins/fastly.toml) | the [Fastly CLI](https://github.com/fastly/cli) | `fastly` | the release's `fastly_v{version}_SHA256SUMS` |

Every plugin resolves versions from the upstream repository's Git tags, so `proto versions <tool>` and version ranges work.
Windows is not supported.

## Using a plugin

Reference each plugin by a release tag of this repository under `[plugins.tools]` in `.prototools`, and pin the tool's version beside it:

```toml
sops = "3.13.3"

[plugins.tools]
sops = "https://raw.githubusercontent.com/dougborg/proto-plugins/v0.1.0/plugins/sops.toml"
```

Then `proto install sops` installs that version.
Always use a tag, never `main`: a tag is immutable, while `main` can change under you between installs.

Where upstream publishes no checksum file, proto can only record the hash of the first download.
Turn on proto's lockfile so that every later install is checked against it, and commit `.protolock`:

```toml
[settings]
lockfile = true
```

## Keeping versions current with Renovate

Renovate's built-in `proto` manager knows only proto's own tools, so it cannot bump these.
Put a comment naming the upstream release above each pin:

```toml
# renovate: datasource=github-releases depName=getsops/sops
sops = "3.13.3"
```

| Plugin | `depName` |
| --- | --- |
| `sops` | `getsops/sops` |
| `pulumi` | `pulumi/pulumi` |
| `shellcheck` | `koalaman/shellcheck` |
| `shfmt` | `mvdan/sh` |
| `bats` | `bats-core/bats-core` |
| `age` | `FiloSottile/age` |
| `fastly` | `fastly/cli` |

Then add a regex manager that reads those comments to `renovate.json`, and a second one for the tag in the plugin URLs:

```json
{
  "customManagers": [
    {
      "customType": "regex",
      "managerFilePatterns": ["/(^|/)\\.prototools$/"],
      "matchStrings": [
        "#\\s*renovate:\\s*datasource=(?<datasource>\\S+)\\s+depName=(?<depName>\\S+)\\s*\\n\\s*[\\w-]+\\s*=\\s*\"(?<currentValue>[^\"]+)\""
      ],
      "extractVersionTemplate": "^v?(?<version>.+)$"
    },
    {
      "customType": "regex",
      "managerFilePatterns": ["/(^|/)\\.prototools$/"],
      "matchStrings": [
        "https://raw\\.githubusercontent\\.com/(?<depName>dougborg/proto-plugins)/(?<currentValue>v[^/]+)/"
      ],
      "datasourceTemplate": "github-tags"
    }
  ]
}
```

This repository's own [`renovate.json`](renovate.json) uses the first form to keep the versions CI tests current.

## Development

[`test/.prototools`](test/.prototools) pins the version of each tool that CI installs, and references each plugin through a local `file://` path.
Check a plugin on your own machine with proto installed:

```sh
scripts/check-plugin.sh sops
```

It installs the pinned version through the plugin in this checkout and fails unless the installed tool reports that version.
CI runs it for every plugin on Linux x64, Linux arm64 and macOS arm64, and lints the workflows with actionlint and the script with the repository's own `shellcheck` and `shfmt` plugins.

A new plugin needs a `plugins/<tool>.toml`, a pinned version with its Renovate comment in `test/.prototools`, and a row in each table above.
Use the release's checksum file whenever upstream publishes one.

## Releases

[release-please](https://github.com/googleapis/release-please) keeps a release pull request open on `main` from the Conventional Commits merged there.
Merging it tags the release as `v<version>`, starting at `v0.1.0`, and creates the GitHub Release.
It needs the `dougborg-release-please` App: the `RELEASE_PLEASE_APP_ID` variable and the `RELEASE_PLEASE_APP_PRIVATE_KEY` secret.

Listing these plugins in [proto's third-party registry](https://moonrepo.dev/docs/proto/tools#unofficial-third-party) is planned for later, so that `proto plugin search` can find them.

## License

[MIT](LICENSE).
