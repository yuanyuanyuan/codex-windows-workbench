# Require Confirmed State Upgrades

When a Workbench version recognizes older managed state, it must report the detected state and proposed migration or re-apply actions, take a new Installation Consent, preserve rollback backups, and be covered by an upgrade UAT from the previous release. This makes versioned state changes explicit instead of silently treating stale sentinels as permission to change a user's environment again.
