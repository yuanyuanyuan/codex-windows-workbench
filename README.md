# Stark Codex Windows Workbench

> Chinese README: [README.zh-CN.md](./README.zh-CN.md)

**Skill:** `stark-codex-windows-workbench`

A direct entry point for Codex to safely preflight, preview, apply, verify, and roll back a managed workbench on **native Windows + PowerShell 7**.  
Default path: **Core + Agent**. No WSL. No auto-login. No secret writes.

## What This Skill Is For

`stark-codex-windows-workbench` is a **native Windows PowerShell 7 workbench skill** for Codex.

It is used to:

1. Install the skill itself
2. Preflight whether the host can run
3. Preview what Core + Agent will change with `-WhatIf`
4. Explicitly Apply a minimal managed baseline
5. Verify / inspect status
6. Roll back managed settings only

In one sentence: give the agent a repeatable, previewable, rollback-friendly Windows workbench instead of a pile of ad-hoc scripts.

## What Problem It Solves

Turning Codex into an engineering-ready state on native Windows usually hits these pain points:

- Agents drift into WSL / bash / `apt` and mess up the Windows host
- Install paths are scattered across winget, scoop, PATH, Profile, and temporary scripts
- There is no safe preview of impact before packages are installed
- Re-runs are unstable, and recovery is unclear when something breaks
- Install docs mix login/secret steps and tempt agents into over-automation

This skill collapses those problems into one direct invocation path and hardens the boundaries:

- Native Windows + PowerShell 7 only
- Preview first, Apply only after confirmation
- Default path is Core + Agent only
- Never auto-login, never write MCP/secrets
- Rollback restores managed settings only; it does not uninstall packages

## Why Use It

| If you currently... | This skill helps you... |
|---|---|
| Bootstrap with chat prompts and scattered scripts | Call one skill for preflight / preview / apply / verify |
| Install first and discover impact later | Preview with `-WhatIf`, then Apply after confirmation |
| Still get pulled into WSL/bash on Windows | Stay on a fixed native Windows + PowerShell 7 path |
| Keep inconsistent machine baselines | Use a managed Core + Agent default |
| Recover by guessing uninstall steps | Roll back managed settings with fixed uninstall steps |

## User Scenario Comparison

| | Before | After |
|---|---|---|
| Entry | Many ad-hoc scripts and chat instructions | Call `$stark-codex-windows-workbench` |
| Host model | WSL/bash leakage, mixed shells | Native Windows + PowerShell 7 only |
| Change safety | Install first, discover impact later | `-WhatIf` preview, then explicit Apply |
| Baseline | Machine-specific tool soup | Managed Core + Agent default |
| Secrets | Bootstrap docs tempt token/login automation | Never auto-login; never write MCP/secrets |
| Recovery | Uninstall guesswork | Rollback managed settings only |
| Repeatability | "Works on my machine" | Idempotent phases + status/verify |

### Typical flow after you call it

```text
call skill
  -> Preflight
  -> WhatIf preview
  -> you confirm
  -> Apply Core + Agent
  -> smoke verify
  -> Status / Verify / Rollback on request
```

## Install

### One-line for agents

```text
Install stark-codex-windows-workbench for me using the installation guide for release v0.1.2: https://github.com/yuanyuanyuan/stark-codex-windows-workbench/blob/v0.1.2/docs/install.md
```

Full agent install guide: [docs/install.md](./docs/install.md)

### npx (Recommended)

```bash
npx skills add yuanyuanyuan/stark-codex-windows-workbench
```

### Manual (Git Clone)

`npx skills` installs the skill folder under `skills/stark-codex-windows-workbench/` (not the whole repo root).

```powershell
git clone --depth 1 --branch v0.1.2 https://github.com/yuanyuanyuan/stark-codex-windows-workbench.git $env:TEMP\stark-codex-windows-workbench
Copy-Item -Recurse -Force $env:TEMP\stark-codex-windows-workbench\skills\stark-codex-windows-workbench $env:USERPROFILE\.codex\skills\stark-codex-windows-workbench
```

## Use

```text
$stark-codex-windows-workbench
```

Default behavior after invoke:

- audit / preflight
- preview with `-WhatIf`
- apply **Core + Agent** only after confirm
- verify / status
- rollback managed settings only

Optional workloads (explicit only):

- `-Developer`
- `-NativeBuild`
- `-Containers`
- `-AgentClients` (Codex presence/version probe only; does **not** install or login)
- `-EnableSafetyHooks`
- `-Full`

## Uninstall

Uninstall removes the skill package from agent skill directories.  
It does **not** uninstall winget/scoop packages installed by Apply.

### 1) Optional: rollback managed workbench settings first

```powershell
pwsh -NoLogo -NoProfile -File "$env:USERPROFILE\.agents\skills\stark-codex-windows-workbench\scripts\Initialize-PwshAgentWindows.ps1" -Rollback -Confirm:$false -Json
```

### 2) Remove skill directories

```powershell
$paths = @(
  "$env:USERPROFILE\.agents\skills\stark-codex-windows-workbench"
  "$env:USERPROFILE\.codex\skills\stark-codex-windows-workbench"
  # legacy names from earlier renames
  "$env:USERPROFILE\.agents\skills\codex-windows-workbench"
  "$env:USERPROFILE\.agents\skills\windows-pwsh-agent-workbench"
  "$env:USERPROFILE\.codex\skills\codex-windows-workbench"
)
$paths | Where-Object { Test-Path $_ } | ForEach-Object {
  Remove-Item -LiteralPath $_ -Recurse -Force
  Write-Host "Removed $_"
}
```

### What uninstall does not do

- Does not uninstall packages installed by Core (`winget` / `scoop`)
- Does not delete your unrelated PowerShell profile content
- Does not log out of Codex

## Execution Effects

| Step | What runs | Machine effect | What you see |
|------|-----------|----------------|--------------|
| 2. Preflight | `Preflight-PwshAgentWindows.ps1 -Json` | Read-only checks | Host/tool blockers and warnings |
| 3. Preview | `Initialize-...ps1 -WhatIf -Json` | **No changes** (`Changed=false`) | `Selected`, `Phases`, `Actions`, `SafetyHooks` |
| 4. Confirm | Agent asks you | No changes | Clear Core + Agent impact summary |
| 5. Apply | `Initialize-...ps1 -Confirm:$false -Json` | Installs baseline tools + managed overlay | Phase results + smoke verification |
| 6. Verify/Status | `-Verify` / `-Status` | Read-only | Pass/fail and phase completeness |
| 7. Rollback | `-Rollback -Confirm:$false` | Restores managed settings only | Packages stay installed |

### Default Apply effects (Core + Agent)

**Core**

- winget-configure baseline packages from `config/windows-agent-core.winget`
- bootstrap scoop if needed
- install common CLI tools: `ripgrep fd fzf jq bat delta yq 7zip zip nuget`
- some packages may require elevation

**Agent**

- write managed PowerShell overlay under `%USERPROFILE%\.config\pwsh-ai`
- create managed agent directories
- record managed state under `%LOCALAPPDATA%\PwshAiAgent\state`

**Never happens by default**

- no WSL / bash / apt / brew
- no Codex auto-login
- no secret / MCP credential writes
- no Developer / NativeBuild / Containers unless requested
- no package uninstall on rollback

## Complete Installation and Configuration Inventory

The tables below are the complete inventory for the current initializer. Items marked **default** run with Core + Agent; items marked **optional** run only when their switch (or `-Full`) is selected. Existing packages are skipped where the underlying package manager reports them as installed.

### Default: Core packages

| Manager | Package / ID | Purpose |
|---|---|---|
| winget configure | `Microsoft.PowerShell` | PowerShell 7 |
| winget configure | `Git.Git` | Git for Windows |
| winget configure | `GitHub.cli` | GitHub CLI (`gh`) |
| winget configure | `Microsoft.WindowsTerminal` | Windows Terminal |
| winget configure | `Microsoft.VisualStudioCode` | Visual Studio Code |
| winget configure | `Microsoft.VCRedist.2015+.x64` | VC++ runtime required by native tools and WinGet configuration |
| winget configure | `OpenJS.NodeJS.LTS` | Node.js LTS for agent CLIs and JavaScript projects |
| winget configure | `Python.Python.3.13` | Python 3.13 |
| winget configure | `astral-sh.uv` | Python package and environment manager |
| winget configure | `Docker.DockerCLI` | Docker client only; no backend is configured |
| winget configure | `Kubernetes.kubectl` | Kubernetes CLI |
| Scoop (bootstrap if missing) | Scoop | User-level package manager for small CLI tools |
| Scoop | `ripgrep`, `fd`, `fzf` | Search, file discovery, and interactive filtering |
| Scoop | `jq`, `yq` | JSON and YAML processing |
| Scoop | `bat`, `delta` | File viewing and Git diffs |
| Scoop | `7zip`, `zip`, `nuget` | Archives and NuGet CLI |

### Default: Agent configuration

| Category | Item | Effect |
|---|---|---|
| Managed files | `%USERPROFILE%\.config\pwsh-ai\pwsh-ai-agent-overlay.ps1` | Installs the PowerShell runtime overlay. |
| Managed files | `%USERPROFILE%\.config\pwsh-ai\pwsh-ai-core.ps1` | Creates or extends the managed core-profile loader; an existing file is backed up before the loader is appended. |
| Managed directories | `hooks`, `mcp`, `skills`, `commands`, `rules`, `agents` below `%USERPROFILE%\.config\pwsh-ai` | Creates empty managed locations for future local configuration; it does not install plugins, MCP servers, or credentials. |
| Managed state | `%LOCALAPPDATA%\PwshAiAgent\state` | Records backups, hashes, and phase-completion state so managed settings can be rolled back safely. |
| User environment | `GOPATH`, `GOPROXY`, `GOSUMDB` | Sets `%USERPROFILE%\go`, `https://proxy.golang.org,direct`, and `sum.golang.org`. |
| User environment | `PYTHONIOENCODING`, `PYTHONUTF8`, `NO_PROXY` | Sets UTF-8 Python output and `localhost,127.0.0.1,::1`. |
| Process overlay | Output encoding and PowerShell preferences | Uses UTF-8, plain output rendering, and suppressed progress for machine-readable agent subprocess output. |
| Process overlay | PATH ordering | Adds existing Go, Scoop, WinGet Links, Codex, `.local\bin`, pnpm, and Python Scripts locations without duplicate entries. |
| Process overlay | Proxy policy | Preserves existing `HTTP_PROXY`, `HTTPS_PROXY`, and `ALL_PROXY`; an optional local private overlay may supply machine-specific values. |

The agent configuration never creates an auth token, MCP endpoint, or permission grant. It also does not install Codex: `-AgentClients` only probes the existing `codex` command and its version.

### Optional workloads and configuration

| Switch | Installs or configures |
|---|---|
| `-Developer` | winget: `GoLang.Go`, `Microsoft.DotNet.SDK.10`, `Kitware.CMake`, `Ninja-build.Ninja`, `Helm.Helm`, `Hashicorp.Terraform`; Scoop: `golangci-lint`, `air`; Go: `gopls`, `dlv`, `air`; current-user PowerShell modules: `Pester`, `PSScriptAnalyzer`, `Microsoft.PowerShell.PSResourceGet`. |
| `-NativeBuild` | `Microsoft.VisualStudio.2022.BuildTools` with the MSVC and Windows SDK workloads, plus `Microsoft.VisualStudio.Locator` (`vswhere`). |
| `-Containers` | `Docker.DockerDesktop`, then probes Docker client/server availability. It does not choose a Docker backend or configure WSL. |
| `-AgentClients` | Probes the public Codex CLI location and `codex --version`; no installation, login, auth, MCP, or permission write. |
| `-EnableSafetyHooks` | Copies `%USERPROFILE%\.config\pwsh-ai\hooks\dangerous-git.ps1`, which guards force-push, hard-reset, aggressive-clean, forced-checkout, amend, and interactive-rebase commands. |
| `-Full` | Selects every optional workload above and enables the safety hook. |

Rollback restores only the managed files and user environment values recorded in state. It deliberately leaves installed packages in place.

### Example preview output

```json
{
  "Mode": "WhatIf",
  "Changed": false,
  "Selected": ["Core", "Agent"],
  "Phases": [
    { "Name": "Core", "Status": "Planned" },
    { "Name": "Agent", "Status": "Planned" },
    { "Name": "Developer", "Status": "NotSelected" }
  ],
  "SafetyHooks": false
}
```

Preview/apply reports now include human-readable `Summary` and structured `Impact` so you can see packages, managed files, and non-actions without decoding raw JSON.

How to read it:

- trust `Selected` + `Actions`
- `Planned` means it will run
- `NotSelected` means it will not run
- `Changed=false` means preview did not modify the machine

## Constraints

- Windows + PowerShell 7+ only
- No Windows PowerShell 5.1
- No WSL / bash / apt / brew
- No auth login automation
- No secret / MCP credential writes
- Rollback does not uninstall packages
- Apply requires `winget`
- Non-interactive Apply/Rollback should use `-Confirm:$false`

## UAT Evidence

After every update, run the mandatory regression suite:

```powershell
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1
```

- Rules: [docs/uat/REGRESSION-RULES.md](./docs/uat/REGRESSION-RULES.md)
- Cases: [docs/uat/cases/](./docs/uat/cases/)
- This gate checks **installed skill product completeness**, not only source-tree discovery/WhatIf.

Real install + configure notes live here:

- [docs/uat-real-install-configure.md](./docs/uat-real-install-configure.md)

Observed on a native Windows host:

- skill discoverable via `npx skills add ... --list`
- skill install lands under `%USERPROFILE%\.agents\skills\stark-codex-windows-workbench`
- `-WhatIf -Json` returns `Changed=false` with `Selected=["Core","Agent"]`
- full package Apply is gated behind explicit user confirmation

One-command agent replay:

```text
Install stark-codex-windows-workbench using docs/install.md. First install the skill with npx, then run -WhatIf -Json to preview Core+Agent, report Selected/Actions for confirmation, and only after I confirm run -Confirm:$false Apply, then -Status/-Verify.
```

## Package

```text
skills/stark-codex-windows-workbench/
  SKILL.md
  agents/openai.yaml
  scripts/
  config/
  references/
.codex-plugin/plugin.json
package.json
docs/
```

## License

MIT — see [LICENSE](./LICENSE).

