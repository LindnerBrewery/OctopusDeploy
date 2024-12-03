function Get-ProjectGroup {
    <#
.SYNOPSIS
    Returns a list of project groups
.DESCRIPTION

.EXAMPLE
    PS C:\> Get-ProjectGroup
    Returns an array of all projects groups for the current space
.EXAMPLE
    PS C:\> Get-ProjectGroup -Name Documentation
    Returns the project group called 'Documentation'


#>
    [CmdletBinding(
        DefaultParameterSetName = "default"
    )]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            Position = 0,
            ParameterSetName = "byName",
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,
        [Parameter(mandatory = $false,
            ParameterSetName = "byID")]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID

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
        $result = [System.Collections.Generic.List[Octopus.Client.Model.ProjectGroupResource]]::new()
        $result = $repo._repository.ProjectGroups.FindAll()
        if ($PSCmdlet.ParameterSetName -eq "default") {
            return $result
        }
        if ($PSCmdlet.ParameterSetName -eq "byID") {
            return ($result | Where-Object ID -EQ $ID)
        }
        if ($PSCmdlet.ParameterSetName -eq "byName") {
            return ($result | Where-Object Name -EQ $Name)
        }
    }
}
