function Get-ProjectTenantVariable {
    <#
    .SYNOPSIS
        Returns a list of project/tenant variables
    .DESCRIPTION
        Returns a list of variables for the given tenant and project. Passing an environment is optional

    .EXAMPLE
        C:\ PS> Get-ProjectTenantVariable -Tenant XXROM001 -Project 'Install RS'
        Returns a list of project variables for the tenant XXROM001 for each connected environment
    .EXAMPLE
        C:\ Get-ProjectTenantVariable -Tenant XXROM001 -Project 'Install Solution' -Environment Development
        Returns a list of project variables for the tenant XXROM001 and development environment
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
        # variables types [System.Enum]::GetNames([Octopus.Client.Model.VariableSetContentType])

        $tenantVar = $repo._repository.Tenants.GetVariables($Tenant)
        $projVars = $tenantVar.ProjectVariables."$($project.id)"
        if (! ($Tenant.ProjectEnvironments.keys -contains $project.id)) {
            try {

                Throw "The `"$($Project.name)`" project is not connected to $($tenant.name)"
            }
            catch {
                $pscmdlet.WriteError($_)
                Return 
            }
        }
        if ($environment) {
            $enumeratedVars = $projVars.Variables.GetEnumerator() | Where-Object Key -EQ $environment.id
        } else {
            $enumeratedVars = $projVars.Variables.GetEnumerator()
        }
        if ($null -eq $enumeratedVars) {
            try {
                Throw "There are no variables in $($Environment.name)"
            }
            catch {
                $pscmdlet.WriteError($_)
                Return
            }
        }

        foreach ($envScoping in $enumeratedVars) {
            $projVars.Templates | ForEach-Object { $setvar = $envScoping.Value."$($_.id)"; [pscustomobject]@{
                    Name           = $_.name
                    Value          = if ($_.DefaultValue.IsSensitive) { "*****" }else { if ($setvar.value) { $setvar.value }else { $_.DefaultValue.value } }
                    IsDefaultValue = if ($setvar.value) { $false }else { $true }
                    Environment    = ($allEnvs | Where-Object ID -EQ $envScoping.key).name
                } }
        }


    }
    end {}

}
#Get-CommonVariable -Tenant XXROM001 -VariableSet "customer variables"
