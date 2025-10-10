# Getting Started with OctopusDeploy PowerShell Module

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Initial Setup](#initial-setup)
5. [Core Concepts](#core-concepts)
6. [Basic Operations](#basic-operations)
7. [Working with Tenants](#working-with-tenants)
8. [Managing Machines](#managing-machines)
9. [Projects and Releases](#projects-and-releases)
10. [Deployments](#deployments)
11. [Runbooks](#runbooks)
12. [Variables Management](#variables-management)
13. [Advanced Topics](#advanced-topics)
14. [Best Practices](#best-practices)
15. [Troubleshooting](#troubleshooting)

---

## Introduction

The OctopusDeploy PowerShell module is a comprehensive wrapper around the Octopus.Client.dll library that provides a PowerShell-friendly interface for interacting with Octopus Deploy. Whether you're managing deployments, configuring tenants, or automating runbooks, this module makes it easy to script and automate your Octopus Deploy operations.

### Key Features

- **Cross-Platform**: Works on Windows PowerShell 5.1+ and PowerShell 7+ (Windows, Linux, macOS)
- **Pipeline-Friendly**: Supports PowerShell pipeline for flexible scripting
- **Auto-Completion**: Tab-completion for tenants, projects, environments, and more
- **Saved Credentials**: Securely store connection configurations
- **Git Support**: Full support for Configuration as Code (CaC) projects

---

## Prerequisites

- **PowerShell**: Windows PowerShell 5.1 or PowerShell 7+
- **Octopus Deploy Instance**: Access to an Octopus Deploy server (cloud or on-premise)
- **API Key**: An API key from your Octopus Deploy instance

### Getting an API Key

1. Log in to your Octopus Deploy web portal
2. Click on your profile (top right)
3. Select **My API Keys**
4. Click **New API Key**
5. Give it a purpose and click **Generate New**
6. Copy and securely store your API key

---

## Installation

### Install from PowerShell Gallery

```powershell
# Install for current user (recommended)
Install-Module -Name OctopusDeploy -Scope CurrentUser

# Or install for all users (requires admin)
Install-Module -Name OctopusDeploy -Scope AllUsers
```

### Update to Latest Version

```powershell
Update-Module -Name OctopusDeploy
```

### Verify Installation

```powershell
# Check installed version
Get-Module -Name OctopusDeploy -ListAvailable

# Import the module
Import-Module OctopusDeploy

# List available commands
Get-Command -Module OctopusDeploy
```

---

## Initial Setup

### Method 1: Quick Connect (Temporary Session)

For one-time operations or testing, you can connect directly without saving credentials:

```powershell
# Convert your API key to a SecureString
$apiKey = "API-XXXXXXXXXXXXXX" | ConvertTo-SecureString -AsPlainText -Force

# Connect to your Octopus instance
Connect-Octopus -OctopusServerURL "https://octopus.example.com" -ApiKey $apiKey
```

### Method 2: Save Configuration (Recommended)

For regular use, save your connection configuration securely:

```powershell
# Store credentials securely
$apiKey = "API-XXXXXXXXXXXXXX" | ConvertTo-SecureString -AsPlainText -Force
Set-ConnectionConfiguration -OctopusServerURL "https://octopus.example.com" -ApiKey $apiKey

# Module will auto-connect when you use any command
# No need to manually call Connect-Octopus
```

### Verify Your Connection

```powershell
# Test the connection
Test-OctopusConnection

# View current configuration
Get-ConnectionConfiguration

# Check current space
Get-CurrentSpace
```

### Working with Multiple Spaces

If your Octopus instance uses spaces, you can switch between them:

```powershell
# List all available spaces
Get-Space

# Switch to a different space
Set-Space -Name "DevOps"

# Check current space
Get-CurrentSpace
```

---

## Core Concepts

### Understanding Octopus Deploy Objects

The module works with several key Octopus Deploy objects:

- **Projects**: Applications or services you deploy
- **Releases**: Versioned snapshots of your project
- **Deployments**: The act of deploying a release to an environment
- **Runbooks**: Operational procedures (like backups, health checks)
- **Environments**: Deployment stages (Development, Test, Production)
- **Tenants**: Customers or instances of your application
- **Machines**: Deployment targets (servers, cloud instances)
- **Variables**: Configuration values for projects and tenants

### Pipeline Support

Most functions support the PowerShell pipeline, allowing you to chain commands:

```powershell
# Chain commands together
Get-Project -Name "My App" | Get-Release -Latest

# Process multiple items
Get-Tenant -Tag "Region/US" | Get-TenantMachineCount -Environment Production
```

### Type Transformations

The module automatically converts strings to Octopus resource objects:

```powershell
# These are equivalent:
Get-Machine -Tenant "MyTenant"
Get-Machine -Tenant (Get-Tenant -Name "MyTenant")
```

---

## Basic Operations

### Exploring Your Octopus Instance

Start by exploring what's available in your Octopus instance:

```powershell
# List all environments
Get-Environment | Select-Object Name, Id

# List all projects
Get-Project | Select-Object Name, ProjectGroupId

# List all tenants
Get-Tenant | Select-Object Name, Id

# List all machines
Get-Machine | Select-Object Name, HealthStatus, Roles
```

### Getting Help

Every function includes comprehensive help documentation:

```powershell
# View basic help
Get-Help Get-Machine

# View detailed help with parameter descriptions
Get-Help Get-Machine -Full

# View examples only
Get-Help Get-Machine -Examples

# List all parameters
Get-Help Get-Machine | Select-Object -ExpandProperty Parameters
```

### Using Tab Completion

The module provides intelligent tab completion:

```powershell
# Press TAB to cycle through available options
Get-Machine -Tenant <TAB>
Get-Project -Name <TAB>
Get-Environment <TAB>
```

---

## Working with Tenants

### Listing Tenants

```powershell
# Get all tenants
Get-Tenant

# Get a specific tenant by name
Get-Tenant -Name "MyTenant"

# Get tenant by ID
Get-Tenant -ID "Tenants-123"
```

### Finding Tenants by Tags

Tags are powerful for organizing tenants:

```powershell
# List all tag sets and their tags
Get-TagSet

# Get canonical tag names (easier to use in queries)
Get-TagSet -CanonicalTagName

# Find tenants with a specific tag
Get-Tenant -Tag "Region/US"
Get-Tenant -Tag "Rolloutgroups/Wave-1"

# Find tenants with multiple tags
Get-Tenant -Tag "Region/US", "Type/Production"
```

### Managing Tenant Tags

```powershell
# Add a tag to a tenant
Add-TagToTenant -Tenant "MyTenant" -Tag "Region/EU"

# Remove a tag from a tenant
Remove-TagFromTenant -Tenant "MyTenant" -Tag "Region/US"

# Using pipeline
Get-Tenant -Name "MyTenant" | Add-TagToTenant -Tag "Priority/High"
```

### Tenant-Project Relationships

```powershell
# Get all projects associated with a tenant
Get-TenantProject -Tenant "MyTenant"

# Connect a project to a tenant
Add-ProjectToTenant -Project "My Application" -Tenant "MyTenant" -Environment Development, Production

# Connect multiple projects
$projects = @("App1", "App2", "App3")
foreach ($project in $projects) {
    Add-ProjectToTenant -Project $project -Tenant "MyTenant" -Environment Development, Test, Production
}

# Disconnect a project from a tenant
Remove-ProjectFromTenant -Project "My Application" -Tenant "MyTenant"
```

### Counting Tenant Machines

Useful for infrastructure audits:

```powershell
# Count all machines for all tenants
Get-TenantMachineCount

# Count machines in a specific environment
Get-TenantMachineCount -Environment Production

# Count machines with a specific role
Get-TenantMachineCount -Environment Production -MachineRole "DatabaseServer"

# Count for specific tenants
Get-Tenant -Tag "Region/US" | 
    Get-TenantMachineCount -Environment Production -MachineRole "WebServer" |
    Sort-Object Count -Descending
```

### Creating and Removing Tenants

```powershell
# Create a new tenant
New-Tenant -Name "NewCustomer" -Tag "Region/US", "Type/Trial"

# Remove a tenant
Remove-Tenant -Tenant "OldCustomer"
```

---

## Managing Machines

### Listing Machines

```powershell
# Get all machines
Get-Machine

# Get machines by name
Get-Machine -Name "web-server-01"

# Get machines by ID
Get-Machine -ID "Machines-123"

# Get machines in an environment
Get-Machine -Environment Production

# Get machines with a specific role
Get-Machine -Role "WebServer"

# Get machines for a tenant
Get-Machine -Tenant "MyTenant"

# Combine filters
Get-Machine -Tenant "MyTenant" -Environment Production -Role "DatabaseServer"
```

### Working with Machine Roles

```powershell
# List all available roles
Get-MachineRole

# Add a role to a machine
Add-RoleToMachine -Machine "web-server-01" -Role "WebServer"

# Add multiple roles at once
Add-RoleToMachine -Machine "app-server-01" -Role "WebServer", "ApiServer"

# Remove a role from a machine
Remove-RoleFromMachine -Machine "web-server-01" -Role "WebServer"

# Using pipeline
Get-Machine -Name "web-server-01" | Add-RoleToMachine -Role "DatabaseServer"
```

### Checking Machine Status

```powershell
# Get machines with health status
Get-Machine | Select-Object Name, HealthStatus, StatusSummary

# Get only healthy machines
Get-Machine -Healthy | Select-Object Name, Roles

# Check machine connectivity
Get-MachineConnectionStatus -Machine "web-server-01"
```

### Machine Policies

```powershell
# List all machine policies
Get-MachinePolicy

# Get policy for a specific machine
$machine = Get-Machine -Name "web-server-01"
Get-MachinePolicy -ID $machine.MachinePolicyId

# Copy a machine policy
Copy-MachinePolicy -SourcePolicy "Default Policy" -NewPolicyName "Custom Policy"
```

### Advanced Machine Queries

```powershell
# Get machines with environment names (calculated property)
Get-Machine -Tenant "MyTenant" | 
    Select-Object Name, @{
        Name = 'Environments'
        Expression = { (Get-Environment -ID $_.EnvironmentIds).Name -join ', ' }
    }

# Count machines by role
Get-Machine | 
    ForEach-Object { $_.Roles } | 
    Group-Object | 
    Select-Object Name, Count | 
    Sort-Object Count -Descending
```

---

## Projects and Releases

### Working with Projects

```powershell
# List all projects
Get-Project

# Get a specific project
Get-Project -Name "My Application"

# Get project by ID
Get-Project -ID "Projects-123"

# Get projects with their groups
Get-Project | 
    Select-Object Name, @{
        Name = 'ProjectGroup'
        Expression = { (Get-ProjectGroup -ID $_.ProjectGroupId).Name }
    }
```

### Project Groups

```powershell
# List all project groups
Get-ProjectGroup

# Get specific group
Get-ProjectGroup -Name "Web Applications"
```

### Release Channels

```powershell
# Get channels for a project
Get-Channel -Project "My Application"

# Get a specific channel
Get-Channel -Project "My Application" -Name "default"
```

### Working with Releases

```powershell
# Get all releases for a project
Get-Release -Project "My Application"

# Get the latest release
Get-Release -Project "My Application" -Latest

# Get latest release for a specific channel
Get-Release -Project "My Application" -Latest -Channel "default"

# Get a specific release by version
Get-Release -Project "My Application" -Version "1.2.3"
```

### Creating Releases

```powershell
# Create a release with default package versions
New-Release -Project "My Application"

# Create a release with specific package versions
$packages = @{
    'MyApp.Web'     = '1.2.3'
    'MyApp.Api'     = '1.2.4'
    'MyApp.Worker'  = '1.2.3'
}
New-Release -Project "My Application" -Package $packages

# Create a release with a specific version number
New-Release -Project "My Application" -Version "1.2.3" -Package $packages

# Create release for a specific channel
New-Release -Project "My Application" -Channel "Hotfix" -Package $packages
```

### Release Package Information

```powershell
# Get package versions in a release
$release = Get-Release -Project "My Application" -Latest
Get-ReleasePackageVersion -Release $release

# Using pipeline
Get-Release -Project "My Application" -Latest | Get-ReleasePackageVersion

# Get available package versions
Get-PackageVersion -Project "My Application" -PackageID "MyApp.Web"
```

### Release Templates

```powershell
# Get the release template (shows what packages are available)
Get-ReleaseTemplate -Project "My Application"

# Get template for specific channel
Get-ReleaseTemplate -Project "My Application" -Channel "Hotfix"
```

### Removing Releases

```powershell
# Remove a specific release
Remove-Release -Project "My Application" -Version "1.0.0"

# Remove using pipeline
Get-Release -Project "My Application" -Version "1.0.0" | Remove-Release
```

---

## Deployments

### Viewing Deployments

```powershell
# Get all deployments for a release
$release = Get-Release -Project "My Application" -Latest
Get-Deployment -Release $release

# Get current/active deployments
Get-CurrentDeployment

# Get deployment for specific tenant
Get-Deployment -Release $release -Tenant "MyTenant"
```

### Deployment Preview

Preview what will happen without executing:

```powershell
# Preview a deployment
$release = Get-Release -Project "My Application" -Latest
Get-DeploymentPreview -Release $release -Environment Production -Tenant "MyTenant"
```

### Executing Deployments

```powershell
# Basic deployment
$release = Get-Release -Project "My Application" -Latest
Invoke-Deployment -Release $release -Environment Production -Tenant "MyTenant"

# Deployment with form values (prompted variables)
$formValues = @{
    'Variable1' = 'Value1'
    'Variable2' = 'Value2'
}
Invoke-Deployment -Release $release -Environment Production -Tenant "MyTenant" -FormValue $formValues

# Schedule a deployment for later
Invoke-Deployment -Release $release -Environment Production -Tenant "MyTenant" -QueueTime (Get-Date).AddHours(2)

# Skip specific steps
Invoke-Deployment -Release $release -Environment Production -Tenant "MyTenant" -StepIdToExclude "Steps-123", "Steps-456"

# Preview deployment with -WhatIf
Invoke-Deployment -Release $release -Environment Production -Tenant "MyTenant" -WhatIf
```

### Batch Deployments

Deploy to multiple tenants:

```powershell
# Deploy to all tenants in a rollout group
$release = Get-Release -Project "My Application" -Latest
$tenants = Get-Tenant -Tag "Rolloutgroups/Wave-1"

foreach ($tenant in $tenants) {
    Write-Host "Deploying to $($tenant.Name)..."
    Invoke-Deployment -Release $release -Environment Production -Tenant $tenant
    Start-Sleep -Seconds 10  # Stagger deployments
}
```

### Manual Interventions

```powershell
# Get open interventions
Get-OpenIntervention

# Get interventions for a specific environment
Get-OpenIntervention -Environment Production

# Confirm an intervention
Confirm-Intervention -Intervention "ServerTasks-123" -Notes "Approved by admin"
```

### Deployment Process

```powershell
# Get deployment process for a project
Get-DeploymentProcess -Project "My Application"

# Get deployment process steps
Get-DeploymentProcessSteps -Project "My Application"
```

---

## Runbooks

Runbooks are operational procedures like database backups, health checks, or maintenance tasks.

### Listing Runbooks

```powershell
# Get all runbooks (non-CaC only)
Get-Runbook

# Get runbooks for a specific project
Get-Runbook -Project "My Application"

# Get a specific runbook
Get-Runbook -Project "My Application" -Name "Database Backup"
```

### Configuration as Code Runbooks

For projects stored in Git (Configuration as Code):

```powershell
# Get runbooks from default branch
Get-Runbook -Project "My CaC Project"

# Get runbooks from a specific branch
Get-Runbook -Project "My CaC Project" -BranchName "main"
Get-Runbook -Project "My CaC Project" -BranchName "feature/new-process"

# List available branches
Get-GitBranch -Project "My CaC Project"
```

### Runbook Snapshots

Snapshots are versions of runbooks, similar to releases:

```powershell
# Get all snapshots for a runbook
$runbook = Get-Runbook -Project "My Application" -Name "Maintenance"
Get-RunbookSnapshot -Runbook $runbook

# Get the published snapshot
Get-RunbookSnapshot -Runbook $runbook -Published

# Using pipeline
Get-Runbook -Project "My Application" -Name "Maintenance" | 
    Get-RunbookSnapshot -Published
```

### Executing Runbooks

```powershell
# Execute a runbook
$runbook = Get-Runbook -Project "My Application" -Name "Database Backup"
$snapshot = $runbook | Get-RunbookSnapshot -Published
Invoke-RunbookRun -RunbookSnapshot $snapshot -Environment Production -Tenant "MyTenant"

# Execute with form values
$formValues = @{
    'BackupPath' = '/backups/daily'
    'RetentionDays' = '30'
}
Invoke-RunbookRun -RunbookSnapshot $snapshot -Environment Production -Tenant "MyTenant" -FormValue $formValues

# Preview runbook execution
Get-RunbookRunPreview -RunbookSnapshot $snapshot -Environment Production -Tenant "MyTenant"
```

### Runbook Runs

```powershell
# Get runbook run information
Get-RunbookRun -Runbook $runbook

# Get specific runbook run
Get-RunbookRun -ID "RunbookRuns-123"
```

### Batch Runbook Execution

Run a runbook across multiple tenants:

```powershell
# Execute maintenance across all production tenants
$runbook = Get-Runbook -Project "Infrastructure" -Name "Health Check"
$snapshot = $runbook | Get-RunbookSnapshot -Published
$tenants = Get-Tenant -Tag "Environment/Production"

foreach ($tenant in $tenants) {
    Write-Host "Running health check on $($tenant.Name)..."
    Invoke-RunbookRun -RunbookSnapshot $snapshot -Environment Production -Tenant $tenant
}
```

### Runbook Process

```powershell
# Get runbook process definition
Get-RunbookProcess -Runbook $runbook

# Get runbook process steps
Get-RunbookProcessStep -Runbook $runbook
```

---

## Variables Management

Octopus Deploy has four types of variables:

1. **Project Variables**: Variables defined at the project level
2. **Project Tenant Variables**: Project template variables with tenant-specific values
3. **Common Variables**: Library variable sets
4. **Common Tenant Variables**: Library variable sets with tenant-specific values

### Project Variables

```powershell
# Get all project variables
Get-ProjectVariable -Project "My Application"

# Variables are returned as VariableSetResource objects
$vars = Get-ProjectVariable -Project "My Application"
$vars.Variables | Select-Object Name, Value, Scope
```

### Project Tenant Variables

These are template variables that each tenant can provide values for:

```powershell
# Get project tenant variables
Get-ProjectTenantVariable -Project "My Application" -Tenant "MyTenant" -Environment Production

# Set a project tenant variable
Set-ProjectTenantVariable -Project "My Application" -Tenant "MyTenant" -Variable "ConnectionString" -Value "Server=..."
```

### Common Variables (Library Variable Sets)

```powershell
# List all variable sets
Get-VariableSet

# Get variables from a specific set
Get-CommonVariable -VariableSet "Shared Configuration"

# View the variables
$vars = Get-CommonVariable -VariableSet "Shared Configuration"
$vars.Variables | Select-Object Name, Value
```

### Common Tenant Variables

These are library variables with tenant-specific values:

```powershell
# Get common tenant variables
Get-CommonTenantVariable -VariableSet "Customer Variables" -Tenant "MyTenant"

# Set a single variable
Set-CommonTenantVariable -Tenant "MyTenant" -VariableSet "Customer Variables" -Name "DatabaseServer" -Value "sql.example.com"

# Set variable with environment scope
$environment = Get-Environment -Name "Production"
Set-CommonTenantVariable -Tenant "MyTenant" -VariableSet "Customer Variables" -Name "DatabaseType" -Value "PostgreSQL" -Environment $environment

# Reset a variable (clear tenant-specific value)
Set-CommonTenantVariable -Tenant "MyTenant" -VariableSet "Customer Variables" -Name "DatabaseServer" -Value ""

# Set multiple variables at once using a hashtable
$variables = @{
    'DatabaseServer' = 'sql.example.com'
    'DatabasePort'   = '1433'
    'DatabaseName'   = 'MyDatabase'
    'DatabaseUser'   = 'app_user'
}
Set-CommonTenantVariable -Tenant "MyTenant" -VariableSet "Customer Variables" -VariableHash $variables
```

### Variable Snapshots

```powershell
# Get variable snapshot for a release
$release = Get-Release -Project "My Application" -Latest
Get-VariableSnapshot -Release $release
```

### Bulk Variable Updates

Update variables for multiple tenants:

```powershell
# Update database server for all US tenants
$tenants = Get-Tenant -Tag "Region/US"
foreach ($tenant in $tenants) {
    Set-CommonTenantVariable -Tenant $tenant -VariableSet "Customer Variables" -Name "DatabaseServer" -Value "us-sql.example.com"
}
```

---

## Advanced Topics

### Working with Tasks

```powershell
# Get all tasks
Get-Task

# Get tasks by type
Get-TaskType  # List available task types
Get-Task -Type "Deploy"

# Get task details
Get-Task -ID "ServerTasks-123"

# Get task results
Get-TaskResult -Task "ServerTasks-123"

# Check task status
Get-TaskStatus -Task "ServerTasks-123"

# Cancel a running task
Stop-Task -Task "ServerTasks-123"
```

### Working with Artifacts

```powershell
# List all artifacts
Get-Artifact

# Get artifacts for a specific task
Get-Artifact -Task "ServerTasks-123"

# Get artifact content
$artifact = Get-Artifact | Select-Object -First 1
Get-ArtifactContent -Artifact $artifact -Encoding UTF8

# Save artifact to disk
Save-Artifact -Artifact $artifact -Path "C:\Downloads\artifact.txt"

# Remove an artifact
Remove-Artifact -Artifact $artifact
```

### Git Integration (Configuration as Code)

```powershell
# List Git branches
Get-GitBranch -Project "My CaC Project"

# Get Git references
Get-GitReference -Project "My CaC Project"

# Get source scripts from Git
Get-SourceScriptsInGit -Project "My CaC Project" -BranchName "main"
```

### Script Modules

```powershell
# List all script modules
Get-ScriptModule

# Get specific script module
Get-ScriptModule -Name "Common Functions"
```

### Lifecycles

```powershell
# Get all lifecycles
Get-Lifecycle

# Get specific lifecycle
Get-Lifecycle -Name "Default Lifecycle"
```

### Project Triggers

```powershell
# Get triggers for a project
Get-ProjectTrigger -Project "My Application"

# Add tenant to trigger
Add-TenantToTrigger -Trigger "ProjectTriggers-123" -Tenant "MyTenant"

# Remove tenant from trigger
Remove-TenantFromTrigger -Trigger "ProjectTriggers-123" -Tenant "MyTenant"
```

### Generic Repository Access

For advanced scenarios not covered by specific functions:

```powershell
# Access any repository object directly
Get-OctopusRepositoryObject -ObjectType "Projects" -ObjectId "Projects-123"
```

---

## Best Practices

### Security

```powershell
# Always use SecureString for API keys
$apiKey = Read-Host "Enter API Key" -AsSecureString
Set-ConnectionConfiguration -OctopusServerURL "https://octopus.example.com" -ApiKey $apiKey

# Never hardcode API keys in scripts
# Use environment variables or secure vaults
$apiKey = $env:OCTOPUS_API_KEY | ConvertTo-SecureString -AsPlainText -Force
```

### Error Handling

```powershell
# Use try-catch for robust scripts
try {
    $release = Get-Release -Project "My Application" -Latest
    Invoke-Deployment -Release $release -Environment Production -Tenant "MyTenant"
}
catch {
    Write-Error "Deployment failed: $_"
    # Log error, send notification, etc.
}
```

### Testing

```powershell
# Use -WhatIf for safe testing
Invoke-Deployment -Release $release -Environment Production -Tenant "MyTenant" -WhatIf

# Preview deployments first
Get-DeploymentPreview -Release $release -Environment Production -Tenant "MyTenant"
```

### Performance

```powershell
# Use specific filters to reduce data transfer
Get-Machine -Tenant "MyTenant" -Environment Production  # Better
Get-Machine | Where-Object { ... }  # Slower for large datasets

# Cache frequently used objects
$allTenants = Get-Tenant  # Get once
$allTenants | ForEach-Object { ... }  # Reuse
```

### Scripting Patterns

```powershell
# Use splatting for complex parameters
$deployParams = @{
    Release     = $release
    Environment = 'Production'
    Tenant      = 'MyTenant'
    FormValue   = $formValues
}
Invoke-Deployment @deployParams

# Use progress indicators for long operations
$tenants = Get-Tenant
$i = 0
foreach ($tenant in $tenants) {
    $i++
    Write-Progress -Activity "Processing Tenants" -Status $tenant.Name -PercentComplete (($i / $tenants.Count) * 100)
    # Do work...
}
```

---

## Troubleshooting

### Connection Issues

```powershell
# Verify connection
Test-OctopusConnection

# Check configuration
Get-ConnectionConfiguration

# Reconnect manually
Connect-Octopus -OctopusServerURL "https://octopus.example.com" -ApiKey $apiKey

# Verify API key has correct permissions
# Check in Octopus web portal: Configuration → Users → API Keys
```

### Space Issues

```powershell
# Check current space
Get-CurrentSpace

# List available spaces
Get-Space

# Switch to correct space
Set-Space -Name "Correct Space Name"
```

### Function Not Found

```powershell
# Ensure module is loaded
Get-Module OctopusDeploy

# Reimport module
Remove-Module OctopusDeploy
Import-Module OctopusDeploy

# Check available functions
Get-Command -Module OctopusDeploy
```

### Object Not Found Errors

```powershell
# Verify object exists
Get-Project | Where-Object Name -Like "*MyApp*"
Get-Tenant | Where-Object Name -Like "*Customer*"

# Check you're in the right space
Get-CurrentSpace

# Use exact names (case-sensitive in some contexts)
```

### Debugging

```powershell
# Enable verbose output
$VerbosePreference = 'Continue'
Get-Machine -Tenant "MyTenant" -Verbose

# View detailed error information
$Error[0] | Format-List * -Force

# Use built-in help
Get-Help Get-Machine -Full
```

### Common Errors

**Error: "Connection not established"**
- Solution: Run `Connect-Octopus` or verify saved configuration

**Error: "Object not found"**
- Solution: Check object name, verify space, ensure object exists

**Error: "Access denied"**
- Solution: Verify API key has sufficient permissions

**Error: "Variable set not found"**
- Solution: Use `Get-VariableSet` to find the correct name

---

## Additional Resources

### Built-in Help

Every function includes comprehensive documentation:

```powershell
# View help
Get-Help <Function-Name>

# View examples
Get-Help <Function-Name> -Examples

# View detailed help
Get-Help <Function-Name> -Full

# View online help (if available)
Get-Help <Function-Name> -Online
```

### Useful Links

- **Module GitHub**: [https://github.com/LindnerBrewery/OctopusDeploy](https://github.com/LindnerBrewery/OctopusDeploy)
- **Octopus Deploy Documentation**: [https://octopus.com/docs](https://octopus.com/docs)
- **Octopus.Client Documentation**: [https://octopus.com/docs/octopus-rest-api/octopus.client](https://octopus.com/docs/octopus-rest-api/octopus.client)
- **Octopus REST API**: [https://octopus.com/docs/octopus-rest-api](https://octopus.com/docs/octopus-rest-api)

### Community and Support

For issues, questions, or contributions:
- Open an issue on [GitHub](https://github.com/LindnerBrewery/OctopusDeploy/issues)
- Review existing issues and discussions
- Contribute improvements via pull requests

---

## Quick Reference

### Connection

```powershell
Connect-Octopus -OctopusServerURL "URL" -ApiKey $key
Set-ConnectionConfiguration -OctopusServerURL "URL" -ApiKey $key
Test-OctopusConnection
Get-CurrentSpace
Set-Space -Name "SpaceName"
```

### Common Queries

```powershell
Get-Project
Get-Tenant -Tag "Tag/Value"
Get-Machine -Environment Production
Get-Release -Project "Name" -Latest
Get-Runbook -Project "Name"
```

### Deployments & Runbooks

```powershell
Invoke-Deployment -Release $r -Environment Production -Tenant "Name"
Invoke-RunbookRun -RunbookSnapshot $s -Environment Production
```

### Variables

```powershell
Set-CommonTenantVariable -Tenant "Name" -VariableSet "Set" -Name "Var" -Value "Val"
Get-ProjectVariable -Project "Name"
```

---

## Conclusion

You now have a comprehensive understanding of the OctopusDeploy PowerShell module. Start with simple queries to explore your Octopus instance, then progress to automating deployments and managing complex multi-tenant scenarios.

Remember:
- Use built-in help: `Get-Help <Function-Name>`
- Test with `-WhatIf` and previews
- Leverage pipelines for efficient scripting
- Save your configuration for convenience
- Handle errors gracefully in production scripts

Happy automating! 🚀
