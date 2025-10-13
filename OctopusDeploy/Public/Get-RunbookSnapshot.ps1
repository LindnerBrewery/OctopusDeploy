function Get-RunbookSnapshot {
    <#
.SYNOPSIS
    Returns runbook snapshots.
.DESCRIPTION
    Returns a runbook snapshot. A snapshot is the runbook equivalent to releases. It can be used to find runs or artifacts
.EXAMPLE
    PS C:\> Get-Runbook -Project 'Install RS' | Where-Object name -EQ  "Check Config - Max Memory" | Get-RunbookSnapshot -latest
    Returns the latest snapshot of the runbook. This is not necessarily the puplished snapshot
.EXAMPLE
    PS C:\> Get-RunbookSnapshot -Runbook "Predeploy - Default" -Published
    Returns the published snapshot of a runbook

#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'byName' )]
        [AllowNull()]
        [AllowEmptyString()]
        [Version]
        $Name,
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            ParameterSetName = 'byID' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID,
        [Parameter(mandatory = $false,
            ValueFromPipeline = $true,
            ParameterSetName = 'byRunbook' )]
        [ValidateNotNullOrEmpty()]
        [RunbookSingleTransformation()]
        [Octopus.Client.Model.RunbookResource[]]
        $Runbook,

        [Parameter(mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'byRunbook' )]
        [switch]
        $Published,

        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'byName' )]
            [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'byRunbook' )]
        [switch]
        $latest

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

        if ($PSCmdlet.ParameterSetName -eq 'byID') {
            return $repo._repository.Runbooksnapshots.get("$ID")
        }
        if ($PSCmdlet.ParameterSetName -eq 'default') {
            $result = $repo._repository.Runbooksnapshots.findall()
        }
        if ($PSCmdlet.ParameterSetName -eq 'byName') {
            $result = $repo._repository.Runbooksnapshots.FindByName($name)
        }
        if ($PSCmdlet.ParameterSetName -eq 'byRunbook') {
            if ($Runbook.Count -gt 1) {
                #if more than one object call recurse with bound params
                foreach ($_runbook in $Runbook) {
                    $boundParams = $PSBoundParameters
                    $boundParams.Runbook = $_Runbook
                    $result = Get-RunbookSnapshot @boundParams
                    if ($null -ne $result) {
                       $result
                    }
                }
                return #exit cmdlet
            } else {
                if ($Published.IsPresent) {
                    return $repo._repository.Runbooksnapshots.get(($Runbook.PublishedRunbookSnapshotId))
                } else {
                    $result = $repo._repository.RunbookSnapshots.FindAll("$($runbook.Links.RunbookSnapshots)")
                }
            }
        }
        if ($latest) {
            return $result | Select-Object -First 1
        } else {
            return $result
        }

        # depricated and will never get called
        # TODO new functions to update variable snapshos Update-RunbookSnapshotVariables -RunbookSnapshot or -Runbook (published will get updated)
        # have snapshot pipeable get-runbooksnaphot | update-runbooksnapshotVariables
        if ($UpdateVariableSnapshot.IsPresent) {
            return ($result | ForEach-Object { $repo._repository.Runbooksnapshots.SnapshotVariables($_) })
        }
    }
    end {}
}

