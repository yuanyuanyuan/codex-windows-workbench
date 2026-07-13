# UAT-013 npx install completeness

- Tier: B (network)
- Gate: G2 + G3
- Priority: P0 for publish

## Objective
Real `npx skills add` product tree includes scripts/config, not only SKILL.md.

## Steps
1. Install into an isolated project or temp workspace.
2. Resolve installed skill directory.
3. Assert required files exist:
   - `SKILL.md`
   - `scripts/Initialize-PwshAgentWindows.ps1`
   - `config/windows-agent-core.winget`
4. Optionally run WhatIf from installed path.

## Pass criteria
Installed product is complete and runnable.

## Fail signals
Installed directory contains only `SKILL.md`.

## Note
This is the exact class of bug that previously escaped incomplete UAT.
