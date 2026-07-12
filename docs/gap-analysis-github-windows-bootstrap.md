# GitHub Windows Bootstrap Gap Analysis

## Scope

This project optimizes native Windows PowerShell for Codex/AI agents. WSL is explicitly out of scope.

## Compared Projects

This analysis was updated after cloning and reading the setup scripts/configuration files for the listed projects, not only their README files. The local audit copies were under `%TEMP%\windows-agent-bootstrap-audit`.

### microsoft/WindowsDeveloperConfig

Repository: https://github.com/microsoft/WindowsDeveloperConfig

Most relevant reference. It uses `winget configure` / DSC as the source of truth for Windows developer machine state. It separates a complete workstation setup from individual language workloads such as TypeScript, Python, Go, Rust, Java, .NET, and PowerShell.

Useful patterns to adopt:

- Declarative `.winget` configuration as the long-term machine bootstrap layer.
- `winget configure validate/test` before applying.
- Wrapper scripts around `winget configure`: preflight, enable/assert winget configuration support, retry, current-session PATH refresh, and a machine-readable success sentinel.
- Hello-world verification per language/toolchain, not just command-existence checks.
- Explicit handling for reboot/elevation-heavy steps.
- Per-workload `.winget` files using `metadata.winget.processor: dscv3`, `acceptAgreements: true`, and elevated package metadata.

Patterns not adopted:

- WSL bootstrap.
- Opinionated desktop cleanup and distraction-free OS defaults.

### blackwell-systems/blackdot

Repository: https://github.com/blackwell-systems/blackdot

More relevant for AI coding environment governance than for Windows package install. It treats shell config, secrets, developer tools, and Claude Code integration as one portable system.

Useful patterns to adopt:

- Feature presets such as `minimal`, `developer`, `agent`, and `full`.
- Health checks that explain what is broken and how to fix it.
- Agent-specific safety hooks and profile sync.
- Secrets/SSH/git identity as explicit setup dimensions.
- A tiered package catalog. The source scripts separate minimal tools from enhanced/full tools instead of installing everything by default.
- Dangerous git command hooks for agent shells, especially force push, hard reset, forced clean, forced checkout, amend, and interactive rebase.

Patterns not adopted yet:

- Secret manager integration.
- Cross-platform framework migration.

### Ven0m0/Win

Repository: https://github.com/Ven0m0/Win

Useful as a high-coverage Windows 11 bootstrap example. It chains prerequisites, package installation, debloat, dotfiles deployment, and optional WSL.

Useful patterns to adopt:

- Phase flags such as skip packages, skip debloat, skip WSL, deploy configs only.
- Shared utility functions for package install and PATH refresh.
- Clear separation between bootstrap and repeatable local setup.
- `Wait-ForWinget`, package resolution helpers, and explicit phase summaries.
- Catalogued optional tools such as Bun, Deno, SQLite, `sccache`, `taplo`, `topgrade`, and PowerShell modules.

Patterns not adopted:

- Debloat.
- Huge default software catalog.
- WSL.

### microsoft/intelligent-terminal

Repository: https://github.com/microsoft/intelligent-terminal

The source tree and installer were read, including `README.md`,
`installer/install-local-terminal.ps1`, `.config/configuration.winget`, and the
agent policy files under `policies/`. It is an experimental Windows Terminal fork
with a local ACP transport layer: it detects Copilot, Claude, Codex, and Gemini
agent CLIs and passes shell context over stdio. It does not replace the agent CLIs
or authenticate them.

Useful patterns to adopt:

- Keep Node/npm/npx in the required baseline.
- Verify agent CLI prerequisites separately from general developer tools.
- Treat agent discovery, session state, error context, and hook policy as separate
  concerns from package installation.

### blackwell-systems/dotclaude

Repository: https://github.com/blackwell-systems/dotclaude

Relevant as a Claude Code profile manager rather than a Windows bootstrapper. The Windows installer creates `~\.claude`, installs a binary to `~\.local\bin`, sets `DOTCLAUDE_REPO_DIR`, and initializes hook directories.

Useful patterns to adopt:

- Treat agent configuration as managed state, not scattered JSON files.
- Keep `~\.local\bin` in PATH for agent helper binaries.
- Initialize hook directories consistently even before specific hooks are enabled.

### darkroomengineering/cc-settings

Repository: https://github.com/darkroomengineering/cc-settings

Relevant for agent governance. The Windows bootstrap ensures Bun, delegates real logic to a TypeScript setup script, supports dry-run/status/rollback, and composes settings from separate JSON fragments.

Useful patterns to adopt:

- Dry-run, status, migrate-only, and rollback modes for agent settings.
- Modular config fragments for core settings, permissions, MCP, and hooks.
- Hook categories for pre-command safety checks, post-edit validation, session start verification, handoff on compaction/session end, and shell command logging.

### rohitg00/awesome-claude-code-toolkit

Repository: https://github.com/rohitg00/awesome-claude-code-toolkit

The repository was downloaded and read, including `README.md`,
`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and representative
`agents/`, `skills/`, `commands/`, `hooks/`, `rules/`, and `mcp-configs/` entries.
It is a large Claude Code content/plugin catalog, not a Windows bootstrapper. Its
value is the content taxonomy and governance patterns, not its full package list.

Useful patterns to adopt:

- Keep agent content modular by category instead of one monolithic settings file.
- Provide explicit installation and verification commands for hooks/plugins.
- Make MCP, hooks, rules, commands, skills, and agents independently selectable.
- Add a safety review gate before enabling command hooks or external MCP servers.

Patterns explicitly not adopted by the Windows initializer:

- Installing the complete marketplace or all bundled plugins by default.
- Running bash-based installers or assuming Claude Code is the only supported agent.
- Copying third-party MCP credentials, permissions, or remote endpoints automatically.

## Current Coverage

Already covered:

- Clean PowerShell output for agents: UTF-8, plain text, quiet progress.
- Optional user-level proxy variables supplied from machine-local private settings.
- Local loopback exemption via `NO_PROXY`.
- PATH source control for `7z`, Scoop, WinGet links, Codex bin, Go bin.
- Required tool check: Git, GitHub CLI, ripgrep, fd, fzf, jq, Node, npm, pnpm, Python, uv, Docker, kubectl, winget, scoop, curl, ssh.
- Go toolchain: `go`, `gofmt`, `gopls`, `dlv`, `golangci-lint`, `air`.
- Build/devops tools: `cmake`, `ninja`, `nuget`, `yq`, `zip`, `helm`, `terraform`.
- Current-session PATH refresh script: `scripts/Refresh-EnvPath.ps1`.
- `.winget` package metadata aligned with Microsoft workload examples.
- Source-level audit includes `intelligent-terminal` and
  `awesome-claude-code-toolkit`; the audit workspace is under
  `%TEMP%\windows-agent-bootstrap-audit`.

## Current Limits And Follow-Ups

Verified in the source implementation and local environment:

- Deep Node, Python, Go, and uv smoke tests pass.
- Docker CLI is present; Docker server is correctly reported as an optional warning
  when the daemon is not running.
- The initializer has retry, current-session PATH refresh, phase sentinels,
  machine-readable WhatIf/Status/Verify output, and conservative profile rollback.
- The three new `.winget` documents parse; WinGet emits only the known built-in DSC
  module-publicity warnings described in `docs/windows-agent-env.md`.

Not claimed as an end-to-end machine apply in this audit:

- `-NativeBuild` remains an explicit heavy installer. The current machine still lacks
  `msbuild` until that phase is intentionally applied.
- Docker Desktop is opt-in and its daemon may require a separate user start/login.
- The initializer creates managed `hooks` and `mcp` directories but does not enable
  third-party hooks, plugins, remote MCP endpoints, permissions, or credentials.

### P2

- Optional `rclone` for rsync-style workflows.
- Optional `fastfetch` for quick system inventory.
- Optional cloud CLIs: `aws`, `az`, `gcloud`.
- Optional language stacks and tools: Rust, Java, PHP, SQL, Bun, Deno, SQLite, `sccache`, `taplo`, `topgrade`, `glow`, `dust`, `age`.

## Recommendation

Keep this project narrower than general dotfiles frameworks:

1. Native Windows PowerShell agent runtime.
2. Reproducible tool baseline.
3. Verifiable smoke tests.
4. Optional heavy installers kept explicit.

Do not add WSL, debloat, desktop personalization, or broad application installation unless the goal changes.

