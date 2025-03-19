function Remove-TenantFromTrigger {
    <#
.SYNOPSIS
    Removes one tenant from project triggers
.DESCRIPTION
    Removes one tenant from project triggers
.EXAMPLE
    PS C:\> Remove-TenantFromTrigger -ProjectTrigger $trigger -Tenant $tenant
    Removes the tenant $tenant from the project trigger $trigger. $tenant can be a single tenant.
.PARAMETER ProjectTrigger
    The project trigger(s) from which the tenant should be removed
.PARAMETER Tenant
    The tenant that should be removed from the project trigger
#>
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $true)]
        [ProjectTriggerTransformation()]
        [Octopus.Client.Model.ProjectTriggerResource[]]
        $ProjectTrigger,
        [Parameter(mandatory,
            valueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]
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
        foreach ($trigger in $ProjectTrigger) {
            $result = $trigger.Action.TenantIds.Remove($Tenant.id)
            if (-not $result) {
                Write-Verbose "Tenant $($Tenant.Name) is not connected to the project trigger $($trigger.Name)"
                continue
            }

            try {
                $null = $repo._repository.ProjectTriggers.Modify($trigger)
                Write-Verbose "Removed tenant $($Tenant.Name) from project trigger $($trigger.Name)"
            } catch {
                $PSCmdlet.WriteError($_)
            }
        }

    }

    end {}
}
