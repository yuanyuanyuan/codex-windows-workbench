# Declare Host Prerequisites Before the Workbench

The Workbench runtime remains PowerShell 7-only. Release and installation documentation declare PowerShell 7 and winget/App Installer as host prerequisites and direct users without winget to the official App Installer flow. This avoids claiming a bootstrapper that the packaged product does not provide while retaining winget as the only package-management path.
