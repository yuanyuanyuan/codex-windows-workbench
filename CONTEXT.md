# Windows AI Agent Workbench

This context defines a native Windows PowerShell environment for AI-assisted software development and the reusable skill that operates it. It distinguishes maintaining an established workstation from creating a portable starting point for a new one.

## Language

**Windows AI Agent Workbench**:
A native Windows development environment that equips AI agents with the shell, runtimes, tools, configuration, and safety boundaries needed to perform engineering work.
_Avoid_: Agent desktop, AI setup

**Workbench Skill**:
A Codex skill that maintains this repository's Workbench and can derive a reusable Workbench Template from its validated baseline.
_Avoid_: Installer, bootstrap script

**Workbench Template**:
A portable project starting point derived from the Workbench that another Windows environment can adapt without inheriting machine-specific state.
_Avoid_: Clone, backup

**Portable Workbench Distribution**:
A versioned, self-contained Workbench Template intended for computer migration or public reuse.
_Avoid_: Machine image, personal setup export

**Workbench Source Repository**:
The version-controlled project that publishes the Workbench Skill and its directly runnable bootstrap assets.
_Avoid_: Personal dotfiles repository, package registry

**Managed Workbench State**:
The configuration, files, and user-environment values explicitly owned and tracked by the Workbench.
_Avoid_: Entire user profile, machine state

**User-Supplied Proxy Configuration**:
Optional network-routing values supplied by a Workbench user for their own environment.
_Avoid_: Default proxy, bundled proxy credentials

**Configuration Wizard**:
The default interactive setup flow that collects optional user choices before a Workbench applies them.
_Avoid_: Silent defaults, automated installation

**Non-Interactive Workbench Run**:
An explicitly selected Workbench execution that never prompts and uses only supplied or already stored configuration.
_Avoid_: Headless wizard, inferred settings

**Codex Workbench MVP**:
The first public Workbench release, which supports only the Codex Agent as its AI agent client.
_Avoid_: Multi-agent platform, general agent-client manager

**Codex Client Installation**:
An explicitly confirmed installation or update of the Codex command through an official OpenAI distribution channel.
_Avoid_: Authentication automation, credential migration

**Codex Command Resolution**:
The rule that selects an existing official Codex App command before a separately installed official Codex CLI, while reporting all discovered candidates without deleting any.
_Avoid_: PATH cleanup, forced replacement

**fnm-Managed Node Runtime**:
The user-scoped Node.js runtime selected and activated by Fast Node Manager for a Workbench session.
_Avoid_: System Node installation, unmanaged Node PATH

**Node Runtime Selection**:
The recorded Node version chosen for an fnm-Managed Node Runtime, defaulting to the current LTS unless the user supplies an exact version.
_Avoid_: Undeclared version drift, global Node pin

**Elevation Decision**:
The user's explicit choice to rerun the Workbench with administrator rights for selected system-level work.
_Avoid_: Automatic UAC escalation, implicit privilege changes

**Template Generation**:
The explicit creation of an independent Portable Workbench Distribution from a Workbench Source Repository with machine-specific state excluded.
_Avoid_: Repository clone with state, profile export

**Resolved Package Record**:
The locally recorded source, package identity, version, and installation time for a package selected by the Workbench.
_Avoid_: Lockfile, package inventory guess

**Managed Configuration Rollback**:
The restoration or removal of only Workbench-owned configuration after ownership and file-hash checks.
_Avoid_: Package uninstall, credential cleanup, system restore

**Codex Base**:
The minimal default workload required to run and maintain the Codex Workbench MVP without optional language, editor, cloud, or container tools.
_Avoid_: Full developer workstation, bundled cloud stack

**Optional Workload**:
An explicitly selected tool group extending Codex Base: Developer Tools, Cloud Tools, Containers, or Native Build.
_Avoid_: Default dependency, hidden package bundle

**Selected Workload Verification**:
Verification that fails only for required Codex Base components and explicitly selected Optional Workloads, while reporting unselected workloads as not selected.
_Avoid_: Full-machine compliance check, missing optional tools

**Workbench-Local Setting**:
A non-secret user setting stored for and applied only within Workbench-managed PowerShell sessions.
_Avoid_: Global user environment variable, system network policy

**Supported Workbench Host**:
Native Windows PowerShell 7, the only shell host permitted to execute Workbench commands.
_Avoid_: Windows PowerShell 5.1, WSL, bash compatibility layer

**Installation Consent**:
The user's explicit approval of the displayed package sources, packages, elevation impact, and applicable package agreements for one Workbench run.
_Avoid_: Silent agreement acceptance, inferred license consent

**Shareable Diagnostic Export**:
A deliberately generated, redacted Workbench report suitable for sharing outside the user's computer.
_Avoid_: Raw installation log, environment dump

**Public Release Repository**:
The publishable Workbench Source Repository whose tracked contents are portable, non-secret, and safe for public distribution.
_Avoid_: Personal workstation archive, environment backup

## Relationships

- A **Workbench Skill** maintains one **Windows AI Agent Workbench**.
- A **Workbench Skill** derives **Workbench Templates** from the validated baseline of a **Windows AI Agent Workbench**.
- A **Portable Workbench Distribution** is a self-contained **Workbench Template** that excludes **Managed Workbench State** tied to an individual user.
- A **Workbench Source Repository** distributes the **Workbench Skill** and **Portable Workbench Distribution** together.
- A **Windows AI Agent Workbench** can manage **User-Supplied Proxy Configuration** only after the user provides it explicitly.
- A **Configuration Wizard** collects optional **User-Supplied Proxy Configuration** for a **Windows AI Agent Workbench**.
- A **Non-Interactive Workbench Run** bypasses the **Configuration Wizard**.
- A **Codex Workbench MVP** is a **Windows AI Agent Workbench** with Codex Agent as its sole supported client.
- A **Codex Workbench MVP** can perform **Codex Client Installation** without managing the user's Codex authentication state.
- A **Codex Command Resolution** selects the command verified by a **Codex Workbench MVP**.
- A **Codex Workbench MVP** uses an **fnm-Managed Node Runtime** to run Node-based tools.
- A **Node Runtime Selection** identifies the version installed in an **fnm-Managed Node Runtime**.
- A **Configuration Wizard** explains elevated work before the user makes an **Elevation Decision**.
- A **Template Generation** produces a **Portable Workbench Distribution** from a **Workbench Source Repository**.
- A **Resolved Package Record** documents a package installed for a **Windows AI Agent Workbench**.
- A **Managed Configuration Rollback** affects only **Managed Workbench State**.
- A **Codex Workbench MVP** installs **Codex Base** by default.
- An **Optional Workload** extends a **Codex Workbench MVP** only after explicit selection.
- A **Selected Workload Verification** evaluates a **Codex Workbench MVP** and its selected **Optional Workloads**.
- A **User-Supplied Proxy Configuration** is stored as a **Workbench-Local Setting** unless the user explicitly chooses global user-environment application.
- A **Codex Workbench MVP** executes only on the **Supported Workbench Host**.
- A **Configuration Wizard** obtains **Installation Consent** before installing packages.
- A **Non-Interactive Workbench Run** requires explicit **Installation Consent** flags before installing packages.
- A **Shareable Diagnostic Export** is derived from local Workbench diagnostics without exposing machine-specific settings.
- A **Public Release Repository** is a **Workbench Source Repository** that excludes **Managed Workbench State** tied to an individual user.
- A **Windows AI Agent Workbench** contains **Managed Workbench State** without owning unrelated user configuration.

## Example dialogue

> **Dev:** "Does the **Workbench Skill** copy my Codex login into a **Workbench Template**?"
> **Domain expert:** "No. Authentication is not **Managed Workbench State**, so the template only preserves the configuration structure and requires its own setup."
