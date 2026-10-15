function Get-ProjectTenantVariable {
    <#
    .SYNOPSIS
        Returns a list of project/tenant variables
    .DESCRIPTION
        Returns a list of variables for the given tenant and project. Passing an environment is optional.
        Every variable is returned with its unscoped value (the set unscoped value or the template default value)
        and all environment scoped values. Scoped values have the environment names in the Environment property,
        unscoped values have $null.

    .EXAMPLE
        C:\ PS> Get-ProjectTenantVariable -Tenant XXROM001 -Project 'Install RS'
        Returns all unscoped and scoped project variables for the tenant XXROM001
    .EXAMPLE
        C:\ Get-ProjectTenantVariable -Tenant XXROM001 -Project 'Install Solution' -Environment Development
        Returns the effective project variables for the tenant XXROM001 in the development environment
        (the value scoped to development, otherwise the unscoped value)
    #>

    [CmdletBinding()]
    param (

        # project you want the variables for
        [parameter(Mandatory = $true,
            ParameterSetName = "tenant")]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]$Project,

        # tenant you want the variables for
        [parameter(Mandatory = $true,
            ParameterSetName = "tenant")]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]$Tenant,

        # provide environment if you only want tenant vars for a certain environment
        [Parameter(Mandatory = $false,
            ParameterSetName = "tenant")]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]$Environment

    )
    begin {
        # testing connection to octopus
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        $allEnvs = Get-Environment
    }
    process {
        if (! ($Tenant.ProjectEnvironments.keys -contains $project.id)) {
            try {

                Throw "The `"$($Project.name)`" project is not connected to $($tenant.name)"
            }
            catch {
                $pscmdlet.WriteError($_)
                Return
            }
        }

        # templates (with default values) of the project
        $templates = $repo._repository.Tenants.GetVariables($Tenant).ProjectVariables."$($project.id)".Templates

        # all set values of the project incl. scope. An empty scope means the value is unscoped
        $getRequest = [Octopus.Client.Model.TenantVariables.GetProjectVariablesByTenantIdRequest]::new($Tenant.Id, $Tenant.SpaceId)
        $setVars = $repo._repository.TenantVariables.Get($getRequest).Variables | Where-Object ProjectId -EQ $Project.Id

        $results = foreach ($template in $templates) {
            $templateVars = @($setVars | Where-Object TemplateId -EQ $template.Id)
            $isSensitive = $template.DefaultValue.IsSensitive

            # set values (scoped and unscoped)
            foreach ($var in $templateVars) {
                $envIds = [String[]]$var.Scope.EnvironmentIds
                [pscustomobject]@{
                    Name           = $template.Name
                    Value          = if ($isSensitive) { "*****" } else { $var.Value.Value }
                    IsDefaultValue = $false
                    Environment    = if ($envIds) { [String[]]($allEnvs | Where-Object Id -In $envIds).Name } else { $null }
                    EnvironmentIds = if ($envIds) { $envIds } else { $null }
                    IsSensitive    = $isSensitive
                    TemplateId     = $template.Id
                    VariableId     = $var.Id
                }
            }

            # template default is the unscoped value if no unscoped value has been set
            if (-not ($templateVars | Where-Object { $_.Scope.EnvironmentIds.Count -eq 0 })) {
                [pscustomobject]@{
                    Name           = $template.Name
                    Value          = if ($isSensitive) { "*****" } else { $template.DefaultValue.Value }
                    IsDefaultValue = $true
                    Environment    = $null
                    EnvironmentIds = $null
                    IsSensitive    = $isSensitive
                    TemplateId     = $template.Id
                    VariableId     = $null
                }
            }
        }

        # if an environment was specified, return the effective value per variable:
        # the value whose scope contains that environment, otherwise the unscoped (set or default) value
        if ($Environment) {
            $results = $results | Group-Object Name | ForEach-Object {
                $scoped = $_.Group | Where-Object { $_.EnvironmentIds -contains $Environment.Id }
                if ($scoped) { $scoped } else { $_.Group | Where-Object { $null -eq $_.EnvironmentIds } }
            }
        }

        $results | Sort-Object Name, { $null -ne $_.Environment } | Select-Object Name, Value, IsDefaultValue, Environment

    }
    end {}

}
#Get-CommonVariable -Tenant XXROM001 -VariableSet "customer variables"
