function Get-VariableTemplate {
    <#
    .SYNOPSIS
        Gets a variable template from a variable set by name.
    .DESCRIPTION
        This function retrieves a specific variable template from a LibraryVariableSetResource based on the provided name.
    .PARAMETER VariableSet
        The LibraryVariableSetResource to search in.
    .PARAMETER Name
        The name of the template to find.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Octopus.Client.Model.LibraryVariableSetResource]$VariableSet,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    process {
        $template = $VariableSet.Templates | Where-Object Name -EQ $Name
        return $template
    }
}
