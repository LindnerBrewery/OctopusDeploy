function Add-ProjectToTenant {
    <#
.SYNOPSIS
    Adds a project to one or more tenants for an environment
.DESCRIPTION
    Adds a single project to an array of tenants and environments.
.EXAMPLE
    PS C:\> Add-ProjectToTenant -Project "monitoring" -Tenant "DEKAE99Z" -Environment "Production"
    Adds the project to as single tenant in the production environments
.EXAMPLE
    PS C:\> get-Tenant | Add-ProjectToTenant -Project 'Portal' -Environment Production
    Adds the 'portal' project to all tenants in production and environment
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
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
        [Parameter(mandatory)]
        [EnvironmentTransformation()]
        [Octopus.Client.Model.EnvironmentResource[]]
        $Environment

    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {
        #$project = Get-Project -ID $ProjectID
        #$environment = Get-Environment -ID $EnvironmentID
        foreach ($_Tenant in $Tenant) {

            $tenantEditor = $repo._repository.Tenants.CreateOrModify($_tenant.name)
            foreach ($_project in $project) {
                $changes = 0
                if ($tenantEditor.Instance.ProjectEnvironments[$_project.id]) {
                    foreach ($_environment in $environment) {
                        if ($tenantEditor.Instance.ProjectEnvironments[$_project.id] -notcontains $_environment.Id) {
                            $tenantEditor.Instance.ProjectEnvironments[$_project.id].add($_environment.Id) | Out-Null
                            $message = "Adding {1} in {2} to {0}" -f $_Tenant.name, $_project.Name, $_environment.name
                            Write-Verbose $message
                            $changes ++
                        } else {
                            $message = "{0} ist allready connceted to {1} in {2}" -f $_Tenant.name, $_project.Name, $_environment.name
                            Write-Verbose $message
                        }
                    }

                } else {
                    $tenantEditor.Instance.ProjectEnvironments[$_project.id] = [string[]]$environment.Id
                    $message = "Adding {1} in {2} to {0}" -f $_Tenant.name, $_project.Name, ($environment.name -join ", ")
                    $changes ++
                    Write-Verbose $message
                }
                #$tenantEditor.ConnectToProjectAndEnvironments($_project, $environment) | Out-Null

                $tenantEditor.Save() | Out-Null
                Write-Host "Saving $changes changes to $($_tenant.name)"
            }
        }

    }
    end {}
}


<#
param argument complete class
https://youtu.be/LMw_mfYRHYI?t=2558

param tranformator
https://youtu.be/LMw_mfYRHYI?t=2866


$acScriptEnvironment = {
    param($commandName, $parameterName, $stringMatch)
    OctoDeploy\Get-Environment | Where-Object name -Like $stringMatch* | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}
Register-ArgumentCompleter -CommandName Add-ProjectToTenant -ParameterName Environment -ScriptBlock $acScriptEnvironment

$acScriptProject = {
    param($commandName, $parameterName, $stringMatch)
    OctoDeploy\Get-Project | Where-Object name -Like $stringMatch* | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}
Register-ArgumentCompleter -CommandName Add-ProjectToTenant -ParameterName Project -ScriptBlock $acScriptProject

$acScriptTenant = {
    param($commandName, $parameterName, $stringMatch)
    OctoDeploy\get-Tenant | Where-Object name -Like $stringMatch* | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}
Register-ArgumentCompleter -CommandName Add-ProjectToTenant -ParameterName Tenant -ScriptBlock  $acScriptTenant

#>
