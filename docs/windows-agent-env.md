# Windows PowerShell Agent Environment

## Goal

Make this Windows PowerShell environment behave like a strong macOS/Linux software-engineering workstation plus Windows-native administration tools for Codex/AI agents.

WSL is explicitly out of scope. This project targets native Windows PowerShell.

## Baseline

Required runtime tools:

- Shell/system: `pwsh`, `winget`, `scoop`, `curl`, `ssh`
- Code navigation: `git`, `git-lfs`, `gh`, `rg`, `fd`, `fzf`
- Text/data: `jq`, `bat`, `delta`
- JS/TS: `node`, `npm`, `pnpm`, `corepack`
- Python: `python`, `uv`, `pip`
- Containers: `docker`, `kubectl`
- Windows admin: `reg`, `schtasks`, `robocopy`, `tasklist`, `taskkill`, `Get-NetTCPConnection`

Recommended additions:

- Go: `go`, `gofmt`, `gopls`, `dlv`, `golangci-lint`, `air`
- Native builds: `cmake`, `ninja`, Visual Studio Build Tools / MSVC / Windows SDK
- CLI parity: `yq`, `zip`, `nuget`; use `robocopy` or `rclone` for rsync-style workflows
- DevOps: `helm`, `terraform`

## Package Manager Policy

- Use `winget` / `winget configure` for Windows applications, SDKs, and large tools.
- Use `scoop` for small developer CLI tools.
- Keep `choco` available for compatibility, but do not expand it as the default source.
- Use `go install` for Go-native tools when that is the official path.

## Proxy Policy

Proxy endpoints are machine-local and are not stored in this public repository.

Public defaults:

- honor already configured `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY`
- set `NO_PROXY=localhost,127.0.0.1,::1` only when unset
- keep Go module proxy defaults:

```text
GOPROXY=https://proxy.golang.org,direct
GOSUMDB=sum.golang.org
```

Install machine-local proxy and PATH overrides from a private settings repository:

```powershell
.\scripts\Install-PwshAgentEnv.ps1 -PrivateSettingsPath <path-to-private-settings-repo>
.\scripts\Install-PwshAgentEnv.ps1 -PrivateSettingsPath <path-to-private-settings-repo> -ApplyUserEnvironment
```

`GOPROXY` selects the Go module proxy service. `HTTP_PROXY` / `HTTPS_PROXY` decide whether traffic to that service goes through a local proxy.


## Preflight

Run host and declarative validation before apply:

```powershell
.\scripts\Preflight-PwshAgentWindows.ps1 -Json
.\scripts\Preflight-PwshAgentWindows.ps1 -Configs .\config\windows-agent-core.winget,.\config\windows-agent-developer.winget -Json
```

`-Status -Json` and `-Verify -Json` include a machine-readable `Preflight` object.
YAML/schema/resource errors are blockers. The known WinGet DSC module-publicity warning
(`Microsoft.WinGet/Package` "not available publicly") is treated as a warning, not a blocker.
`winget configure test` runs when supported; warning-only results are not silently treated as success.
## Low-Risk Apply

One-click initializer (PowerShell 7 only). Default path is Core + Agent and auto-verifies after apply:


```powershell
.\scripts\Initialize-PwshAgentWindows.ps1
```

The default installs Core + Agent. Optional workloads are explicit:

```powershell
.\scripts\Initialize-PwshAgentWindows.ps1 -Developer
.\scripts\Initialize-PwshAgentWindows.ps1 -NativeBuild
.\scripts\Initialize-PwshAgentWindows.ps1 -Containers
.\scripts\Initialize-PwshAgentWindows.ps1 -AgentClients
.\scripts\Initialize-PwshAgentWindows.ps1 -EnableSafetyHooks
.\scripts\Initialize-PwshAgentWindows.ps1 -Full
```

Preview, inspect, verify, or roll back managed profile state. Default apply auto-runs smoke verification after success. Explicit `-Verify` remains available for later diagnosis. Preview/status/rollback:

```powershell
.\scripts\Initialize-PwshAgentWindows.ps1 -WhatIf -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
.\scripts\Initialize-PwshAgentWindows.ps1 -Rollback
```

The initializer does not invoke WSL, bash, or Linux package managers. Docker Desktop
is opt-in and is installed without selecting a backend; daemon availability is reported
separately from Docker CLI installation.

```powershell
.\scripts\Install-PwshAgentEnv.ps1 -ApplyUserEnvironment
```

Dry run:

```powershell
.\scripts\Install-PwshAgentEnv.ps1 -ApplyUserEnvironment -WhatIf
```

Verify:

```powershell
pwsh -NoLogo -NoProfile -Command ". '$env:USERPROFILE\.config\pwsh-ai\pwsh-ai-agent-overlay.ps1'; .\scripts\Test-PwshAgentEnv.ps1"
```

JSON report:

```powershell
.\scripts\Test-PwshAgentEnv.ps1 -Json
```

Deep runtime checks:

```powershell
.\scripts\Test-PwshAgentEnv.ps1 -Deep
```

Validate the declarative Windows baselines:

```powershell
winget configure validate -f .\config\windows-agent-core.winget
winget configure validate -f .\config\windows-agent-developer.winget
winget configure validate -f .\config\windows-agent-native-build.winget
```

Current caveat: on the current WinGet `v1.29.280`, all three new documents parse and
validate to the same non-zero result because the built-in `Microsoft.WinGet/Package`
resource reports "The module was not provided" and "not available publicly" warnings.
There were no YAML parse errors. Treat those known module-publicity warnings as a
WinGet packaging limitation; treat parse errors or concrete resource failures from
`show`/`test` as blockers.

## Candidate Install Commands

Small CLI tools:

```powershell
scoop install 7zip yq zip nuget
```

Go SDK and lightweight build/devops tools:

```powershell
scoop install go cmake ninja helm terraform golangci-lint
```

Go tools after `go` is installed:

```powershell
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install github.com/air-verse/air@latest
```

`golangci-lint` is installed as an independent package rather than with `go install`.

Visual Studio Build Tools / MSVC should be installed separately because it is large and changes the machine significantly.

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --accept-source-agreements --accept-package-agreements --disable-interactivity
```

In this environment, direct `winget install` calls for SDK packages timed out, and `winget --proxy` requires the administrator-only `ProxyCommandLineOptions` feature. Scoop was used as a user-level fallback for Go/CMake/Ninja/Helm/Terraform.


