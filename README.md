# OctopusDeploy PowerShell Module

[![PowerShell Gallery](https://img.shields.io/badge/PowerShell%20Gallery-OctopusDeploy-blue.svg)](https://www.powershellgallery.com/packages/OctopusDeploy)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue.svg)](https://github.com/PowerShell/PowerShell)

<table>
    <tr>
        <td><img src="logo.png" alt="OctopusDeploy Logo" width="200" /></td>
        <td>A comprehensive PowerShell wrapper around the Octopus.Client.dll library that provides a "PowerShell-friendly" interface for interacting with Octopus Deploy instances (both cloud and on-premise).</td>
    </tr>
</table>

## 🌟 Features

- **Cross-Platform**: Works on Windows PowerShell 5.1+ and PowerShell 7+ (Windows, Linux, macOS)
- **Pipeline Support**: Most functions support pipeline input for flexible scripting
- **Argument Completion**: Tab-completion for tenants, environments, projects, and more
- **Type Transformation**: Automatic conversion of string inputs to Octopus resource objects
- **Saved Connections**: Securely store connection configurations for easy reuse
- **Configuration as Code**: Support for Git-based projects and runbooks
- **Comprehensive Coverage**: 70+ cmdlets covering all major Octopus Deploy operations

## 📦 Installation

### From PowerShell Gallery

```powershell
Install-Module -Name OctopusDeploy -Scope CurrentUser
```

### Update to Latest Version

```powershell
Update-Module -Name OctopusDeploy
```

## 🚀 Quick Start

### Connect to Your Octopus Instance

```powershell
# Option 1: Connect with credentials
$apiKey = "API-XXXXXXXXXXXXXX" | ConvertTo-SecureString -AsPlainText -Force
Connect-Octopus -OctopusServerURL "https://octopus.example.com" -ApiKey $apiKey

# Option 2: Save configuration for automatic connection
Set-ConnectionConfiguration -OctopusServerURL "https://octopus.example.com" -ApiKey $apiKey

# Test your connection
Test-OctopusConnection
```

### Basic Examples

```powershell
# Get all machines in Production environment
Get-Machine -Environment Production

# Get all tenants with a specific tag
Get-Tenant -Tag "Region/US"

# Deploy the latest release
$release = Get-Release -Project "My Project" -Latest -Channel default
Invoke-Deployment -Release $release -Environment Production -Tenant "MyTenant"

# Run a runbook
$runbook = Get-Runbook -Project "My Project" -Name "Maintenance"
$snapshot = $runbook | Get-RunbookSnapshot -Published
Invoke-RunbookRun -RunbookSnapshot $snapshot -Environment Production
```

## 📚 Function Reference

### Connection Management

| Function | Description |
|----------|-------------|
| `Connect-Octopus` | Establishes a connection to an Octopus Deploy instance |
| `Test-OctopusConnection` | Tests the current Octopus connection |
| `Get-ConnectionConfiguration` | Retrieves saved connection configuration |
| `Set-ConnectionConfiguration` | Saves connection configuration for reuse |
| `Get-CurrentSpace` | Gets the currently active Octopus space |
| `Set-Space` | Switches to a different Octopus space |
| `Get-Space` | Lists all available spaces |

### Projects & Project Groups

| Function | Description |
|----------|-------------|
| `Get-Project` | Retrieves project information |
| `Get-ProjectGroup` | Gets project groups |
| `Remove-Project` | Deletes a project |
| `Get-ProjectTrigger` | Lists project triggers |
| `Get-Channel` | Gets release channels for a project |
| `Set-ReleaseChannel` | Updates channel settings |

### Releases

| Function | Description |
|----------|-------------|
| `Get-Release` | Retrieves release information |
| `New-Release` | Creates a new release |
| `Remove-Release` | Deletes a release |
| `Get-ReleaseTemplate` | Gets the release template for a project |
| `Get-ReleasePackageVersion` | Lists package versions in a release |
| `Get-PackageVersion` | Gets available package versions |

### Deployments

| Function | Description |
|----------|-------------|
| `Invoke-Deployment` | Deploys a release to an environment |
| `Get-Deployment` | Retrieves deployment information |
| `Get-CurrentDeployment` | Gets currently active deployments |
| `Get-DeploymentPreview` | Previews a deployment without executing it |
| `Get-DeploymentProcess` | Gets the deployment process for a project |
| `Get-DeploymentProcessSteps` | Lists deployment process steps |
| `Confirm-Intervention` | Confirms a manual intervention |
| `Get-OpenIntervention` | Lists open manual interventions |

### Runbooks

| Function | Description |
|----------|-------------|
| `Get-Runbook` | Retrieves runbook information (supports CaC) |
| `Invoke-RunbookRun` | Executes a runbook |
| `Get-RunbookRun` | Gets runbook run information |
| `Get-RunbookSnapshot` | Retrieves runbook snapshots |
| `Get-RunbookRunPreview` | Previews a runbook run |
| `Get-RunbookProcess` | Gets the runbook process definition |
| `Get-RunbookProcessStep` | Lists runbook process steps |
| `Set-RunbookSettings` | Updates runbook settings |

### Machines (Targets)

| Function | Description |
|----------|-------------|
| `Get-Machine` | Lists deployment targets/machines |
| `Get-MachineRole` | Gets available machine roles |
| `Get-MachinePolicy` | Retrieves machine policies |
| `Get-MachineConnectionStatus` | Checks machine connectivity status |
| `Add-RoleToMachine` | Adds a role to a machine |
| `Remove-RoleFromMachine` | Removes a role from a machine |
| `Set-Machine` | Updates machine properties |
| `Copy-MachinePolicy` | Copies a machine policy |

### Tenants

| Function | Description |
|----------|-------------|
| `Get-Tenant` | Retrieves tenant information |
| `New-Tenant` | Creates a new tenant |
| `Remove-Tenant` | Deletes a tenant |
| `Get-TenantProject` | Lists projects associated with a tenant |
| `Add-ProjectToTenant` | Connects a project to a tenant |
| `Remove-ProjectFromTenant` | Disconnects a project from a tenant |
| `Add-TagToTenant` | Adds a tag to a tenant |
| `Remove-TagFromTenant` | Removes a tag from a tenant |
| `Get-TenantMachineCount` | Counts machines per tenant |
| `Get-ProjectTenant` | Gets tenants for a project |
| `Add-TenantToTrigger` | Adds a tenant to a project trigger |
| `Remove-TenantFromTrigger` | Removes a tenant from a trigger |

### Variables

| Function | Description |
|----------|-------------|
| `Get-ProjectVariable` | Gets project variables |
| `Get-ProjectTenantVariable` | Gets project template variables for a tenant |
| `Set-ProjectTenantVariable` | Sets project template variables |
| `Get-CommonVariable` | Gets common (library) variables |
| `Get-CommonTenantVariable` | Gets common tenant-specific variables |
| `Set-CommonTenantVariable` | Sets common tenant variables |
| `Get-VariableSet` | Lists variable sets |
| `Get-VariableSnapshot` | Gets variable snapshot for a release |

### Environments & Lifecycles

| Function | Description |
|----------|-------------|
| `Get-Environment` | Lists environments |
| `Get-Lifecycle` | Gets lifecycle information |

### Tags

| Function | Description |
|----------|-------------|
| `Get-TagSet` | Lists tag sets and tags |

### Tasks

| Function | Description |
|----------|-------------|
| `Get-Task` | Retrieves task information |
| `Get-TaskResult` | Gets task execution results |
| `Get-TaskStatus` | Checks task status |
| `Get-TaskType` | Lists available task types |
| `Stop-Task` | Cancels a running task |
| `Invoke-TaskScript` | Executes a script in task context |

### Artifacts

| Function | Description |
|----------|-------------|
| `Get-Artifact` | Lists artifacts |
| `Get-ArtifactContent` | Retrieves artifact content |
| `Save-Artifact` | Saves an artifact to disk |
| `Remove-Artifact` | Deletes an artifact |

### Git Integration (Configuration as Code)

| Function | Description |
|----------|-------------|
| `Get-GitBranch` | Lists Git branches for a CaC project |
| `Get-GitReference` | Gets Git references |
| `Get-SourceScriptsInGit` | Retrieves scripts from Git repository |

### Script Modules

| Function | Description |
|----------|-------------|
| `Get-ScriptModule` | Lists script modules |

### Advanced

| Function | Description |
|----------|-------------|
| `Get-OctopusRepositoryObject` | Generic method to retrieve any repository object |

## 💡 Common Use Cases

### Working with Tenants

```powershell
# Get all tenants in a specific region
Get-Tenant -Tag "Region/US" | Select-Object Name, Id

# Count machines per tenant in production
Get-Tenant | Get-TenantMachineCount -Environment Production -MachineRole DatabaseServer

# Add a project to multiple tenants
$tenants = Get-Tenant -Tag "Rolloutgroups/Wave-1"
foreach ($tenant in $tenants) {
    Add-ProjectToTenant -Project "My App" -Tenant $tenant -Environment Development, Production
}
```

### Managing Variables

```powershell
# Get project variables
Get-ProjectVariable -Project "My Project"

# Set multiple tenant variables at once
$variables = @{
    'DatabaseServer' = 'sql.example.com'
    'DatabasePort' = '1433'
    'DatabaseName' = 'MyDatabase'
}
Set-CommonTenantVariable -Tenant "MyTenant" -VariableSet "Customer Variables" -VariableHash $variables

# Clear a tenant variable (reset to default)
Set-CommonTenantVariable -Tenant "MyTenant" -VariableSet "Customer Variables" -Name "DatabaseServer" -Value ""
```

### Release Management

```powershell
# Create a release with specific package versions
$packages = @{
    'MyApp.Web' = '1.2.3'
    'MyApp.Api' = '1.2.4'
}
New-Release -Project "My Application" -Package $packages -Version "1.2.3"

# Get the latest release and deploy it
$release = Get-Release -Project "My App" -Latest -Channel default
$tenants = Get-Tenant -Tag "Rolloutgroups/Wave-1"
foreach ($tenant in $tenants) {
    Invoke-Deployment -Release $release -Environment Production -Tenant $tenant
}
```

### Runbook Automation

```powershell
# Run maintenance runbook across all tenants
$runbook = Get-Runbook -Project "Infrastructure" -Name "Database Backup"
$snapshot = $runbook | Get-RunbookSnapshot -Published
$tenants = Get-Tenant

foreach ($tenant in $tenants) {
    Invoke-RunbookRun -RunbookSnapshot $snapshot -Environment Production -Tenant $tenant
}
```

### Machine Management

```powershell
# Find all machines with a specific role
Get-Machine -Role "DatabaseServer" | Select-Object Name, HealthStatus, Roles

# Add a role to all machines in an environment
Get-Machine -Environment Production | Add-RoleToMachine -Role "WebServer"

# Get machines for a specific tenant and environment
Get-Machine -Tenant "MyTenant" -Environment Production | 
    Select-Object Name, @{N='Environment'; E={(Get-Environment -ID $_.EnvironmentIds).Name}}
```

## 🔧 Advanced Features

### Pipeline Support

Most functions support PowerShell pipeline for flexible scripting:

```powershell
# Chain commands together
Get-Project -Name "My App" | 
    Get-Release -Latest | 
    Get-ReleasePackageVersion

# Process multiple items
Get-Tenant -Tag "Region/US" | 
    Get-TenantMachineCount -Environment Production |
    Sort-Object Count -Descending
```

### Argument Completion

The module provides tab-completion for many parameters:

```powershell
Get-Machine -Tenant <TAB>        # Completes with tenant names
Get-Project -Name <TAB>          # Completes with project names
Get-Environment <TAB>            # Completes with environment names
```

### Working with Multiple Spaces

```powershell
# Check current space
Get-CurrentSpace

# Switch spaces
Set-Space -Name "DevOps"

# List all spaces
Get-Space
```

### Configuration as Code Support

```powershell
# Get runbooks from a specific Git branch
Get-Runbook -Project "My CaC Project" -BranchName "feature/new-deployment"

# Get available branches
Get-GitBranch -Project "My CaC Project"

# Get source scripts from Git
Get-SourceScriptsInGit -Project "My CaC Project"
```

## 📖 Documentation

- **[Getting Started Guide](GettingStarted2.md)** - Comprehensive tutorial with step-by-step examples
- **Built-in Help** - All functions include detailed help:
  ```powershell
  Get-Help Get-Machine -Full
  Get-Help Invoke-Deployment -Examples
  ```

## 🤝 Contributing

Contributions are welcome! This module is developed "as is" and functions are added as needed. Please note that breaking changes may occur in future versions.

## �📄 License

Copyright (c) 2025 Emrys MacInally. All rights reserved.

## 🔗 Links

- **GitHub Repository**: [https://github.com/LindnerBrewery/OctopusDeploy](https://github.com/LindnerBrewery/OctopusDeploy)
- **Octopus Deploy**: [https://octopus.com](https://octopus.com)
- **Octopus.Client Documentation**: [https://octopus.com/docs/octopus-rest-api/octopus.client](https://octopus.com/docs/octopus-rest-api/octopus.client)

## ⚠️ Important Notes

- This module wraps the Octopus.Client.dll library
- Some features may not be fully implemented
- Breaking changes may occur in future versions as the module evolves
- Always test in a non-production environment first
- Secure your API keys properly using SecureString

## 🆘 Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/LindnerBrewery/OctopusDeploy).

## 🙏 Special Thanks

Special thanks to **[Marvin Becker](https://github.com/Marvin-Becker)** for his valuable contributions to this project. His work has helped improve and extend the functionality of this module.