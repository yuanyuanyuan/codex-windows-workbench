# UAT-005 Runtime from packaged path

- Tier: A
- Gate: G3
- Priority: P0

## Objective
Runtime checks execute from the packaged skill path, not a stale root `.\scripts` path.

## Steps
1. Resolve entry script under `skills/stark-codex-windows-workbench/scripts/`.
2. Run `-WhatIf -Json` from that path.
3. Assert exit code 0 and parseable Mode=WhatIf.

## Pass criteria
Packaged path is executable and returns a valid WhatIf report.

## Fail signals
- Missing entry script
- Tests still pointing at root `.\scripts`
