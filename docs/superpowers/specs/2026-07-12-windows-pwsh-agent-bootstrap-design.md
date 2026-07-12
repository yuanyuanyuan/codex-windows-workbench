# Windows PowerShell 7 AI Agent Bootstrap Design

## Goal

Provide one repeatable native-Windows initializer for AI-assisted development. The
default path installs and verifies the agent workstation baseline. Heavy native build
and container components remain explicit opt-in phases.

WSL, Linux compatibility layers, desktop debloating, and broad personal application
installation are out of scope.

## Decisions

- PowerShell 7 is the supported shell and script host.
- `winget`/DSC is the declarative source for Windows applications and machine settings.
- Scoop supplies small user-level CLI tools where it is a better fit.
- Official language installers and language-native package commands are used for
  language-specific tools.
- User configuration is additive and backed up before a profile loader is appended.
- Existing agent settings are never overwritten by default.
- Proxy values use the existing user policy; no credentials are stored in this repo.
- The default plan excludes Visual Studio Build Tools, Windows SDK, MSBuild, and Docker
  Desktop. These are available through explicit switches.

## User Interface

The single entry point is `scripts/Initialize-PwshAgentWindows.ps1`.

- No switches: run preflight, install Core + Agent, configure the profile overlay, and
  verify the result.
- `-Developer`: add Go, build helpers, DevOps CLIs, and PowerShell development modules.
- `-NativeBuild`: install Visual Studio Build Tools with MSVC, Windows SDK, MSBuild,
  and vswhere through a dedicated winget configuration.
- `-Containers`: install/configure Docker Desktop and verify client/server separately.
- `-Full`: enable Developer, NativeBuild, and Containers together.
- `-WhatIf`: show all planned actions without changing the machine.
- `-Status`: report installed package phases, sentinel state, PATH sources, and health
  results without installing anything.
- `-Verify`: run command and runtime checks and return a non-zero exit code for required
  failures.
- `-Rollback`: restore only files and registry values created by this tool, using the
  manifest recorded in the local state directory.

The entry point must be safe to rerun. A phase that already has a valid sentinel is
skipped unless `-Force` is provided. Each phase writes an action summary and failure
detail to a local state directory under the user's profile.

## Architecture

The initializer is a thin orchestrator over focused scripts:

1. `Preflight`: assert Windows PowerShell 7, locate winget/scoop, inspect elevation,
   validate proxy reachability without exposing credentials, and refresh PATH.
2. `Install-WingetConfiguration`: run `validate`, then `test`/`configure` with retry,
   agreement flags, elevation-aware diagnostics, and a success sentinel. Known DSC
   module-publicity warnings are recorded as warnings; parse and resource failures are
   blockers.
3. `Install-ScoopTools`: install the selected tier with idempotent package checks,
   then refresh the current session PATH.
4. `Install-LanguageTools`: install Go-native tools and PowerShell modules only for the
   Developer tier.
5. `Install-AgentProfile`: copy the overlay, create or append the managed profile loader,
   initialize managed hook/config directories, and write a backup manifest.
6. `Test-PwshAgentEnv`: provide the existing command inventory and deep smoke tests,
   extended with phase and sentinel information.

The current `config/windows-agent-dev.winget`, `config/pwsh-ai-agent-overlay.ps1`,
`scripts/Install-PwshAgentEnv.ps1`, and `scripts/Refresh-EnvPath.ps1` remain reusable
building blocks. The existing low-risk profile installer remains available as a focused
operation; the new entry point composes it rather than duplicating its profile logic.

## Package Tiers

Core covers PowerShell 7, Git/Git LFS, GitHub CLI, Windows Terminal, VS Code, VC++
runtime, Node/npm/corepack/pnpm, Python/pip/uv, Docker CLI, kubectl, winget, Scoop,
curl, and SSH. Agent tooling also includes the text/search CLIs used by the overlay:
rg, fd, fzf, jq, bat, and delta.

Developer adds Go, gofmt, gopls, dlv, golangci-lint, air, CMake, Ninja, yq, zip,
nuget, Helm, Terraform, Pester, PSScriptAnalyzer, and PSResourceGet.

NativeBuild adds the large Visual Studio Build Tools workload. It must be isolated so
users can opt into disk use, elevation, installer duration, and reboot requirements.

Containers adds Docker Desktop. Docker client presence is a command check; daemon
availability is a separately reported runtime condition and is never silently treated as
a successful server check.

## State, Safety, and Failure Handling

State is kept outside the repository under `%LOCALAPPDATA%\PwshAiAgent\state`. It
contains phase sentinels, package command output, and a manifest of files/registry values
owned by this initializer. Secrets and full environment dumps are excluded.

The installer stops on a required phase failure, prints the exact phase and suggested
manual command, and preserves logs for diagnosis. Optional tool failures are collected
and reported without hiding required failures. It never invokes WSL, `bash`, or Linux
package managers.

Rollback is conservative: restore backed-up profile files and remove only managed files
whose hashes still match the recorded post-install values. Registry cleanup is limited to
values written by this initializer and does not remove pre-existing user settings.

## Verification

The implementation is complete only when these checks are available and pass on a
machine with the required prerequisites:

- PowerShell parser checks for every script.
- `-WhatIf` produces a complete plan without changing managed state.
- `-Status` and `-Verify -Json` are machine-readable and stable.
- Core and Agent sentinels are created only after their phases succeed.
- Node, Python, Go, and uv smoke tests execute successfully when their tools exist.
- Missing Docker daemon is reported as a warning unless `-Containers` explicitly made it
  a required phase.
- Existing profile content survives installation and rollback.
- The winget document validates, with documented handling for known non-blocking DSC
  warnings.

