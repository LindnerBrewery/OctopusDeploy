# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A PowerShell module (`OctopusDeploy`) that wraps the `Octopus.Client.dll` .NET library to provide a PowerShell-native interface for Octopus Deploy. The module supports both Windows PowerShell 5.1 and PowerShell 7+ (Windows, Linux, macOS).

## Build and Test Commands

All build tasks run through `build.ps1` (which orchestrates psake via `psakeFile.ps1`):

```powershell
# Bootstrap dependencies (first time setup — installs PowerShellBuild, PSDepend, copies Octopus.Client.dll)
./build.ps1 -Bootstrap

# Full build: lint + tests
./build.ps1 -Task default

# Build + publish to PSGallery
./build.ps1 -Task release

# List all available build tasks
./build.ps1 -Help
```

Run Pester tests directly (requires module to be importable):

```powershell
Invoke-Pester ./tests/
```

Lint with PSScriptAnalyzer:

```powershell
Invoke-ScriptAnalyzer -Path ./OctopusDeploy/ -Recurse
```

## Repository Layout

```
OctopusDeploy/
  OctopusDeploy.psm1          # Module root: dot-sources all Public/ and Private/, calls Connect-Octopus on import
  OctopusDeploy.psd1          # Module manifest
  startup.ps1                 # Loaded first (ScriptsToProcess): loads Octopus.Client.dll from Lib/
  Classes/
    Classes.psm1              # PowerShell classes: Repository, TaskResult, ProjectDeploymentObject, etc.
    TransformerClasses.psm1   # ArgumentTransformation attributes (auto-convert strings -> Octopus objects)
  Public/                     # ~80 exported cmdlets (one function per file)
  Private/                    # Internal helpers: ValidateConnection, ArgumentCompleters, SetSpace, etc.
  Lib/
    Desktop/Octopus.Client.dll  # For Windows PowerShell 5.1 (net48)
    Core/Octopus.Client.dll     # For PowerShell 7+ (netstandard2.0)
  Formats/                    # .ps1xml format files for custom output types
tests/
  mock.tests.ps1              # Pester test file
psakeFile.ps1                 # Build task definitions
build.ps1                     # Build entry point
dependencies/                 # Vendored build tools (psake, PSScriptAnalyzer, Pester, BuildHelpers)
```

## Architecture

### Connection and State

The module uses a module-scoped variable `$repo` (a `Repository` class instance defined in `Classes/Classes.psm1`) to hold the live connection. `Connect-Octopus` populates `$repo`. Every public cmdlet calls `ValidateConnection` at the start of its `begin` block, which throws a terminating error if `$repo` is not set.

The `Repository` class wraps `Octopus.Client.OctopusRepository` and `OctopusClient`, and handles both SecureString and plain-text API keys.

### String-to-Object Auto-Conversion

`TransformerClasses.psm1` defines `[ArgumentTransformation]` attributes (e.g., `[TenantTransformation()]`, `[ProjectSingleTransformation()]`). These are applied to cmdlet parameters so callers can pass either a resource name/ID string or an already-fetched object. The transformation automatically calls the appropriate `Get-*` cmdlet to resolve strings.

### Argument Completion

`Private/ArgumentCompleters.ps1` registers tab-completion scriptblocks for common parameters (`Tenant`, `Project`, `Environment`, `Role`, `Tag`, `Machine`, etc.) across all cmdlets that have matching parameter names, using `Register-ArgumentCompleter`.

### Module Loading Order

1. `startup.ps1` loads the correct `Octopus.Client.dll` based on `$PSVersionTable.PSEdition`
2. `OctopusDeploy.psm1` imports `Classes.psm1` and `TransformerClasses.psm1` via `using module`, then dot-sources all `Public/*.ps1` and `Private/*.ps1`
3. `Connect-Octopus` is called automatically on import if a saved config exists

### Versioning

Versions are managed by `dotnet-gitversion` (GitVersion). The `UpdateVersion` psake task reads the computed version and writes it into the staged `.psd1` before publishing.

## Adding New Cmdlets

1. Create a file in `OctopusDeploy/Public/<Verb-Noun>.ps1` with a single function.
2. Follow the existing pattern: `begin {}` block calls `ValidateConnection`, then uses `$repo._repository.<Repository>.*` to interact with the Octopus API.
3. Apply `[ArgumentTransformation]` attributes from `TransformerClasses.psm1` to parameters that accept Octopus resource objects.
4. Argument completers for standard parameter names (`Tenant`, `Project`, `Environment`, etc.) are registered automatically — no extra work needed for those.
5. The function is exported automatically (the `.psm1` exports all names in `$public.Basename`).
