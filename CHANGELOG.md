# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Fixed

- **Set-ProjectTenantVariable**: Refactored variable template retrieval to cache the result outside loops, significantly improving performance by reducing redundant API calls. Fixed an issue where sensitive variables were not properly set by correctly passing the `IsSensitive` flag from the template to the PropertyValueResource.
- **Get-ProjectTenantVariable**: Fixed `IsDefaultValue` logic to correctly determine when a variable is using its default value, accounting for variables with empty string values that should still be considered as set (not default).

### Improved

- **Connect-Octopus**: Added connection confirmation message displaying the server URL, user, and space after successful connection for better user feedback.

## [2.2.0] - 2026-01-09

### Added

- **Get-CurrentTenantDeployment**: New function that returns the latest successful deployments for a tenant, grouped by project and environment. Accepts mandatory `Tenant` parameter and optional `Environment` parameter. Parses task descriptions to extract project name, release version, and deployment date. Results are sorted by environment (A-Z) then by date (newest first).

### Fixed

- **Get-Tenant**: Now writes an error when a tenant is not found instead of silently returning nothing, allowing users to handle the error appropriately.
- **TenantSingleTransformation**: Improved feedback when tenant is not found, providing clearer error messages.
- **Set-ConnectionConfiguration**: Fixed an issue on macOS where the configuration folder was not created, resulting in an error when saving connection settings.

## [2.1.0] - 2025-12-19

### Improved

- **Get-Task**: Added support for retrieving tasks from `DeploymentResource` objects.
- **Get-CommonTenantVariable**: Added support for filtering by Environment, made VariableSet optional to retrieve all variable sets, and improved output to include scope and variable set name.
- **Set-CommonTenantVariable**: Enhanced to handle scoped common tenant variables with environment scoping support. Intelligently handles scope conflicts (disjoint, overlapping, equal, contained), supports setting multiple variables at once via hashtable, includes comprehensive verbose logging, and detailed comment-based help with multiple examples.

## [2.0.0] - Configuration as Code Runbook Support 🎉

### Added

- **Get-Runbook**: Configuration as Code (CaC) runbook support with optional `BranchName` parameter for Git-based projects. Auto-detects default branch when not specified.
- **Invoke-RunbookRun**: Execute CaC runbooks directly from Git branches with new `BranchName` parameter. Enhanced tenant and project type validation.

### Changed - BREAKING

- **Get-Runbook**: 
  - Renamed parameter `RunbookID` → `Id`
  - Changed `-Name` from wildcard to exact match only
  - Simplified parameter sets (removed `byName`)
  - `Project` parameter now accepts single object instead of array
- **Invoke-RunbookRun**:
  - Separate parameter sets for CaC (`Runbook`) vs traditional (`RunbookSnapshot`) projects
  - No longer auto-resolves published snapshots
  - Changed to non-terminating errors for better pipeline handling

### Migration Guide

```powershell
# Get-Runbook
Get-Runbook -RunbookID "Runbooks-123"  # Before
Get-Runbook -Id "Runbooks-123"         # After

# Invoke-RunbookRun (CaC projects)
Invoke-RunbookRun -Runbook $runbook -Environment Production -BranchName "main"

# Invoke-RunbookRun (Traditional projects)
$snapshot = Get-RunbookSnapshot -Runbook $runbook -Latest
Invoke-RunbookRun -RunbookSnapshot $snapshot -Environment Production
```

### Improved

- Enhanced error handling with specific exception types and non-terminating errors
- Comprehensive verbose logging for debugging
- Updated comment-based help with extensive examples

### Fixed

- Corrected inverted CaC validation logic in Invoke-RunbookRun
- Fixed default branch selection for multiple branches

**Related Issues**: DNA-337
