function Remove-TenantFromTrigger {
    <#
.SYNOPSIS
    Removes one or more tenants from a project trigger
.DESCRIPTION
    Removes one or more tenants from a project trigger
.EXAMPLE
    PS C:\> Remove-TenantFromTrigger -ProjectTrigger $trigger -Tenant $tenant
    Removes the tenant $tenant from the project trigger $trigger. $tenant can be one or more tenants.
.EXAMPLE
    PS C:\> $trigger = Get-ProjectTrigger -Project $project
    PS C:\> $tenants = Get-ProjectTenant -Project 'Project Name' -Environment Production
    PS C:\> Remove-TenantFromTrigger -ProjectTrigger $trigger -Tenant $tenants
    First the project trigger is retrieved. Then the tenants are retrieved that are associated with the project in the production environment. Finally the tenants are removed from the project trigger.
.PARAMETER ProjectTrigger
    The project trigger from which the tenant(s) should be removed
.PARAMETER Tenant
    The tenant(s) that should be removed from the project trigger
#>
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $true)]
        [ProjectTriggerSingleTransformation()]
        [Octopus.Client.Model.ProjectTriggerResource]
        $ProjectTrigger,
        [Parameter(mandatory,
            valueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [TenantTransformation()]
        [Octopus.Client.Model.TenantResource[]]
        $Tenant
    )

    begin {
        try {
            ValidateConnection
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        # Remove the tenant from the project trigger
        foreach ($_tenant in $Tenant) {
            $result = $ProjectTrigger.Action.TenantIds.Remove($_tenant.id)
            if ($result) {
                Write-Verbose "Removed tenant $($_tenant.Name) from project trigger $($ProjectTrigger.Name)"
            } else {
                Write-Verbose "Tenant $($_tenant.Name) is not connected to the project trigger $($ProjectTrigger.Name)"
            }
        }
        try {
            $repo._repository.ProjectTriggers.Modify($ProjectTrigger)
        } catch {
            $PSCmdlet.WriteError($_)
        }

    }

    end {}
}
