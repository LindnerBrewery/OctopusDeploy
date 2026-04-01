function Remove-TriggerFromTenant {
    <#
.SYNOPSIS
    Removes a tenant from one or more project triggers
.DESCRIPTION
    Removes one or more tenants from a specific project trigger, or from all triggers associated with the tenant(s) when -AllTriggers is specified.
.EXAMPLE
    PS C:\> Get-ProjectTrigger -Name "nightly" | Remove-TriggerFromTenant -Tenant $tenant
    Removes the tenant from the specified project trigger piped from Get-ProjectTrigger.
.EXAMPLE
    PS C:\> Remove-TriggerFromTenant -Tenant "TenantA","TenantB" -AllTriggers
    Removes TenantA and TenantB from all project triggers they are associated with.
.EXAMPLE
    PS C:\> $trigger | Remove-TriggerFromTenant -Tenant $tenant
    Removes the tenant from the project trigger passed via the pipeline.
.PARAMETER Tenant
    One or more tenants to remove from the project trigger(s).
.PARAMETER ProjectTrigger
    The project trigger(s) from which the tenant should be removed. Mandatory unless -AllTriggers is specified. Accepts pipeline input.
.PARAMETER AllTriggers
    When specified, removes the tenant(s) from all project triggers they are associated with.
#>
    [CmdletBinding(DefaultParameterSetName = "ByTrigger")]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [TenantTransformation()]
        [Octopus.Client.Model.TenantResource[]]
        $Tenant,

        [Parameter(Mandatory = $true,
            ParameterSetName = "ByTrigger",
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ProjectTriggerTransformation()]
        [Octopus.Client.Model.ProjectTriggerResource[]]
        $ProjectTrigger,

        [Parameter(Mandatory = $true,
            ParameterSetName = "AllTriggers")]
        [switch]
        $AllTriggers
    )

    begin {
        try {
            ValidateConnection
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        foreach ($_tenant in $Tenant) {
            if ($PSCmdlet.ParameterSetName -eq "AllTriggers") {
                $triggersToProcess = Get-ProjectTrigger -Tenant $_tenant
            } else {
                $triggersToProcess = $ProjectTrigger
            }

            foreach ($trigger in $triggersToProcess) {
                $result = $trigger.Action.TenantIds.Remove($_tenant.Id)
                if (-not $result) {
                    Write-Verbose "Tenant $($_tenant.Name) is not associated with project trigger $($trigger.Name)"
                    continue
                }

                try {
                    $null = $repo._repository.ProjectTriggers.Modify($trigger)
                    Write-Verbose "Removed tenant $($_tenant.Name) from project trigger $($trigger.Name)"
                } catch {
                    $PSCmdlet.WriteError($_)
                }
            }
        }
    }

    end {}
}
