function Get-CommonVariable {
    <#
    .SYNOPSIS
        Returns a list of common variables
    .DESCRIPTION
        Returns a list of common variables. These are common variables that are not connected to tenants
    .EXAMPLE
        PS C:\> Get-CommonVariable -VariableSet 'Customer Variables'
        Returns only common variables saved in 'Customer Variables' VariableSet
    .EXAMPLE
        PS C:\> Get-CommonVariable
        Returns all common variables in the current space
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false)]
        [LibraryVariableSetSingleTransformation()]
        [Octopus.Client.Model.LibraryVariableSetResource]$VariableSet

    )
    begin {
        # testing connection to octopus
        Test-OctopusConnection | Out-Null
    }
    process {
        # variables types [System.Enum]::GetNames([Octopus.Client.Model.VariableSetContentType])
        if($VariableSet){}else{[Octopus.Client.Model.LibraryVariableSetResource[]]$VariableSet = Get-VariableSet}
        foreach ($vSet in $VariableSet) {
            $libVars = $repo._repository.variableSets.Get($vSet.VariableSetId)
            $libVars.Variables | ForEach-Object { [VariableSetVar]::new($_) }
        }

    }
    end {}

}
#Get-CommonVariable -Tenant XXROM001 -VariableSet "customer variables"
