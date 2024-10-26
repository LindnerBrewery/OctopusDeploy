function Add-TenantToTrigger {
<#
.SYNOPSIS
    Adds one or more tenants to a project trigger
.DESCRIPTION
    Adds one or more tenants to a project trigger
.EXAMPLE
    PS C:\> Add-TenantToTrigger -ProjectTrigger $trigger -Tenant $tenant
    Adds the tenant $tenant to the project trigger $trigger. $tenant can be one or more tenants.
.EXAMPLE
    PS C:\> $trigger = Get-ProjectTrigger -Project $project
    PS C:\> $tenants = Get-ProjectTenant -Project 'Project Name' -Environment Production
    PS C:\> Add-TenantToTrigger -ProjectTrigger $trigger -Tenant $tenants
    First the project trigger is retrieved. Then the tenants are retrieved that are associated with the project in the production environment. Finally the tenants are added to the project trigger.
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    [CmdletBinding()]
    param (
        [Parameter(mandatory=$true)]
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
        if (! (Test-OctopusConnection)){
            Throw "No connection to octopus server"
        }
    }

    process {
        # Get List of allowed tenants for the project
        $allowedtenants = Get-ProjectTenant -Project $Projecttrigger.projectID
        foreach ($_tenant in $Tenant) {
            if ($allowedtenants.id -notcontains $_tenant.id) {
                $err = [System.Management.Automation.ErrorRecord]::new(
                    [Octopus.Client.Exceptions.OctopusResourceNotFoundException]::new("Tenant $($_tenant.Name) is not allowed for project $($Projecttrigger.ProjectId)"),
                    'NotSpecified',
                    'NotSpecified',
                    $null
                )
                $errorDetails = [System.Management.Automation.ErrorDetails]::new("Tenant $($_tenant.Name) is not allowed for project $($Projecttrigger.ProjectId)")
                $errorDetails.RecommendedAction = 'Add the Tenant to the Project'
                $err.ErrorDetails = $errorDetails
                $PSCmdlet.WriteError($err)
            } else {
                # Add the tenant to the project trigger
                $result = $ProjectTrigger.Action.TenantIds.Add($_tenant.id)
                if ($result){
                    Write-Verbose "Added tenant $($_tenant.Name) to project trigger $($Projecttrigger.Name)"
                } else {
                    Write-Verbose "Tenant $($_tenant.Name) already added to project trigger $($Projecttrigger.Name)"
                }
            }
        }
        try {
            $repo._repository.ProjectTriggers.Modify($ProjectTrigger)
        }
        catch {
            $PSCmdlet.WriteError($_)
        }

    }

    end {}
}
