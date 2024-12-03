function Get-ScriptModule {
    <#
.SYNOPSIS
    Returns script modules
.DESCRIPTION
    Returns script modules. Script modules are special variables that can contain powershell modules.
.EXAMPLE
    PS C:\> Get-ScriptModule
    Returns all script modules
.EXAMPLE
    PS C:\> Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'byID' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID,
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'byName' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
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
        function Get-VariableSet {
            param (
                [Parameter(mandatory = $true,
                    ValueFromPipelineByPropertyName = $true,
                    Position = 0,
                    ParameterSetName = 'byID' )]
                [ValidateNotNullOrEmpty()]
                [String]
                $ID
            )
            Test-OctopusConnection | Out-Null
            $repo._repository.VariableSets.Get($ID)
        }
        Test-OctopusConnection | Out-Null
        $result = [System.Collections.ArrayList]::new()
        if ($PSCmdlet.ParameterSetName -eq 'byID') {
            $result = $repo._repository.LibraryVariableSets.Get($ID) | Where-Object Contenttype -EQ "scriptModule"
        } elseif ($PSCmdlet.ParameterSetName -eq 'byName') {
            $result = $repo._repository.LibraryVariableSets.FindByName($Name) | Where-Object Contenttype -EQ "scriptModule"
        } else {
            $result = $repo._repository.LibraryVariableSets.GetAll() | Where-Object Contenttype -EQ "scriptModule"
        }

        $result | ForEach-Object { $_ | Add-Member -NotePropertyName 'VariableSet' -NotePropertyValue (Get-VariableSet $_.VariableSetId) }
        return $result
    }
    end {}
}


