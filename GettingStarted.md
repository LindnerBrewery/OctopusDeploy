Introduction to OctopusDeploy pwsh module
---
## Getting Started
OctopusDeploy is a cross-platform module to interact with octopus deploy. It can be used with Windows PowerShell > 5.1 or PowerShell > 7 on Windows, Linux or Mac.
The module is not feature complete, and commands are added as needed. Downwards compatibility cannot be guarantied.

---
##### Install module

```powershell
Install-Module OctopusDeploy -Scope CurrentUser -Repository PSGallery-group
```

_or_

```Powershell
Update-Module OctopusDeploy
```
---
##### Connect to an octopus instance
You can connect to an on premise or cloud instance of octopus
```Powershell
$ApiKey = ($APIKEY | ConvertTo-SecureString -AsPlainText -Force)
Connect-Octopus -OctopusServerURL https://octo.medavis.com -ApiKey $ApiKey
```

You can save your connection configuration
```Powershell
Set-ConnectionConfiguration -OctopusServerURL https://octo.medavis.com -ApiKey $ApiKey
```
_or_
___
```Powershell
Set-ConnectionConfiguration -OctopusServerURL https://octo.medavis.com -ApiKey ($APIKEY | ConvertTo-SecureString -AsPlainText -Force)
```
---
##### Check saved configuration

```powershell
Get-ConnectionConfiguration
```
There is no need for connect-octopus with saved config as it happens implicitly when importing module or using any cmdlet
___
#####  Checking connection

```powershell
Test-OctopusConnection
```
---
##### Check current space and switching space
```powershell
Get-CurrentSpace
Set-Space -Name DevOps
Set-Space -Name default
```
---
## Getting machine information
---
##### Get a list of all machine

```powershell
Get-Machine
```
---
##### Getting machine from tenant with argument completion and transformation
```powershell
Get-Machine -Tenant XXROM001 -Environment Development
```
---
##### Piping to function and using help
```powershell
Get-Help Get-machine -Full | Select-Object -ExpandProperty parameters
'xxrom001' | Get-Machine | Select-Object name, environmentids
```
---
##### More complex scenarios
Machine object only contain IDs to other objects
```Powershell
'xxrom001' | Get-Machine | Select-Object name, environmentids
```
---
Use calculated properties to get environment name
```powershell
'xxrom001' | Get-Machine | Select-Object name, environmentids, @{n = 'EnvironmentName'; e = { (Get-Environment -ID $_.environmentids).name.tostring() } }
```
---
##### Get a list of machine roles and use them to query machines
```powershell
Get-MachineRole
```

```powershell
Get-Machine -Role RISDatabaseServer
Get-Machine -Role RISDatabaseServer | Select-Object name, role, healthstatus
```
---
## Getting tenant information
---
### Get a list of all tenants
```powershell
Get-Tenant
```
---
### Use tags to filter tenants
---
#### Find existing tags
```powershell
Get-TagSet
Get-TagSet -CanonicalTagName
```
Canonical tag names are simple text representations of TagSets and Tag and can be used to query tenants.
---
#### Filtering tenants with tags
```powershell
Get-Tenant -Tag Rolloutgroups/Portal-1 | Select-Object name, tagset
```
---
### Getting a list of tenants and count their machines
---
#### Getting all with no filter

```powershell
Get-TenantMachineCount
```
---
#### Adding filters
```powershell
Get-TenantMachineCount -Environment Production -MachineRole RISDatabaseServer
```
---
#### Like most functions, pipeline is supported
```powershell
Get-Help Get-TenantMachineCount | Select-Object -ExpandProperty parameters
```
#### Getting non "X" tenants
```powershell
Get-Tenant | Where-Object name -notlike "X*" | Get-TenantMachineCount -Environment Production -MachineRole RISDatabaseServer
```
#### Counting tenant machines depending on tags
```powershell
Get-Tenant -Tag Region/AT | Get-TenantMachineCount -Environment Test -MachineRole RisdatabseServer
```

### All functions have help and examples
```powershell
Get-Help Get-Machine
```
```powershell
Get-Help Get-Machine -Examples
```
```powerhsell
Get-Help Get-Machine -Full
```

## Projects
### Simple list of project names
```powershell
Get-Project | Select-Object name
```

### Releases
#### Get projects releases
```powershell
Get-Project -Name 'Install Solution' | Get-Release
```

#### How many releases?
```powershell
(Get-Project -Name 'Install Solution' | Get-Release).count
```

#### Whats my newest release?
```powershell
Get-Project -Name 'Install Solution' | Get-Release -Latest
```

##### Make sure you have the right release channel
```powershell
Get-Channel -Project 'Install Solution'
Get-Project -Name 'Install Solution' | Get-Release -Latest -Channel default
```

#### Get a list of all packages and version in a release
```powershell
$release = Get-Release -Project 'Install Solution' -Channel default -Latest
Get-ReleasePackageVersion -Release $release
$release | Get-ReleasePackageVersion
```
There is no autocompleter for releases as the list would be to long

## Variables
### Getting the four different types of variables
#### Project vars
```powershell
Get-ProjectVariable -Project "install solution"
```

#### Project template variables
```powershell
Get-ProjectTenantVariable -Project "install RS" -Tenant XXROM001 -Environment Production
```

#### Common variables
For common variables, you need to know the variable's set name. Without you will get all common.
```powershell
Get-CommonVariable -VariableSet
```

```powershell
(Get-VariableSet).name
```

```powershell
Get-CommonVariable -VariableSet 'Customer Variables'
```
Variableset paramerter can autocomplete

#### Common tenant variables
Just like common variables, common tenant variables also expect a variable set name
```powershell
Get-CommonTenantVariable -VariableSet 'Customer Variables' -Tenant ATATT01R
```

### Writing variables
current only common tenant variables are supported
#### Writing a single common tenant variable

```powershell
Get-CommonTenantVariable -VariableSet 'Customer Variables' -Tenant XXROM001
```

```powershell
Set-CommonTenantVariable -Tenant XXROM001 -VariableSet 'Customer Variables' -Name Unlocode -Value "bla"
```

#### Removing a single common tenant variable
```powershell
Set-CommonTenantVariable -Tenant XXROM001 -VariableSet 'Customer Variables' -Name Unlocode -Value ""
```

#### Writing a multiple variables using a hashtable
```powershell
$params = @{Unlocode                     = "bla1"
    'Server.Ris.Database.IP[Production]' = "blup1"
    'Password.User.medavis'              = "XXXXPA1XXXX"
}
Set-CommonTenantVariable -Tenant XXROM001 -VariableSet 'Customer Variables' -VariableHash $params
```

## Adding/removing roles

#### Adding role to machine
```powershell
Get-Machine -name XXROM001-SESUP001-VM-DE | Add-RoleToMachine -Role riscomserver
```
```powershell
Add-RoleToMachine -Role default -Machine XXROM001-SESUP001-VM-DE
```
#### Remove roles from machine
```powershell
Get-Machine -name XXROM001-SESUP001-VM-DE | Remove-RoleFromMachine -Role riscomserver, default
```
## Adding/removing tags to tenants
```powerhsell
Add-TagToTenant -Tenant XXROM001 -Tag Region/CH
```
```powershell
Get-Tenant -name XXROM001 | Remove-TagFromTenant -Tag Region/CH
```

## Adding/removing projects to tenant
*__There will be a function to list all projects associated with a tenant (Get-TenantProject)__*
You can add multiple projects to multiple tenants in multiple environments
```powershell
Add-ProjectToTenant -Project 'Install Solution' -Environment Development, Test, Production  -Tenant XXROMDOC
```
```powershell
Add-ProjectToTenant -Project 'Install Solution' -Environment Development,Test -Tenant XXROMDOC -Verbose
# or
Remove-ProjectFromTenant -Project 'Install Solution' -Tenant XXROMDOC -Verbose
```

## Deployments
#### List of all deployment of a defined release
```Powershell
Get-Deployment -Release (Get-Release -Project 'Configure RIS Server' -Latest -Channel default)
```
#### Invoke a deployment
```Powershell
$release = Get-release -Project 'Test Project' -Latest
$tenant = Get-Tenant -name XXROM001
Invoke-Deployment -Release $release -Environment Development -Tenant $tenant -QueueTime (get-date).AddMinutes(3)
```
## Runbooks
Getting a list of all runbooks
```Powershell
 Get-Runbook | select name, projectid | Sort-Object
```
With project names
```Powershell
Get-Runbook | select name, @{n="projectName";e={Get-Project -id $_.ProjectId | Select-Object -ExpandProperty name}}
```

Get all runbooks of a project
```Powershell
Get-Runbook -Project 'Test Project'
```
Runbooks are like projects and runbooksnapshots are like releases
```Powershell
Get-Runbook -Project 'Test Project' -name artifact | Get-RunbookSnapshot | select name, Assembled
```
You can filter for the currently published runbooksnapshot
```Powershell
Get-Runbook -Project 'Test Project' -name artifact | Get-RunbookSnapshot -Published | select name, Assembled
```
#### invoke a runbook
```Powershell
Invoke-RunbookRun -RunbookSnapshot "RunbookSnapshots-1541" -Tenant XXROM001  -Environment Development
```
## Artifacts
#### Getting artifacts and contents
```powershell
# List of all artifacts
Get-Artifact
```
Getting all artifacts regarding a runbook run
```Powershell
Get-Runbook -Name artifact | get-RunbookSnapshot  | Get-Artifact
```
Retrieving the content of an artifact
```Powershell
Get-Artifact | Select-Object -First 1 | Get-ArtifactContent -Encoding Unicode
```

#### Deleting artifacts
```Powershell
Remove-Artifact -Artifact "Artifacts-105802"
```
```Powershell
Get-Artifact | Select-Object -First 1 | Remove-Artifact
```
