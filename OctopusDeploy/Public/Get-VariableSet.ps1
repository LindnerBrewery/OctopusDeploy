function Get-VariableSet {
    <#
    .SYNOPSIS
        Returns a list of variable sets
    .DESCRIPTION
        Returns a list of variable sets. The result can be used with Set-CommonTenantVariable
    .EXAMPLE
        C:\ PS> Get-VariableSet
        Returns a list of all variable sets
    .EXAMPLE
        C:\ PS> Get-VariableSet -Name 'Customer Variables'
        Returns a variable set by the name of 'Customer Variables'
    #>
    [CmdletBinding()]
    param (
        # Varible set name
        [String]$Name
    )
    begin {
        # testing connection to octopus
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {

        # variables types [System.Enum]::GetNames([Octopus.Client.Model.VariableSetContentType])
        if ($name) {
            $namefilter = "-and `$_.name -like `"$name`""
        }
        $where = "`$_.Contenttype -EQ 'Variables' $namefilter"
        $repo._repository.LibraryVariableSets.FindAll() | Where-Object -FilterScript ([scriptblock]::Create($where))
    }
    end {}
}
