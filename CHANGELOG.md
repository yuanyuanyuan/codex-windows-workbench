# Changelog

## 0.1.2 - 2026-07-14

### Security

- Pass Release workflow version only via environment variables (no expression interpolation in `run:` scripts).
- Pin `actions/checkout` to a full commit SHA in CI and Release workflows.
- Add `.github/CODEOWNERS` for workflows, installer scripts, release tests, and release rules.
- Redact proxy credentials in `agent-env-doctor`, `Test-PwshAgentEnv`, and env-apply WhatIf output.
- Extend `Test-ReleaseGate.ps1` with high-signal secret and absolute personal-path content scanning.
- Document residual floating package-manager risk in install Impact summary.

## 0.1.1 - 2026-07-13

### Release governance

- Publish immutable tags and GitHub Releases only through the Release workflow.
- Require current-host, upgrade, Tier B, and redaction evidence before release.
- Pin and verify the Scoop bootstrap artifact before execution.
- Restrict documented install channels to `npx skills` and manual clone/copy.

## 0.1.0 - 2026-07-13

First public release of `stark-codex-windows-workbench`.

### Highlights

- Native Windows + PowerShell 7 Codex workbench skill
- Default path: Core + Agent only
- Multi-channel install: RedSkill, `npx skills add`, Codex Plugin CLI, manual clone/copy
- Direct invocation: `$stark-codex-windows-workbench`
- Safe preview first (`-WhatIf`), explicit Apply, Status/Verify/Rollback
- Human-readable install impact summary (`Summary` / `Impact`)
- Agent-executable install guide: `docs/install.md`

### Packaging

- Skill package layout under `skills/stark-codex-windows-workbench/`
- Prevents incomplete `npx skills` installs that only copy `SKILL.md`

### Quality gates

- Mandatory UAT regression suite:
  - `docs/uat/REGRESSION-RULES.md`
  - `docs/uat/cases/`
  - `tests/uat/Invoke-UatRegression.ps1`
- CI updated to test packaged skill scripts path and run Tier A regression

### Safety boundaries

- No WSL / bash / apt / brew
- No auth/login automation
- No MCP/secret writes
- Rollback restores managed settings only; does not uninstall packages
