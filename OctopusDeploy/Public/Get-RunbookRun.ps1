function Get-RunbookRun {
    <#
.SYNOPSIS
    Returns a list of runbook runs
.DESCRIPTION
    Returns a list of runbook runs depending on the parameters
.EXAMPLE
    PS C:\> Get-RunbookRun
    Returns all runbook runs. This can be extremely slow!
.EXAMPLE
    PS C:\> Get-RunbookRun -latest
    Returns the last runbook run which was executed
.EXAMPLE
    PS C:\> Get-Runbook -Project 'Install RS' -Name "Check Config - Max Memory" | Get-RunbookRun
    Returns all runs of all snapshots for a given runbook
    .EXAMPLE
    PS C:\> Get-RunbookSnapshot -Runbook "Predeploy - Default" -Published | Get-RunbookRun
    returns all runs of the currently published runbook snapshot. Beware: Runbook names are not unique. Add the project to be sure to only get a unique snapshot.

.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'byID' )]
        [AllowNull()]
        [AllowEmptyString()]
        [Alias("RunbookRun")]
        [String]
        $ID,
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'byRunbook' )]
        [ValidateNotNullOrEmpty()]
        [RunbookSingleTransformation()]
        [Octopus.Client.Model.RunbookResource]
        $Runbook,
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromPipeline = $true,
            ParameterSetName = 'byRunbookSnapshot' )]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.RunbookSnapshotResource]
        $RunbookSnapshot,

        [switch]
        $latest


    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {

        #by snapshotResource $repo._repository.Runbooksnapshots.GetRunbookRuns()

        $result = [System.Collections.ArrayList]::new()
        if ($PSCmdlet.ParameterSetName -eq 'default') {
            if ($latest) {
                $func = {
                    param($ff)
                    $true
                }
                return $repo._repository.RunbookRuns.findone($func)
            } else {
                return $repo._repository.RunbookRuns.findall()
            }
        }
        if ($PSCmdlet.ParameterSetName -eq 'byID') {
            return $repo._repository.RunbookRuns.get($ID)
        }
        if ($PSCmdlet.ParameterSetName -eq 'byRunbook') {
            $snapshot = Get-RunbookSnapshot -Runbook $Runbook
            if ($latest) {
                return Get-RunbookRun -RunbookSnapshot $_snapshot
            } else {
                return $repo._repository.RunbookRuns.findmany($func)
            }
            # $func = {
            #     param($ff)
            #     if ($ff.RunbookId -eq $($Runbook.ID)) {
            #         $true
            #     }
            # }

            # if ($latest) {
            #     return $repo._repository.RunbookRuns.findone($func)
            # } else {
            #     return $repo._repository.RunbookRuns.findmany($func)
            # }
        }

        if ($PSCmdlet.ParameterSetName -eq 'byRunbookSnapshot') {
            $func = {
                param($ff)
                $true
            }
        }
        if ($latest) {
            return $repo._repository.RunbookRuns.findone($func, $RunbookSnapshot.Links.RunbookRuns)
        } else {
            return $repo._repository.RunbookRuns.findmany($func, $RunbookSnapshot.Links.RunbookRuns)
        }
    }

    end {}
}
