# Windows PowerShell 7 AI Agent Workbench — Implementation Prompt

Use this prompt to drive an agent worker through the remaining implementation of this repository.

## Mission

Implement the remaining work in:

- `docs/superpowers/plans/2026-07-12-windows-pwsh-agent-bootstrap-plan-2.md`
- `docs/superpowers/specs/2026-07-12-windows-pwsh-agent-bootstrap-design.md`
- `docs/superpowers/specs/2026-07-12-public-codex-workbench-skill-design.md`
- `CONTEXT.md`
- `docs/windows-agent-env.md`
- `docs/gap-analysis-github-windows-bootstrap.md`

Build a repeatable native Windows PowerShell 7 workbench initializer. Prefer hardening the existing code over rewriting from scratch.

First production milestone: **Core + Agent + Verify**.
Final public milestone: **Codex Workbench MVP** with docs, CI, and portable skill packaging.
Do not treat authentication, third-party MCP, or multi-agent marketplace install as in-scope.

## Repo reality at start

Already present and partially working:

- Entry point: `scripts/Initialize-PwshAgentWindows.ps1`
- Profile installer: `scripts/Install-PwshAgentEnv.ps1`
- PATH refresh: `scripts/Refresh-EnvPath.ps1`
- Verification: `scripts/Test-PwshAgentEnv.ps1`
- Contract smoke tests: `scripts/Test-InitializePwshAgentWindows.ps1`
- Overlay: `config/pwsh-ai-agent-overlay.ps1`
- Winget docs: `config/windows-agent-core.winget`, `config/windows-agent-developer.winget`, `config/windows-agent-native-build.winget`, `config/windows-agent-dev.winget`

Known gaps versus plan/spec:

1. No `scripts/Private/*` split yet.
2. No dedicated preflight script.
3. No `-AgentClients`.
4. No agent-content governance pack.
5. Apply does not auto-run Verify after success.
6. No CI workflow.
7. No root-level public Skill package (`SKILL.md`, `agents/openai.yaml`, template export).
8. Tests are thinner than plan/spec contract requirements.

## Non-negotiable constraints

1. Supported host only: native Windows + PowerShell 7+.
2. Reject Windows PowerShell 5.1, WSL, bash, sh, apt, brew, and Linux package managers.
3. Never invoke WSL backend selection or WSL install commands.
4. Default selection is Core + Agent only.
5. Developer / NativeBuild / Containers / AgentClients are explicit opt-in.
6. Node is managed by fnm; default Node version is `24.18.0` LTS unless an explicit override is provided later by design.
7. Prefer Codex path: `%LOCALAPPDATA%\OpenAI\Codex\bin` over WindowsApps internal paths.
8. UTF-8, PlainText output, no noisy progress.
9. PATH changes must use exact-entry match + dedupe; never substring deletion.
10. Additive profile changes only; backup before append/overwrite of managed files.
11. Never write tokens, credentials, MCP endpoints, permissions grants, or secrets into the repo or managed state.
12. Package installed != runtime available. Report Docker client and Docker server separately.
13. Rollback restores only managed files/settings after ownership + hash checks. Never uninstall packages. Never delete auth state.
14. Public repo hygiene: no username, no absolute personal paths, no proxy endpoints, no secrets, no local state/logs/backups.
15. Public MVP supports Codex only. Claude/Gemini/Copilot may be internal scaffolding later, but do not expand the public product surface without an explicit decision.

## Execution method

Work task-by-task from plan-2. Track each checkbox. Prefer small commits after each green task group.

Recommended order:

1. Tasks 1-3: tests + refactor + preflight, no real package installs required for completion.
2. Task 4: Core + Agent one-click quality, then real machine apply only after WhatIf review.
3. Tasks 5-6: agent-client/governance capabilities with public Codex-only boundary.
4. Tasks 7-8: only if heavy workloads are intentionally needed.
5. Task 9 + public skill packaging/docs/CI.

Do not jump to NativeBuild, Docker Desktop, or Full until Core + Agent is green.

## Task instructions

### Task 1 — Lock the contract with tests

Files:

- modify `scripts/Test-InitializePwshAgentWindows.ps1`
- modify `scripts/Test-PwshAgentEnv.ps1`

Add coverage for:

- PowerShell 7 rejection of 5.1 / unsupported host
- default Core + Agent selection
- Full phase selection
- zero WSL-like actions
- `Invoke-Phase` declares `SupportsShouldProcess`
- `-WhatIf` does not create `%LOCALAPPDATA%\PwshAiAgent\state`
- sentinel status, stale sentinel handling, `-Force`
- required vs recommended command failure behavior

Rules:

- Prefer isolated temporary state roots for unit/contract tests.
- Do not call real `winget install`, `scoop install`, `fnm install`, `npm install`, UAC, Docker daemon, or Codex login in unit/contract tests.
- Make new tests fail first if the implementation is still incomplete.
- Keep the direct-run test entrypoint usable by humans.

Commands:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Test-InitializePwshAgentWindows.ps1
pwsh -NoLogo -NoProfile -File .\scripts\Test-PwshAgentEnv.ps1
```

### Task 2 — Split phase definitions and orchestration

Files:

- modify `scripts/Initialize-PwshAgentWindows.ps1`
- create `scripts/Private/PwshAiAgent.Phases.ps1`
- create `scripts/Private/PwshAiAgent.State.ps1`

Requirements:

- Keep one public entry point.
- Move phase metadata, action-plan generation, sentinel read/write, and manifest helpers into private modules/scripts.
- Pass ShouldProcess context only through advanced functions.
- Preserve JSON report shape: `Mode`, `Changed`, `StateRoot`, `Phases`, `Actions`, `Verification`.
- Re-run Task 1 tests and parser checks after the split.

### Task 3 — Real preflight and declarative validation

Files:

- create `scripts/Preflight-PwshAgentWindows.ps1`
- modify `scripts/Initialize-PwshAgentWindows.ps1`
- modify `docs/windows-agent-env.md`

Requirements:

- Check PowerShell major version, Windows platform, winget availability, required local directories.
- Refresh PATH before command checks.
- Check proxy reachability without logging credentials or proxy secrets.
- Run `winget configure validate` for selected documents.
- Treat YAML/schema/resource errors as blockers.
- Treat known DSC module-publicity warning as warning, not blocker.
- Run `winget configure test` only when supported by the selected configuration and installed WinGet.
- Include machine-readable preflight report in `-Status -Json` and `-Verify -Json`.

### Task 4 — Make Core + Agent truly one-click and auto-verified

Files:

- modify `scripts/Initialize-PwshAgentWindows.ps1`
- modify `scripts/Install-PwshAgentEnv.ps1`
- modify `config/pwsh-ai-agent-overlay.ps1`
- modify `scripts/Test-PwshAgentEnv.ps1`

Requirements:

- Execute Core and Agent with retry + logging.
- Refresh PATH after winget/scoop/fnm/corepack operations.
- Keep profile install additive and idempotent.
- Verify fnm, Node 24.18.0, npm, npx, pnpm, yarn if expected, and Codex path resolution.
- After default apply, auto-run smoke tests for Node, Python, uv, and PowerShell.
- Required failures return non-zero; recommended omissions are reported separately.
- Keep explicit `-Verify` for later diagnosis.

Machine apply sequence only after WhatIf looks correct:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Full -WhatIf -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
```

Success criteria for this milestone:

- no WSL/bash/Linux package manager calls
- only Core + Agent installed by default
- valid completed phases are skipped on rerun unless `-Force`
- Node/Python/uv/Git/rg/fd/jq/Codex resolve correctly

### Task 5 — Explicit AgentClients phase (public Codex-first)

Files:

- create `config/agent-clients.json`
- create `scripts/Install-AgentClients.ps1`
- modify `scripts/Initialize-PwshAgentWindows.ps1`
- modify `scripts/Test-PwshAgentEnv.ps1`
- create `scripts/Test-AgentClients.ps1`

Public MVP policy:

- First complete Codex install/resolution/verify path.
- Do not expand public docs or default UX to Claude/Gemini/Copilot until explicitly requested.
- If scaffolding multi-client schema, keep non-Codex clients opt-in and out of default public claims.

Requirements:

- Each client definition includes: `Name`, `Source`, `InstallCommand`, `Command`, `VersionCommand`, `RequiresLogin`.
- Validate package/command identities against official vendor docs before shipping.
- Require explicit `-AgentClients`.
- Never infer authentication from install state.
- Never write tokens, MCP URLs, or permissions files.
- Report `Installed`, `Missing`, `LoginRequired`, `InvocationFailed` separately.
- Tests must prove auth/MCP/permission writes do not occur.

### Task 6 — Modular agent governance without expanding trust boundary

Files:

- create `config/agent-content/README.md`
- create category README files under `config/agent-content/{rules,hooks,skills,commands,agents}/`
- modify `scripts/Install-PwshAgentEnv.ps1`
- modify `scripts/Initialize-PwshAgentWindows.ps1`

Requirements:

- Use modular taxonomy for content categories.
- Add Windows-native dangerous-git hook covering force push, hard reset, aggressive clean, forced checkout, amend, interactive rebase.
- Enable hooks only with `-EnableSafetyHooks`.
- Backup existing agent settings before merge.
- Keep client content separated if multi-client scaffolding exists.
- Provide dry-run/status/rollback outputs for content installation.
- Never silently install marketplace plugins or remote MCP servers.

### Task 7 — Heavy NativeBuild behavior

Files:

- modify `scripts/Initialize-PwshAgentWindows.ps1`
- modify `config/windows-agent-native-build.winget`
- modify `scripts/Test-PwshAgentEnv.ps1`
- modify `docs/windows-agent-env.md`

Requirements:

- Confirm VS Build Tools override selects MSVC + Windows SDK components.
- Detect elevation and reboot-required installer results.
- Locate MSBuild and vswhere after install.
- Native compile smoke test only when NativeBuild selected.
- Keep `msbuild` recommended in baseline; required only for NativeBuild verification.

### Task 8 — Containers without WSL compatibility

Files:

- modify `scripts/Initialize-PwshAgentWindows.ps1`
- modify `scripts/Test-PwshAgentEnv.ps1`
- modify `docs/windows-agent-env.md`

Requirements:

- Install Docker Desktop only with `-Containers` or `-Full`.
- No WSL commands or backend selection.
- Verify docker client and server separately.
- Report daemon/virtualization/permissions/named-pipe failures distinctly.
- Daemon not running remains a warning unless the selected success policy makes it required.

### Task 9 — Verification, documentation, and CI

Files:

- modify tests and docs as needed
- create `.github/workflows/pwsh-agent-bootstrap.yml`

Requirements:

- Parser checks for every PowerShell file.
- WhatIf for default and Full plans asserts zero WSL-like actions.
- Status/Verify JSON parsing checks.
- Node/Python/Go/uv smoke tests when tools exist.
- Winget validate for declarative docs with known-warning explanation.
- PSScriptAnalyzer when available.
- CI must not perform real machine installation.
- Document exact commands for default, Developer, NativeBuild, Containers, AgentClients, Full, Verify, Status, Rollback.

## Public Skill packaging overlay (from skill design)

After Core + Agent is solid, add public packaging work:

1. Root-level `SKILL.md` with only `name` + `description` frontmatter.
2. `agents/openai.yaml` generated/regenerated via skill-creator tools, not hand-drifted.
3. Keep `SKILL.md` under 500 lines; put detailed contracts in `references/`.
4. Interactive configuration wizard by default; `-NonInteractive` uses provided/saved settings only.
5. Non-interactive package installs require explicit agreement acceptance flags.
6. Never auto-trigger UAC; only explain required elevation.
7. Proxy defaults are workbench-local unless user explicitly chooses managed global write.
8. Template generation excludes `.git`, state, logs, backups, auth, local settings, user paths.
9. Shareable diagnostics must redact usernames, proxy endpoints, env values, credentials.
10. Run skill structure validation and secret scanning before any public release claim.

Public first version supports Codex only.

## State and safety contract

State root:

```text
%LOCALAPPDATA%\PwshAiAgent\state\
  phase-core.json
  phase-agent.json
  phase-agentclients.json
  phase-developer.json
  phase-nativebuild.json
  phase-containers.json
  manifest.json
  backups\
  logs\
```

Rules:

- Write phase sentinel only after all required actions in that phase succeed.
- Valid sentinel causes skip unless `-Force`.
- Logs may include command output/exit codes, never full secret/env dumps.
- File rollback restores backups; deletes newly created managed files only when current hash matches post-install hash.
- Registry rollback only for values owned in the manifest.
- Rollback is not package uninstall.

## Definition of done

Implementation is done only when all are true:

1. New PowerShell 7 process can run the default initializer without WSL/bash/Linux package manager calls.
2. Default path prepares only Core + Agent.
3. Existing fnm/Node/Codex/profile/PATH/proxy/encoding decisions remain intact.
4. Rerun skips valid completed phases; `-Force` reruns.
5. `-WhatIf -Json`, `-Status -Json`, `-Verify -Json`, `-Rollback` are stable and machine-readable.
6. Profile/registry changes are backed up; rollback is ownership-safe.
7. After Core + Agent, Node/npm/npx/pnpm/Python/uv/Go/Git/rg/fd/jq/Codex resolve correctly where selected/required.
8. AgentClients never writes auth or remote MCP state.
9. NativeBuild verification finds MSBuild/MSVC/Windows SDK/vswhere only when that phase is selected and installed.
10. Containers reports Docker client/server separately and never assumes WSL.
11. All PowerShell files pass parser checks.
12. Tests exit 0.
13. Docs distinguish “verified on current machine” from “available as explicit install phase”.
14. Public packaging, if claimed, has no personal paths/secrets and validates as a skill package.

## Operator commands cheat sheet

Preview:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Full -WhatIf -Json
```

Default apply:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1
```

Verify / status / rollback:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Verify -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Status -Json
pwsh -NoLogo -NoProfile -File .\scripts\Initialize-PwshAgentWindows.ps1 -Rollback
```

Optional workloads:

```powershell
.\scripts\Initialize-PwshAgentWindows.ps1 -Developer
.\scripts\Initialize-PwshAgentWindows.ps1 -NativeBuild
.\scripts\Initialize-PwshAgentWindows.ps1 -Containers
.\scripts\Initialize-PwshAgentWindows.ps1 -Full
```

Winget document checks:

```powershell
winget configure validate -f .\config\windows-agent-core.winget
winget configure validate -f .\config\windows-agent-developer.winget
winget configure validate -f .\config\windows-agent-native-build.winget
```

## Working style for the implementing agent

1. Read existing scripts before editing.
2. Prefer additive, reversible changes.
3. Keep public surface minimal and documented.
4. Prefer contract tests and WhatIf evidence over claims.
5. Commit after each coherent green task group.
6. If blocked by elevation, reboot, disk, or vendor package identity uncertainty, stop and report the exact blocker with the manual command needed.
7. Never store secrets in the public repository.
8. Do not mark the plan complete until definition-of-done is satisfied and tests pass.

## Immediate start command for the next agent

Start at Task 1 now:

1. Expand `scripts/Test-InitializePwshAgentWindows.ps1` and related tests to the plan contract.
2. Run the tests and capture the red failures.
3. Implement the smallest code changes needed to go green for Task 1.
4. Continue into Task 2 only after Task 1 is green or intentionally red-for-missing-feature with a clear map of remaining code work.
