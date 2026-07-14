# Release Rules

These rules govern every public release of `stark-codex-windows-workbench`. A release is blocked until every applicable gate passes. Do not create a tag or GitHub Release outside `.github/workflows/release.yml`.

## Supported Product Contract

- The supported host is native Windows 10 or 11. The Workbench runtime uses PowerShell 7 only.
- The Workbench runtime uses PowerShell 7 only. Before runtime execution, release documentation must state the PowerShell 7 and `winget`/App Installer prerequisites and direct a user with no `winget` to Microsoft's official App Installer path; it must not introduce a package manager beyond the reviewed `winget` and Scoop paths.
- The default workbench changes only Core and Agent after an explicit preview and consent. It must not automate authentication, write secrets, or use WSL, bash, apt, or brew.
- `npx skills` and manual clone/copy are the only supported installation channels until an additional channel has its own install, invocation, and uninstall UAT evidence.
- The product has no self-hosted telemetry. Shared logs, UAT evidence, and issue attachments must redact usernames, absolute paths, proxy endpoints, credentials, tokens, and machine identifiers.

## Supply Chain And Provenance

- Every externally downloaded executable script must be represented by a reviewable source version or commit and SHA-256 in the packaged integrity manifest. The runtime must verify the hash before execution.
- Release gate must fail on high-signal secrets, private-key blocks, basic-auth URLs, and absolute personal Windows user paths in package-facing files.
- GitHub Actions must pin third-party and first-party actions to full commit SHAs. Release workflow inputs must enter scripts only through environment variables, never via expression interpolation inside `run:` bodies.
- A public release must use an immutable `vX.Y.Z` tag. User-facing commands and release notes must point to that tag or its commit SHA, never `master` or another moving branch.
- `package.json`, `.codex-plugin/plugin.json`, the release tag, and the top `CHANGELOG.md` heading must carry the same version.
- `SECURITY.md` must remain present. Vulnerabilities are reported through GitHub private vulnerability reporting, never public issues.

## Required Automated Gates

The release workflow must pass all of the following with no `continue-on-error` behavior:

1. PowerShell syntax parsing for every packaged script.
2. `PSScriptAnalyzer` at Warning and Error severity.
3. `tests/release/Test-ReleaseGate.ps1` for the requested version.
4. A clean checkout must contain the Workbench entry script, the external-artifact integrity manifest, `SECURITY.md`, this rule file, and a versioned UAT evidence file.

GitHub Actions must run only CI-safe checks. Tier A and Tier B UAT, including package installation and any configuration validation, run on the current release-candidate host before dispatch and are recorded in the versioned release evidence.

## Required Human Evidence

Commit `docs/uat/results/vX.Y.Z-release-uat.md` before dispatching a release. It must identify the tested source commit and record PASS for:

- the current Windows 10 or 11 release-candidate host, including OS version, PowerShell version, and the starting managed-state summary;
- PowerShell 7 and `winget`/App Installer prerequisite guidance;
- default `-WhatIf`, consented Apply, `-Verify`, and managed-configuration `-Rollback`;
- installation through `npx skills` and manual clone/copy;
- an in-place upgrade from the immediately preceding release, including the migration preview, renewed consent, and rollback backup;
- redaction review of the attached evidence.

The evidence must name the OS version, PowerShell version, test date, tested source commit SHA, commands, observed result, starting managed-state summary, and any elevation. The tested source commit must be an ancestor of the release commit. It must state `Fresh-machine coverage: NOT RUN` unless that test was actually performed. Do not commit raw machine logs.

## Release Procedure

1. Implement and review the release changes, then update the version and changelog.
2. Run Tier A locally. Run Tier B locally after packaging or installation changes.
3. Run the required current-host and upgrade UATs, then commit the sanitized versioned evidence. Record any untested fresh-machine coverage as a limitation.
4. Dispatch `Release` from `master` with the numeric version. The workflow validates all gates, creates `vX.Y.Z`, and creates the GitHub Release from that tag.
5. Verify the published release links only to immutable sources and contains supported channels, consent boundaries, rollback limitation, privacy boundary, and security-reporting link.

## Stop Conditions

Stop and fix the release when a required gate fails, the evidence is missing or stale, the tested source commit is not an ancestor of the release commit, current-host or upgrade validation is absent, any external executable is unpinned, a supported install channel lacks end-to-end proof, or the release would change managed state without renewed consent.
