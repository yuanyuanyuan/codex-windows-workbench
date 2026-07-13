# UAT-012 npx discovery

- Tier: B (network)
- Gate: G2
- Priority: P0 for publish

## Objective
Skills CLI can discover the skill from local package layout / published repo.

## Steps
1. Run `npx --yes skills add . --list -y` from repo root, or published form.
2. Assert skill name appears.

## Pass criteria
Found skill `stark-codex-windows-workbench`.

## Fail signals
0 skills found / wrong name.
