# UAT Regression

This directory defines the **mandatory post-change UAT regression gate** for `stark-codex-windows-workbench`.

## Why this exists

A previous false-pass happened because UAT only checked:

1. skill discovery
2. source-tree WhatIf

It did **not** hard-check the **installed skill product tree**. That allowed a packaging bug to ship:

- root-level `SKILL.md` caused `npx skills add` to install only `SKILL.md`
- scripts/config were missing from the installed skill directory

Regression UAT exists to prevent that class of miss forever.

## Contents

| Path | Purpose |
|------|---------|
| [REGRESSION-RULES.md](./REGRESSION-RULES.md) | Rules: when to run, required gates, pass/fail policy |
| [cases/](./cases/) | Human-readable case catalog (UAT-xxx) |
| [results/TEMPLATE.md](./results/TEMPLATE.md) | Result report template |
| [../../tests/uat/Invoke-UatRegression.ps1](../../tests/uat/Invoke-UatRegression.ps1) | Executable regression runner |

## How to run

From repo root on Windows + PowerShell 7:

```powershell
# Required local/CI gate (no real package install, no secrets)
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1

# JSON report
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1 -Json

# Include network install probe when publishing or validating remote packaging
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1 -IncludeNetwork
```

Exit code:

- `0` = all selected cases passed
- non-zero = regression blocked

## Required after every update

Run at least the default suite after changes to:

- `skills/stark-codex-windows-workbench/**`
- packaging / plugin manifests
- install docs (`docs/install.md`, README install sections)
- workbench scripts / summary reporting
- CI workflow

See [REGRESSION-RULES.md](./REGRESSION-RULES.md) for the full policy.
