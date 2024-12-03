function Remove-ProjectFromTenant {
    <#
.SYNOPSIS
    Removes a project from one or many tenants for one or more or all environments
.DESCRIPTION
    Removes a project from one or many tenants for one or more or all environments
.EXAMPLE
    PS C:\> Add-ProjectToTenant -Project "monitoring" -Tenant "DEKAE99Z" -Environment "Production"
    Explanation of what the example doesAdd-ProjectToTenant -Project 'SQLAny RIS DB Maintenance' -Environment Production
.EXAMPLE
    PS C:\> get-Tenant | Add-ProjectToTenant -Project 'Portal' -Environment Production
    Portal project in production environment will be removed from all tenants
.EXAMPLE
    PS C:\> get-Tenant | Add-ProjectToTenant -Project 'Portal'
    Portal project will be completely removed from all tenants, no matter which environment is connected
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory)]
        [ValidateNotNullOrEmpty()]
        [ProjectTransformation()]
        [Octopus.Client.Model.ProjectResource[]]
        $Project,
        [Parameter(mandatory,
            ValueFromPipelineByPropertyName = $true,
            valueFromPipeline = $true)]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [TenantTransformation()]
        [Octopus.Client.Model.TenantResource[]]
        $Tenant,
        [Parameter(mandatory = $false)]
        [EnvironmentTransformation()]
        [Octopus.Client.Model.EnvironmentResource[]]
        $Environment

    )
    begin {
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {


        foreach ($_Tenant in $Tenant) {

            $tenantEditor = $repo._repository.Tenants.CreateOrModify($_tenant.name)
            foreach ($_project in $project) {
                $changes = 0
                if ($environment) {
                    if ($tenantEditor.Instance.ProjectEnvironments[$_project.id]) {
                        foreach ($_environment in $environment) {
                            # check if environment to remove is part of the connection and remove
                            if ($tenantEditor.Instance.ProjectEnvironments[$_project.id] -contains $_environment.Id) {
                                $tenantEditor.Instance.ProjectEnvironments[$_project.id].remove($_environment.Id) | Out-Null
                                $message = "Removing {2} from {0}/{1}" -f $_Tenant.name, $_project.Name, $_environment.name
                                Write-Verbose $message
                                $changes ++
                            } else {
                                $message = "{2} is connceted NOT to {0}/{1}" -f $_Tenant.name, $_project.Name, $_environment.name
                                Write-Verbose $message
                            }
                        }
                        # check if project has any environments connected. if not delete project
                        if ([string]::IsNullOrEmpty($tenantEditor.Instance.ProjectEnvironments[$_project.id])) {
                            $tenantEditor.Instance.ProjectEnvironments.Remove($_project.id) | Out-Null
                            $message = "Removing Project {1} from {0} because it there is no connection to any environment" -f $_Tenant.name, $_project.Name
                            Write-Verbose $message
                            # increment counter to make sure changes are saved
                            $changes ++

                        }


                    } else {
                        $message = "{1} not connected to {0} in {2}" -f $_Tenant.name, $_project.Name, ($environment.name -join ", ")
                        Write-Verbose $message

                    }
                } else {
                    $tenantEditor = $repo._repository.Tenants.CreateOrModify($_tenant.name)
                    foreach ($_project in $project) {

                        # check if project is connected to tenant
                        if ($tenantEditor.Instance.ProjectEnvironments.Keys -contains $_project.id) {
                            # remove project
                            $tenantEditor.Instance.ProjectEnvironments.Remove($_project.id) | Out-Null
                            $message = "Removing Project {1} from {0}" -f $_Tenant.name, $_project.Name
                            Write-Verbose $message
                            # increment counter to make sure changes are saved
                            $changes ++
                        } else {
                            $message = "{1} not connected to {0}" -f $_Tenant.name, $_project.Name, ($environment.name -join ", ")
                            Write-Verbose $message
                        }
                        #$tenantEditor.ConnectToProjectAndEnvironments($_project, $environment) | Out-Null
                        # only save if changes have been madeq

                    }
                }

                # check if project is connected to tenant

                #$tenantEditor.ConnectToProjectAndEnvironments($_project, $environment) | Out-Null
                # only save if changes have been made
                if ($changes -ne 0) {
                    $tenantEditor.Save() | Out-Null
                }
                Write-Host "Saving $changes changes to $($_tenant.name)"
            }
        }

    }
    end {}
}
