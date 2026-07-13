# Verify External Bootstrap Artifacts

The public Workbench must not execute mutable remote bootstrap scripts without verification. Each externally downloaded executable script must be pinned to a reviewable version or commit, checked against a recorded SHA-256 before execution, and documented with its source and update procedure; this adds maintenance overhead but makes the default Apply path auditable.
