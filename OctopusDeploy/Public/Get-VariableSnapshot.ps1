function Get-VariableSnapshot {
<#
.SYNOPSIS
    Returns a list of project or runbook variables snapshots
.DESCRIPTION
    Returns a list of project or runbook variables snapshots. This are the variables that where current during release or runbook snapshot creation
.EXAMPLE
    C:\ PS> Get-VariableSnapshot -Release (Get-Release -Project 'Install Solution' -Latest)
    Returns all saved variables
.EXAMPLE
    C:\ PS> $rs = Get-RunbookSnapshot -Runbook (Get-Runbook -Project 'Install Solution' -Name 'monitoring test') -latest
    C:\ PS> Get-VariableSnapshot -RunbookSnapshot $rs
    Returns all saved variables
#>

    [CmdletBinding()]
    param (

        [parameter(Mandatory = $true,
            ParameterSetName = "Release")]
        [Octopus.Client.Model.ReleaseResource]$Release,

        # tenant you want the variables for
        [parameter(Mandatory = $true,
            ParameterSetName = "runbookSnapshot")]
        [Octopus.Client.Model.RunbookSnapshotResource]$RunbookSnapshot

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
        if ($PSCmdlet.ParameterSetName -eq 'Release') {
            $ProjectVariableSetSnapshotId = $release.ProjectVariableSetSnapshotId
        } elseif ($PSCmdlet.ParameterSetName -eq 'RunbookSnapshot') {
            $ProjectVariableSetSnapshotId = $RunbookSnapshot.ProjectVariableSetSnapshotId
        }
        $snapsVars = $repo._repository.variableSets.Get($ProjectVariableSetSnapshotId)
        $snapsVars.Variables | ForEach-Object { [VariableSetVar]::new($_) }

    }
    end {}

}
<#
$release = get-release -Project 'Install Solution' -Latest
get-VariableSnapshot -Release $release
$rs = (Get-Runbook   -Name "Postgres 9 to 12 Migration" | Get-RunbookSnapshot -latest)
get-VariableSnapshot -RunbookSnapshot $rs
#>
