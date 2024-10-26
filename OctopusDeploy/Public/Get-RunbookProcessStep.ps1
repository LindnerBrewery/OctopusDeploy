function Get-RunbookProcessStep {
    <#
.SYNOPSIS
    Returns the runbook process steps for a given runbook
.DESCRIPTION
    Returns the runbook process steps for a given runbook.
.EXAMPLE
    PS C:\> Get-RunbookProcessStep -Runbook "MyRunbook"
    Returns the deployment process for "MyProject" and default branch if version controlled
.EXAMPLE
    PS C:\> Get-Runbook -name "MyRunbook" | Get-RunbookProcessStep
    Returns the steps of "MyProject" defined in the given branch

#>
    [CmdletBinding(DefaultParameterSetName = "Runbook")]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = 'Runbook')]
        [ValidateNotNullOrEmpty()]
        [RunbookSingleTransformation()]
        [Octopus.Client.Model.RunbookResource]
        $Runbook
    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {
            return ($repo._repository.RunbookProcesses.Get($Runbook.RunbookProcessId)).steps
    }
}
