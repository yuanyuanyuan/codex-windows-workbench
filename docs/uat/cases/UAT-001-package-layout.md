# UAT-001 Package layout

- Tier: A
- Gate: G1
- Priority: P0

## Objective
Ensure the public skill is packaged under `skills/<skill-name>/`, not as a root-only skill.

## Steps
1. Resolve repo root.
2. Assert `skills/stark-codex-windows-workbench/SKILL.md` exists.
3. Assert root `SKILL.md` does **not** exist as the packaging source of truth.
4. Assert sibling dirs exist: `scripts`, `config`, `agents`, `references`.

## Pass criteria
- Package path is `skills/stark-codex-windows-workbench/`
- Root-level skill packaging is absent

## Fail signals
- Only root `SKILL.md`
- Missing package folders under `skills/`
