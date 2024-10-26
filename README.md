# OctoDeploy

Powershell wrapper around octoclient.dll to help  interacting with any octopus instance. Cloud or on-premise

## Overview

This module will let you use the octoclient in a more 'powershelly' way. This module is "as is" and there can be breaking changes in future versions.

## Installation

```powershell
Install-Module -Name OctoDeploy
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
Get-Machine -Tenant XXROM001 -Environment QA | Select name, roles
```
```
Name                     Roles
----                     -----
DEKAE99Y-SEUAS01-VM-DE   {default, fax.service, RISDatabaseServer, UpdateAgent.service}
DEKAE99Z-OCTONEXT05-VM-D {default}
DEKAE99Z-OCTONEXT06-VM-D {default}

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
ATATT01R                            Octopus.Client.Model.MachineResource     1
DELIG01R                            Octopus.Client.Model.MachineResource     1
DELGN01R                            Octopus.Client.Model.MachineResource     1
DELEJ02R                            Octopus.Client.Model.MachineResource     1
DELEJ01R                            Octopus.Client.Model.MachineResource     1
DELEB01R                            Octopus.Client.Model.MachineResource     1
DELDH01R                            Octopus.Client.Model.MachineResource     1
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


