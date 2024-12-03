function Get-TaskResult {
    <#
.SYNOPSIS
    Returns the result of a task
.DESCRIPTION
    Returns the (current) result of a task. This can be called for runnning tasks
.EXAMPLE
    PS C:\> Get-TaskResult -Task (Get-Task -ID ServerTasks-160473)
    Returns the result of 'ServerTasks-160473'

#>
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = 'byID' )]
        [Octopus.Client.Model.TaskResource]
        $Task
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
        #if ((Get-TaskStatus -ID $Task.id).status -eq "completed") {
        #}
        function getChildData {
            [CmdletBinding()]
            param (
                [Parameter()]
                [System.Object]
                $Children,
                # Parameter help description
                [Parameter(mandatory = $false)]
                [int]
                $depth = 1,
                [ref]
                $counter
            )
            foreach ($child in $Children) {
                $start = ""
                for ($i = 1; $i -lt $depth; $i++) {
                    $start += "_"
                }
                $start += " "
                $counter.Value ++

                [TaskResult]::new([String]$counter.value, ($start + $child.name).trim(), $child.Status, $child.Logelements.messagetext)
                if ($child.Children) {
                    foreach ($Cc in $child.Children) {
                        $r = getChildData $Cc ($depth + 1) ($counter)
                        #$counter = $r.step
                        $r
                    }

                }

            }
        }
        $taskDetails = $repo._repository.Tasks.GetDetails($Task)

        $counter = [int]0
        return getChildData $taskDetails.ActivityLogs -counter ([ref]$counter)
    }
    end {}
}



