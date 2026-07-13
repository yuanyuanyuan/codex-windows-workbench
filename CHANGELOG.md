# Changelog

## 0.1.0 - 2026-07-13

First public release of `stark-codex-windows-workbench`.

### Highlights

- Native Windows + PowerShell 7 Codex workbench skill
- Default path: Core + Agent only
- Multi-channel install: RedSkill, `npx skills add`, Codex Plugin CLI, manual clone/copy
- Direct invocation: `$stark-codex-windows-workbench` (Codex) or `/stark-codex-windows-workbench` (Claude Code)
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
