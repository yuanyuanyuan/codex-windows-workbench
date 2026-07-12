# windows-pwsh-agent-workbench

> 中文说明：[README.zh-CN.md](./README.zh-CN.md)

A **Codex Skill** for maintaining a native Windows PowerShell 7 workbench for Codex.

This repository is the **Workbench Source Repository**: it publishes the skill package plus the runtime scripts/config that the skill drives. It is **not** a generic “Windows installer project,” and it is **not** a personal dotfiles dump.

## What this skill is

**Skill name:** `windows-pwsh-agent-workbench`

**One-line job:** help Codex set up, audit, verify, and safely maintain a native Windows PowerShell 7 engineering workbench — without WSL.

When a user asks Codex things like:

- “帮我初始化 Windows AI agent 环境”
- “check my Windows PowerShell workbench”
- “prepare a Codex-ready Windows shell”
- “verify Node/Git/Codex paths on Windows”
- “rollback workbench-managed profile changes”

…this skill should be used.

## What the skill does

The skill routes and executes workbench operations:

1. **Audit / Preflight** — host checks, plan inspection, declarative validation
2. **Preview** — show what would change (`-WhatIf`) without mutating the machine
3. **Apply** — install/maintain the selected workbench path
4. **Verify / Status** — machine-readable health and phase status
5. **Rollback** — restore only workbench-managed files/settings
6. **Safety boundary** — refuse Windows PowerShell 5.1, WSL, bash, apt, brew

Default workload is **Codex Base (Core + Agent)** only. Heavier capabilities are optional and explicit.

| Workload | Selected by | Meaning |
|---|---|---|
| Core + Agent (default) | no extra flags | Codex-ready shell, runtimes, profile overlay |
| Developer | `-Developer` | Go/.NET/build helpers/DevOps CLIs |
| NativeBuild | `-NativeBuild` | VS Build Tools / MSVC / Windows SDK |
| Containers | `-Containers` | Docker Desktop (client/server reported separately) |
| AgentClients | `-AgentClients` | Agent CLI path (public MVP: **Codex only**) |
| Safety hooks | `-EnableSafetyHooks` | opt-in dangerous-git protection |
| Full | `-Full` | all defined optional workloads |

## What this skill is not

- Not a multi-agent marketplace installer
- Not an auth/login automation tool
- Not an MCP credential migrator
- Not a WSL/Linux bootstrap
- Not “silently make my whole PC into a full dev machine”

Public MVP supports **Codex only**.

## Install the skill

### Option A — use this repo as a skill root

Clone the repository, then point Codex / skill installer at the repo root (the directory that contains `SKILL.md`):

```powershell
git clone https://github.com/yuanyuanyuan/windows-pwsh-agent-workbench.git
```

Skill package entrypoints:

- [`SKILL.md`](./SKILL.md) — skill instructions (`name` + `description` frontmatter)
- [`agents/openai.yaml`](./agents/openai.yaml) — Codex agent interface metadata
- [`scripts/`](./scripts/) — deterministic automation the skill invokes
- [`references/`](./references/) — detailed contracts loaded on demand

### Option B — already in a Codex skills directory

If this repo is installed under your Codex skills path, invoke it by skill name:

```text
windows-pwsh-agent-workbench
```

or by natural-language task that matches the skill description.

## How users should talk to the skill

Good prompts:

- “Use the Windows PowerShell Codex workbench skill to preview the default setup.”
- “Audit my current Windows workbench and report missing required tools.”
- “Apply Core + Agent only, then verify.”
- “Enable safety hooks and show what files would change.”
- “Rollback only managed workbench settings.”

The skill should prefer:

```powershell
# preview
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json

# apply default Codex Base
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1

# verify / status / rollback
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Rollback
```

Preflight:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Preflight-PwshAgentWindows.ps1 -Json
```

## Host constraints

- Supported host: **native Windows + PowerShell 7+**
- Rejected: Windows PowerShell 5.1, WSL, bash, sh, apt, brew
- Package installs and machine changes happen only through explicit workbench runs
- CI and contract tests intentionally avoid real machine installation

## Safety model

- Additive profile changes; backup before managed overwrite
- PATH uses exact-entry match + dedupe
- AgentClients never writes tokens, MCP endpoints, or permission grants
- Rollback restores managed files/settings only after ownership/hash checks
- Packages are never uninstalled by rollback
- No usernames, absolute personal paths, proxy secrets, or auth state belong in this public repo

## Repository layout

```text
SKILL.md                 # skill entry (this package root)
agents/openai.yaml       # Codex skill interface metadata
scripts/                 # skill runtime automation + contract tests
scripts/Private/         # phase/state helpers
config/                  # winget docs, overlay, agent content pack
references/              # progressive-disclosure contracts
docs/                    # design and operator notes
.github/workflows/       # skill package CI (no real installs)
```

## Tests

Contract tests for the skill runtime:

```powershell
$env:PWSH_AI_AGENT_SKIP_WINGET_PREFLIGHT = '1'
pwsh -NoLogo -NoProfile -File .\scripts\Test-InitializePwshAgentWindows.ps1
pwsh -NoLogo -NoProfile -File .\scripts\Test-AgentClients.ps1
```

## Docs

- Domain language: [CONTEXT.md](./CONTEXT.md)
- Operator notes: [docs/windows-agent-env.md](./docs/windows-agent-env.md)
- Skill design: [docs/superpowers/specs/2026-07-12-public-codex-workbench-skill-design.md](./docs/superpowers/specs/2026-07-12-public-codex-workbench-skill-design.md)

## Version

Current public release: **Codex Workbench MVP (`v0.1.0`)**.

## License

MIT — see [LICENSE](./LICENSE).
