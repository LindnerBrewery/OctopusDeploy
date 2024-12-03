<#
.SYNOPSIS
    Returns the tenants of a project
.DESCRIPTION
    Returns the tenants of a project depending on the environment
.EXAMPLE
    PS C:\> Get-ProjectTenants -Project "Install Project"
    Lists all Tenants of the project "Install Project" in any environment
.EXAMPLE
    PS C:\> Get-ProjectTenants -Project "Install Project" -Environment "Test"
    Lists all Tenants of the project "Install Project" in the environment "Test"
.PARAMETER Project
    The project to get the tenants from
.PARAMETER Environment
    The environment to get the tenants from
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Get-ProjectTenant {
    [CmdletBinding()]
    param (
        # Project to get the tenants from
        [Parameter(mandatory)]
        [ValidateNotNullOrEmpty()]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]
        $Project,
        # Environment to get the tenants from
        [Parameter(mandatory=$false)]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]
        $Environment

    )

    begin {
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        $tenant = Get-Tenant
    }

    process {
        $tenant | ForEach-Object {
            foreach ($pe in $_.projectenvironments.getenumerator()) {
                if ($Environment) {

                    if ($pe.Key -eq $project.Id -And $pe.Value -contains $Environment.Id){
                        $_
                    }
                }else {
                    if ($pe.Key -eq $project.Id){
                        $_
                    }
                }
            }
        }
    }

    end {}
}
