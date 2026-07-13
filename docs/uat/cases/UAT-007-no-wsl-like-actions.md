# UAT-007 No WSL-like actions

- Tier: A
- Gate: G4
- Priority: P0

## Objective
Default and Full plans never schedule WSL/bash/apt/brew actions.

## Steps
1. Run default `-WhatIf -Json`.
2. Run `-Full -WhatIf -Json`.
3. Scan Actions for WSL/bash/Linux/apt/brew markers.

## Pass criteria
Zero WSL-like planned actions.

## Fail signals
Any planned action mentioning WSL/bash/apt/brew.
