# UAT-004 Simulated install product completeness

- Tier: A
- Gate: G2
- Priority: P0

## Objective
Catch the false-pass class where source is complete but install product is not.

## Steps
1. Create a temp install target directory.
2. Copy `skills/stark-codex-windows-workbench/**` into it, simulating an install product tree.
3. Assert the same required file set exists in the install target.
4. Optionally assert file count > 1 (not only SKILL.md).

## Pass criteria
Installed product tree includes scripts/config/agents, not only `SKILL.md`.

## Historical bug
`npx skills add` previously installed only:

```text
.agents/skills/stark-codex-windows-workbench/SKILL.md
```

This case must permanently protect against that.
