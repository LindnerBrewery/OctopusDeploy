<#
.SYNOPSIS
    Get the project tenant variables of a project for all tenants in one API call
.DESCRIPTION
    Uses TenantVariables.GetAll() from Octopus.Client (legacy /tenantvariables/all?projectId=... endpoint)
    to fetch the project variables of every tenant connected to the project with a single request,
    instead of calling Get-ProjectTenantVariable once per tenant.

    Returns one object per tenant, environment and variable template:
    - Tenant, Environment, Name, Value (sensitive values masked as *****)
    - IsDefault: $true if no value is set and the template default value is used

    Note: the legacy endpoint returns values flattened per environment. It cannot tell whether a value
    was set unscoped or scoped to an environment; use Get-ProjectTenantVariable for that.
.EXAMPLE
    PS C:\> . .\Get-projectTenantVariableforAllTenants.ps1
    PS C:\> $rsVars | Where-Object Name -eq 'DatabaseType' | Format-Table
    Lists the DatabaseType value of every tenant per environment for the 'Install RS' project
#>

# Ensure we're connected to Octopus
# Connect-Octopus -Server "your-server" -ApiKey "your-api-key" -Space "your-space"

$project = Get-Project -Name 'Install RS'
$repo = get-octopusRepositoryObject                                                             
                                          
$all = $repo._repository.TenantVariables.GetAll($project)

$envs = Get-Environment
$rsVars = foreach ($t in $all) {
    $p = $t.ProjectVariables[$project.Id]
    foreach ($envId in $p.Variables.Keys) {
        foreach ($tpl in $p.Templates) {
            $v = $p.Variables[$envId][$tpl.Id]
            [pscustomobject]@{
                Tenant      = $t.TenantName
                Environment = ($envs | ? Id -eq $envId).Name
                Name        = $tpl.Name
                Value       = if ($v) { if ($v.IsSensitive) { '*****' } else { $v.Value } } else { $tpl.DefaultValue.Value }
                IsDefault   = -not $v
            }
        }
    }
}