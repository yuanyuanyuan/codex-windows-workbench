# UAT Cases Index

Executable coverage is implemented by `tests/uat/Invoke-UatRegression.ps1`.

| ID | Tier | Title | Catches |
|---|---|---|---|
| [UAT-001](./UAT-001-package-layout.md) | A | Package layout | root-level skill packaging |
| [UAT-002](./UAT-002-identity-consistency.md) | A | Identity consistency | skill/repo/plugin name drift |
| [UAT-003](./UAT-003-required-package-files.md) | A | Required package files | incomplete skill package source |
| [UAT-004](./UAT-004-simulated-install-completeness.md) | A | Simulated install product completeness | "only SKILL.md installed" class bugs |
| [UAT-005](./UAT-005-runtime-from-packaged-path.md) | A | Runtime from packaged path | source-path-only green tests |
| [UAT-006](./UAT-006-default-core-agent-plan.md) | A | Default Core+Agent plan | optional workloads leaking into default |
| [UAT-007](./UAT-007-no-wsl-like-actions.md) | A | No WSL-like actions | WSL/bash/apt/brew regression |
| [UAT-008](./UAT-008-summary-impact-readability.md) | A | Summary/Impact readability | opaque install results |
| [UAT-009](./UAT-009-contract-unit-tests.md) | A | Contract unit tests | script contract breakage |
| [UAT-010](./UAT-010-docs-install-path-correctness.md) | A | Docs/install path correctness | manual/npx path docs drift |
| [UAT-011](./UAT-011-no-chat-plugin-install-path.md) | A | No chat `/plugin` install path | invalid Codex chat slash command docs |
| [UAT-012](./UAT-012-npx-discovery.md) | B | npx discovery | skill not discoverable by skills CLI |
| [UAT-013](./UAT-013-npx-install-completeness.md) | B | npx install completeness | real incomplete install product tree |
