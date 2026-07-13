# UAT Regression Rules

Skill: `stark-codex-windows-workbench`  
Scope: every update that can affect install, packaging, docs identity, or workbench runtime behavior.

## 1. Purpose

Guarantee that a change is not "source-only green".

A pass means:

1. the **skill package** is complete
2. the **installed product tree** is complete
3. the **runtime path used after install** still works
4. identity/docs/install channels stay consistent
5. safety boundaries still hold

## 2. When regression is mandatory

Run the default suite before claiming an update is ready if any of these changed:

| Change area | Examples |
|---|---|
| Skill package | `skills/**`, `SKILL.md`, scripts, config, agents, references |
| Packaging | repo layout, plugin manifests, `package.json`, root wrappers |
| Install UX | `docs/install.md`, README install/use/uninstall sections |
| Runtime behavior | WhatIf/Apply/Status/Verify/Rollback, Summary/Impact |
| Safety / identity | naming, no-WSL, no-secret policy, Codex-only MVP |
| CI / tests | workflow, contract tests, UAT runner itself |

If unsure: run it.

## 3. Required gates (never optional)

These are hard gates. Any fail blocks release/publish claims.

### G1. Package layout gate
Installed skill layout source of truth must be:

```text
skills/stark-codex-windows-workbench/
  SKILL.md
  scripts/
  config/
  agents/
  references/
```

Root-level skill-only packaging is forbidden.

### G2. Install product completeness gate
Validate the **product directory that users actually get after install**, not only the source tree.

Minimum required files in installed skill dir:

- `SKILL.md`
- `scripts/Initialize-PwshAgentWindows.ps1`
- `scripts/Private/PwshAiAgent.Phases.ps1`
- `scripts/Private/PwshAiAgent.State.ps1`
- `config/windows-agent-core.winget`
- `agents/openai.yaml`

This gate exists because `npx skills` can install only `SKILL.md` if packaging is wrong.

### G3. Runtime-from-installed-path gate
WhatIf/Status/contract checks must execute from the **packaged/installed skill path**, not an imaginary root `.\scripts` path.

### G4. Default plan gate
Default WhatIf must:

- select only Core + Agent
- keep optional workloads NotSelected
- report `Changed=false`
- contain zero WSL/bash/apt/brew actions

### G5. Reporting gate
WhatIf must expose human-readable impact:

- `Summary`
- `Impact` (packages, managed files, non-actions)

### G6. Identity consistency gate
These names must match:

- skill name
- repo product name
- plugin name
- direct invocation names in docs

### G7. Docs channel gate
Install docs must support:

- RedSkill wording
- `npx skills add` (recommended)
- Codex Plugin CLI (`codex plugin ...`, not chat `/plugin`)
- Manual clone/copy of the skill folder

### G8. Contract suite gate
Existing no-network contract tests must still pass.

## 4. Suite tiers

### Tier A — Default / CI / every update
Always run. No real winget/scoop package install. No secret writes.

Includes:

- UAT-001 Package layout
- UAT-002 Identity consistency
- UAT-003 Required files in skill package
- UAT-004 Simulated install product completeness
- UAT-005 Runtime WhatIf from packaged path
- UAT-006 Default Core+Agent plan
- UAT-007 No WSL-like actions
- UAT-008 Summary/Impact readability
- UAT-009 Contract unit tests
- UAT-010 Docs/install path correctness
- UAT-011 No invalid chat `/plugin` install path

### Tier B — Pre-publish / network packaging
Run before public publish or after packaging changes:

- UAT-012 `npx skills` discovery
- UAT-013 `npx skills add` real install product completeness

Use:

```powershell
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1 -IncludeNetwork
```

### Tier C — Machine-mutating apply
Optional and explicit only. Never CI default.

- real Core+Agent Apply on a disposable machine/profile
- record evidence into `docs/uat-real-install-configure.md`

## 5. Pass / fail policy

| Result | Meaning | Action |
|---|---|---|
| All Tier A pass | update may proceed | commit / open PR / claim local ready |
| Any Tier A fail | blocked | fix before merge/publish claim |
| Tier B fail on packaging change | blocked for publish | fix layout / reinstall validation |
| Tier C not run | normal | do not claim full machine apply unless evidence exists |

## 6. False-pass anti-patterns (forbidden)

Do not mark UAT green if you only did:

1. "skill is discoverable"
2. "source tree WhatIf works"
3. "README looks right"
4. "old local skill still responds"

Especially forbidden:

- testing only source checkout scripts while install path is incomplete
- treating residual old skill names as new skill success
- skipping install-dir file checks after packaging changes

## 7. Evidence requirements

For each regression run, capture:

1. command used
2. suite tier
3. case IDs and pass/fail
4. installed/packaged path checked
5. key file presence booleans
6. WhatIf Selected / NotSelected summary
7. git commit SHA

Use [results/TEMPLATE.md](./results/TEMPLATE.md).

For public evidence updates, sanitize personal absolute paths to:

- `%USERPROFILE%`
- repo-relative paths

## 8. Ownership checklist for agents/humans

After coding:

1. Run Tier A
2. If packaging/install docs changed, run Tier B
3. Update case status if a new failure mode was found
4. If a real false-pass happened, add a permanent case that would have caught it
5. Update lesson-learn only with durable rules, not one-off noise

## 9. Command of record

```powershell
# every update
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1

# packaging / publish
pwsh -NoLogo -NoProfile -File .\tests\uat\Invoke-UatRegression.ps1 -IncludeNetwork -Json
```

Non-zero exit code means the update is not done.
