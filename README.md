# Windows PowerShell 7 Codex Workbench

> Chinese README: [README.zh-CN.md](./README.zh-CN.md)

Native Windows PowerShell 7 workbench bootstrap for Codex/AI agents.

This repository prepares a **repeatable, inspectable, reversible** developer shell for AI agents on Windows — without WSL, bash, apt, or brew.

## What it does

Default path installs only:

- **Core** — common runtimes and CLI tools (Git, Node/fnm path readiness, Python/uv, Docker CLI, small Scoop CLIs, etc.)
- **Agent** — PowerShell profile overlay, managed agent directories, PATH/encoding/proxy policy

After a successful default apply, smoke verification runs automatically. Explicit `-Verify` remains available later.

Optional workloads are explicit opt-in:

| Switch | Purpose |
|---|---|
| `-Developer` | Go/.NET/build helpers/DevOps CLIs |
| `-NativeBuild` | VS Build Tools / MSVC / Windows SDK |
| `-Containers` | Docker Desktop (client/server reported separately) |
| `-AgentClients` | Agent CLI verify/install (public MVP: **Codex only**) |
| `-EnableSafetyHooks` | Dangerous-git safety hook |
| `-Full` | All defined workloads |

## Non-goals

- Not Windows PowerShell 5.1
- Not WSL / Linux package managers
- No automatic Codex/Claude login
- No silent remote MCP / marketplace plugin install
- No package uninstall on rollback
- Public MVP does **not** expand to multi-agent client marketing surface

## Requirements

- Native Windows
- PowerShell 7+
- `winget` available for package configuration/install paths

## Quick start

```powershell
# Preview (no machine changes)
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json

# Apply Core + Agent (default), then auto smoke-verify
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1

# Later diagnosis
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
```

Optional:

```powershell
.\scripts\Initialize-PwshAgentWindows.ps1 -Developer
.\scripts\Initialize-PwshAgentWindows.ps1 -NativeBuild
.\scripts\Initialize-PwshAgentWindows.ps1 -Containers
.\scripts\Initialize-PwshAgentWindows.ps1 -AgentClients
.\scripts\Initialize-PwshAgentWindows.ps1 -EnableSafetyHooks
.\scripts\Initialize-PwshAgentWindows.ps1 -Full
.\scripts\Initialize-PwshAgentWindows.ps1 -Rollback
```

Preflight only:

```powershell
.\scripts\Preflight-PwshAgentWindows.ps1 -Json
```

## Safety model

- Additive profile changes with backup before managed overwrites
- PATH updates use exact-entry match + dedupe
- AgentClients never writes tokens, MCP endpoints, or permission grants
- Rollback restores only managed files/registry values after ownership/hash checks
- Packages stay installed unless the user uninstalls them separately
- Secrets and machine-local proxy endpoints do not belong in this repo

## Repository layout

```text
scripts/                     # public entrypoints + tests
scripts/Private/             # phase/state helpers
config/                      # winget docs, overlay, agent content
docs/                        # design notes and operator docs
SKILL.md                     # Codex skill packaging entry
.github/workflows/           # CI (no real machine installs)
```

## Tests and CI

Local contract tests:

```powershell
$env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT = '1'
pwsh -NoLogo -NoProfile -File .\scripts\Test-InitializePwshAgentWindows.ps1
pwsh -NoLogo -NoProfile -File .\scripts\Test-AgentClients.ps1
pwsh -NoLogo -NoProfile -File .\scripts\Test-PwshAgentEnv.ps1 -Json
```

CI runs parser checks, contract tests, and WhatIf assertions. It intentionally does **not** perform real `winget install` / `scoop install` / Docker daemon setup.

## Docs

- Operator guide: [docs/windows-agent-env.md](./docs/windows-agent-env.md)
- Design notes under `docs/superpowers/`
- Domain language: [CONTEXT.md](./CONTEXT.md)

## Versioning

This repository publishes a **Codex Workbench MVP**.
Treat heavy workloads (NativeBuild/Containers) as explicit capabilities, not default claims.

## License

MIT — see [LICENSE](./LICENSE).
