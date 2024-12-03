function Get-TaskStatus {
    <#
.SYNOPSIS
    Returns the current status of a task. Running or completed
.DESCRIPTION
    Returns the current status of a task. Running or completed
.EXAMPLE
    PS C:\> Get-TaskStatus -ID ServerTasks-160473
    Returns the current status of task 'ServerTasks-160473'
#>
    param (
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.TaskResource]
        $task,
        [switch]$ExludeQueued,
        [switch]$ExludeCanceled
    )
    begin {
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        # use this approach to set a default view without a type definition . alternatively use formaters
        $defaultProperties = @('TaskType', 'ID', 'Description', 'Status')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’, [string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    }
    process {


        #$myObject | Add-Member MemberSet PSStandardMembers $PSStandardMembers
        if ($ExludeQueued.IsPresent -and $task.isCompleted -eq $False) {
            return
        }
        if ($ExludeCanceled.IsPresent -and $task.State -eq 'Canceled') {
            return
        }
        Write-Debug $task.State
        $obj = [PSCustomObject]@{
            TaskType    = $task.Name
            ID          = $task.id
            Description = $task.Description
            Status      = $task.State
            taskObject  = $task
        }

        if ($task.isCompleted -eq $true) {
            #$obj.Status = "completed"
            if ($task.HasWarningsOrErrors) {
                if ([System.String]::IsNullOrWhiteSpace($Task.ErrorMessage)) {
                    $obj.Status = 'SuccessWithWarning'
                }#else {
                #         $obj.Status = 'Failed'
                #     }
                # }else{
                #     $obj.Status = 'Success'
            }

        }
        $obj | Add-Member MemberSet PSStandardMembers $PSStandardMembers
        $obj
    }
    end {}
}
