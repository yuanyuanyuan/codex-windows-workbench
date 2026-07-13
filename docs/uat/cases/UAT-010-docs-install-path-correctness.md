# UAT-010 Docs/install path correctness

- Tier: A
- Gate: G7
- Priority: P0

## Objective
Install docs point to the skill package folder, not whole-repo-as-skill or stale paths.

## Steps
1. Read `docs/install.md`, `README.md`, `README.zh-CN.md`.
2. Assert references to `skills/stark-codex-windows-workbench`.
3. Assert recommended install uses `npx skills add yuanyuanyuan/stark-codex-windows-workbench`.
4. Assert manual install copies the skill folder.

## Pass criteria
Docs describe skill-folder install product correctly.

## Fail signals
Docs tell users to install/copy repo root as the skill product.
