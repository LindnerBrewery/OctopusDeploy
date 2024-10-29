# OctopusDeploy

Powershell wrapper around octoclient.dll to help  interacting with any octopus instance. Cloud or on-premise

## Overview

This module will let you use the octoclient in a more 'PowerShelly' way. This module is "as is" and there can be breaking changes in future versions.

## Installation

```powershell
Install-Module -Name OctopusDeploy
```

## Getting started

### Connecting to an octopus instance

#### Connecting without saving your configuration

```powershell
Connect-Octopus -OctopusServerURL https://octopus.instance.com -ApiKey $env:OctoApiKey
```

#### Connecting with saved configuration

Save configuration by using Set-ConnectionConfiguration

```powershell
Set-ConnectionConfiguration -OctopusServerURL https://octopus.instance.com -ApiKey ("API-XXXXXXXXXXXXXX" | ConvertTo-SecureString -AsPlainText -Force)
```

Using Connect-Octopus is not necessary. Module will connect automatically to the server as soon as the module is used

### Getting a list of machines

```powershell
Get-Machine -Tenant Tenantname -Environment QA | Select name, roles
```
```
Name        Roles
----        -----
Machine1    {default, fax.service, RISDatabaseServer, UpdateAgent.service}
Machine2    {default}
Machine3    {default}

```
### Get a list of machines in a certain environment and with a given role



### Count machines with a specific role per tenant

```powershell
$allTenants = Get-Tenant
$allTenants | Get-TenantMachine -Environment Production -MachineRole RISDatabaseServer | Sort-Object count -Descending
```
```
Tenant                              Machines                             Count
------                              --------                             -----
TenantName1                         Octopus.Client.Model.MachineResource     1
TenantName2                         Octopus.Client.Model.MachineResource     1
TenantName3                         Octopus.Client.Model.MachineResource     1
TenantName4                         Octopus.Client.Model.MachineResource     1
TenantName5                         Octopus.Client.Model.MachineResource     1
TenantName6                         Octopus.Client.Model.MachineResource     1
TenantName7                         Octopus.Client.Model.MachineResource     1
```

### Getting a list of tenants with a certain tag

#### Finding tags

```powershell
Get-TagSet -CanonicalTagName -Name Rolloutgroups
```

#### Finding tenant with tag

```powershell
Get-Tenant -TenantTag Rolloutgroups/DB-1
```
