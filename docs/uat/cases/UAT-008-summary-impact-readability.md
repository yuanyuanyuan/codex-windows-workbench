# UAT-008 Summary/Impact readability

- Tier: A
- Gate: G5
- Priority: P0

## Objective
Users can see what will be installed and what will not.

## Steps
1. Run `-WhatIf -Json`.
2. Assert report has `Summary` lines.
3. Assert report has `Impact` with package/managed-file information.

## Pass criteria
Human-readable impact is present and non-empty.

## Fail signals
Only opaque JSON/actions with no Summary/Impact.
