# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.0] 

### Added - Configuration as Code Runbook Support 🎉

#### Get-Runbook
- **CaC Runbook Support**: Added ability to retrieve runbooks from Configuration as Code (CaC) projects stored in Git
- **BranchName Parameter**: New optional parameter to specify Git branch (supports both canonical names like `refs/heads/main` and short names like `main`)
- **Name Parameter**: New optional parameter for filtering runbooks by exact name match across all parameter sets
- **Auto-detection**: Automatically detects and uses the default branch for CaC projects when no branch is specified
- **Enhanced Examples**: Added 8+ comprehensive examples demonstrating CaC and traditional runbook retrieval

#### Invoke-RunbookRun
- **CaC Runbook Execution**: Added support for running runbooks directly from Git branches for CaC projects
- **BranchName Parameter**: New optional parameter to specify which Git branch to run from (defaults to project's default branch)
- **Separate Parameter Sets**: Introduced distinct parameter sets (`Runbook` for CaC, `Snapshot` for traditional) for clearer intent
- **Automatic Validation**: Validates project type (CaC vs traditional) and provides clear error messages when wrong parameter set is used
- **Enhanced Tenant Validation**: Improved validation of tenant connections to project/environment before execution
- **Better Error Messages**: Custom error objects with appropriate categories for clearer troubleshooting

#### Documentation
- **Complete Help Rewrite**: Comprehensive comment-based help for both `Get-Runbook` and `Invoke-RunbookRun`
- **Real-world Examples**: Added practical examples covering CaC branches, traditional snapshots, tenanted/untenanted scenarios
- **Parameter Clarity**: Enhanced parameter descriptions explaining when and how to use each parameter
- **Notes Section**: Added detailed notes about CaC detection, branch handling, and tenant modes
- **README & Getting Started**: Updated with extensive CaC runbook examples and usage patterns

#### Infrastructure
- **GitHub Actions Workflow**: Added `release-with-github-publish.yaml` for automated releases
- **Utility Scripts**: Added helper scripts for tenant management and runbook operations
- **Build Enhancements**: Updated build process for better CI/CD integration

### Changed

#### Get-Runbook - BREAKING CHANGES
- **Parameter Name**: Renamed `RunbookID` parameter to `Id` for consistency with other functions
- **Name Matching**: Changed `-Name` parameter from wildcard support to exact match only
- **Default Behavior**: When called without parameters, now returns only non-CaC runbooks with a warning (previously returned all runbooks but couldn't access CaC runbooks)
- **Parameter Sets**: Simplified parameter sets - removed `byName` set, consolidated into `default`, `byProject`, and `byID`
- **Project Parameter**: Changed from accepting array (`ProjectResource[]`) to single object (`ProjectResource`) for clarity

#### Invoke-RunbookRun - BREAKING CHANGES
- **Default Parameter Set**: Changed from `default` to `Runbook` for better clarity
- **Parameter Separation**: `Runbook` parameter now exclusively for CaC projects; must use `RunbookSnapshot` for traditional projects
- **Auto-resolution Removed**: No longer automatically resolves published snapshots when using `Runbook` parameter
- **Error Handling**: Changed from throwing terminating errors to writing non-terminating errors for better pipeline handling

### Improved

#### Error Handling
- Replaced `throw` statements with `Get-CustomError` and `WriteError` for non-terminating errors
- Added specific exception types (ArgumentException, OctopusResourceNotFoundException, InvalidOperationException)
- Improved error categories (InvalidData, InvalidOperation) for better error handling in scripts

#### Validation
- Enhanced tenant deployment mode validation (Tenanted/Untenanted/TenantedOrUntenanted)
- Added validation for tenant connections to project/environment combinations
- Improved CaC project detection with edge case handling

#### User Experience
- Added verbose logging throughout execution flow for better debugging
- Clear warning messages when CaC runbooks won't be returned
- Helpful error messages suggesting correct parameter usage
- Better ShouldProcess messages showing branch information

### Fixed
- **Logic Error in Invoke-RunbookRun**: Corrected inverted CaC validation logic (was treating CaC projects as traditional)
- **Branch Handling**: Fixed default branch selection when multiple branches exist
- **Edge Case**: Properly handles CaC projects where individual runbooks may not be version controlled

### Removed
- **Get-Runbook**: Removed `byName` parameter set (functionality merged into other parameter sets)
- **Get-Runbook**: Removed wildcard support from `-Name` parameter
- **Documentation**: Removed incorrect/broken `.LINK` references from comment-based help

### Dependencies
- **Octopus.Client**: Updated to newer .NET Framework version for better CaC API support

### Migration Guide

#### Updating Get-Runbook Calls
```powershell
# Before
Get-Runbook -RunbookID "Runbooks-123"    # Parameter renamed
Get-Runbook -Name "Deploy*"              # Wildcards no longer supported
Get-Runbook                              # Didn't warn about missing CaC runbooks

# After
Get-Runbook -Id "Runbooks-123"           # Use -Id instead
Get-Runbook -Name "Deploy Application"   # Exact match only
Get-Runbook -Project "MyProject"         # Add -Project to get CaC runbooks
```

#### Updating Invoke-RunbookRun Calls
```powershell
# Before (auto-resolved to published snapshot)
Invoke-RunbookRun -Runbook "MyRunbook" -Environment Production

# After (explicit parameter sets)
# For CaC runbooks:
Invoke-RunbookRun -Runbook "MyRunbook" -Environment Production -BranchName "main"

# For traditional runbooks:
$snapshot = Get-RunbookSnapshot -Runbook "MyRunbook" -Latest
Invoke-RunbookRun -RunbookSnapshot $snapshot -Environment Production
```

### Technical Details

#### API Methods Used
- `$repo._repository.Projects.GetAllRunbooks($Project, $BranchCanonicalName)` - Retrieve CaC runbooks from specific branch
- `$repo._repository.Runbooks.Run($project, $branch, $slug, $parameters)` - Execute CaC runbook from Git
- `$repo._repository.RunbookRuns.Create($runbookRun)` - Execute traditional snapshot-based runbook

#### Branch Resolution Logic
1. Retrieves all branches via `Get-GitBranch`
2. If `BranchName` specified, matches by name or canonical name
3. If no branch specified, automatically uses default branch
4. Falls back to non-versioned mode for traditional projects

---

**Semver Tag**: `+semver:major`  
**Related Issues**: DNA-337  
**Breaking Changes**: Yes - see migration guide above

