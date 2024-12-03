function Get-ProjectTrigger {
    <#
.SYNOPSIS
    Returns a list of project triggers
.DESCRIPTION
    Retruns a list of project triggers
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Project to get the triggers from
        [Parameter(mandatory = $false,
            ParameterSetName = "byProject",
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]
        $Project,
        # Project trigger name
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
        $trigger = $repo._repository.ProjectTriggers.FindAll()
        if ($PSCmdlet.ParameterSetName -eq "byProject") {
            $trigger = $trigger | Where-Object ProjectId -EQ $Project.Id
        }
        if ($PSCmdlet.ParameterSetName -eq "byID") {
            return ($trigger | Where-Object ID -EQ $ID)
        }
        if ($PSCmdlet.ParameterSetName -eq "byName") {
            return ($trigger | Where-Object Name -EQ $Name)
        }
        $trigger
    }

    end {}
}
