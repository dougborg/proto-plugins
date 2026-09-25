# Security policy

## Supported versions

Only the latest release receives fixes.
Each plugin is a TOML file that a `.prototools` file references by release tag, so a fix reaches you when you move your reference to the new tag.

## Reporting a vulnerability

Report vulnerabilities privately through [GitHub's private vulnerability reporting](https://github.com/dougborg/proto-plugins/security/advisories/new), not in a public issue.
Include the affected plugin, a description of the problem, and steps to reproduce it.
A plugin that downloads from the wrong place, or skips a checksum its upstream publishes, counts.
You should get an acknowledgement within a week.
Fixes land on `main` and ship in the next release, and the advisory is published once that release is out.
