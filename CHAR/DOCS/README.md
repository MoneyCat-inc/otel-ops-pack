# CHAR/DOCS - Published Documentation Mirror (Read Only)

This directory is a publish mirror of /docs.
Do not edit files here directly.

Source of truth: /docs
To change content, edit /docs and run the publish step:

    pwsh -File BRAV/SCPT/publish-docs-mirror.ps1 -DryRun   # preview
    pwsh -File BRAV/SCPT/publish-docs-mirror.ps1           # publish

The script mirrors the git-tracked contents of /docs into CHAR/DOCS/docs/
exactly (copies changes, deletes removed files) and touches nothing else in
CHAR/DOCS/. It is manual by design (docs/PURPOSE.md: no new recurring
writers). Before 2026-08-29 this "publish step" was referenced but never
existed, so the mirror drifted unconditionally — found and fixed in the
audit close-out (ECRR_BOSSCAT_AUDIT_DRIFT_20260829.md).
