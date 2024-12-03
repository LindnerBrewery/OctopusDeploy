function Get-ProjectVariable {
    <#
    .SYNOPSIS
        Returns a list of project variables
    .DESCRIPTION
        Returns a list of project variable for a given project. These are variables that are only connected to a project and not to a tenant
        .EXAMPLE
        C:\ PS> Get-ProjectVariable -Project 'Install Solution'
        Returns a list of project variables bound to the project 'Install Solution'
    #>

    [CmdletBinding()]
    param (

        # project you want the variables for
        [parameter(Mandatory = $true,
            ParameterSetName = "project")]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]$Project
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
        if (Get-GitReference -Project $Project) {
            $projgitVars = $repo._repository.variableSets.Get($Project,(Get-GitReference -Project $Project).gitref)
            $projgitVars.Variables | ForEach-Object { [VariableSetVar]::new($_) }
        }
        $projVars = $repo._repository.variableSets.Get($project.VariableSetId)
        $projVars.Variables | ForEach-Object { [VariableSetVar]::new($_) }
    }
    end {}

}
#Get-CommonVariable -Tenant XXROM001 -VariableSet "customer variables"
