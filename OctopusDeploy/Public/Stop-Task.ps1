function Stop-Task {
    <#
    .SYNOPSIS
    Cancels tasks with specified states for a project release, runbook, or other filters.
    .DESCRIPTION
    This function retrieves tasks using the `Get-Task` function and cancels them based on the provided parameters.
    .PARAMETER Task
    The task to cancel. This parameter is mandatory when using the 'byTask' parameter set.
    .PARAMETER TaskType
    The type of task to filter by (e.g., Deploy, RunbookRun). Optional.
    .PARAMETER Tenant
    The tenant to filter tasks by. Optional.
    .PARAMETER Environment
    The environment to filter tasks by. Optional.
    .PARAMETER Regarding
    The task or runbook snapshot object to filter by. Optional.
    .PARAMETER State
    The state of the tasks to cancel. Valid values are "Executing", "Queued" and "WaitingForManualIntervention". Defaults to all if not specified.
    .EXAMPLE
    Stop-Task -Task (Get-Task -TaskID "ServerTasks-1234567")
    Cancels the task with the specified ID.
    .EXAMPLE
    Stop-Task -TaskType Deploy -State Executing
    Cancels all executing deployment tasks.
    .EXAMPLE
    Stop-Task -Tenant $tenant -Environment $environment -State Queued
    Cancels all queued tasks for the specified tenant and environment.
    .EXAMPLE
    Stop-Task -Regarding $runbookSnapshot
    Cancels all tasks regarding the given runbook snapshot.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ParameterSetName = 'byTask')]
        [TaskTransformation()]
        [Octopus.Client.Model.TaskResource[]]
        $Task,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'default')]
        [ValidateSet("Deploy", "RunbookRun", "Health", "AdHocScript", "Upgrade", "Backup", "TentacleUpgrade", "Retention", "MachinePolicyUpdate")]
        [string]
        $TaskType,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'default')]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]
        $Tenant,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'default')]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]
        $Environment,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'byRegarding')]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.Resource]
        $Regarding,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Executing", "Queued", "WaitingForManualIntervention")]
        [String[]]
        $State = @("Executing", "Queued", "WaitingForManualIntervention")
    )

    begin {
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        # Initialize counter for progress
        $taskCounter = 0
        $allTasks = @()
    }

    process {
        # Initialize an empty array to store tasks to cancel
        $tasksToCancel = @() 
        
        # Combine states into a regex pattern
        $stateRegex = ($State -join '|') -replace ' ', ''
        
        # Check the parameter set name to determine how to retrieve tasks
        if ($PSCmdlet.ParameterSetName -eq 'byTask') {
            # Cancel a specific task
            $tasksToCancel = $Task
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'byRegarding') {
            # Cancel tasks regarding a specific object
            foreach ($r in $Regarding) {
                $tasksToCancel = Get-Task -Regarding $r | Where-Object { $_.State -match $stateRegex }
            }
        }
        else {
            # Retrieve tasks using Get-Task
            $tasksToCancel = Get-Task -TaskType $TaskType -Tenant $Tenant -Environment $Environment | Where-Object { $_.State -match $stateRegex }
        }

        # Add to collection
        $allTasks += $tasksToCancel
    }

    end {
        Write-Verbose "Found $($allTasks.Count) tasks to cancel."

        # Cancel each task with progress bar
        $totalTasks = $allTasks.Count
        foreach ($_task in $allTasks) {
            $taskCounter++
            
            # Show progress bar
            if ($totalTasks -gt 0) {
                $percentComplete = ($taskCounter / $totalTasks) * 100
                Write-Progress -Activity "Cancelling Tasks" `
                    -Status "Processing task $taskCounter of $totalTasks" `
                    -CurrentOperation "Cancelling: $($_task.Description)" `
                    -PercentComplete $percentComplete
            }
            
            try {
                Write-Verbose "Cancelling task: $($_task.Id) - $($_task.Description)"
                $repo._repository.Tasks.Cancel($_task)
            }
            catch {
                Write-Warning "Failed to cancel task $($_task.Id): $_"
            }
        }
        
        # Clear the progress bar
        if ($totalTasks -gt 0) {
            Write-Progress -Activity "Cancelling Tasks" -Completed
        }
    }
}