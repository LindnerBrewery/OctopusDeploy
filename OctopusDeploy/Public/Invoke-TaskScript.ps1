function Invoke-TaskScript {
<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.EXAMPLE
    PS C:\> Invoke-TaskScript -machineId 'Machines-419' -ScriptBlock '$env:computername'
    Executes the script $env:computername' on Machines-419 and returns a task object
.EXAMPLE
    PS C:\> Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional
#>
    param (
        # Parameter help description
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $MachineId,
        [String]
        $ScriptBlock,
        [String]
        $Description,
        [int]
        $MaxTargetsPerTask
    )
    # TODO: Replace machineID with Machine Object and
    Test-OctopusConnection | out-null
    # split machineArray into chunks of $MaxTargetsPerTask https://stackoverflow.com/a/26850233
    if ($machineId.count -gt $MaxTargetsPerTask -and $MaxTargetsPerTask) {
        $counter = [pscustomobject] @{ Value = 0 }
        $groups = $machineId | Group-Object -Property { [math]::Floor($counter.Value++ / $MaxTargetsPerTask) }
        foreach ($item in $groups) {
            Invoke-TaskScript -machineId $item.group -ScriptBlock $ScriptBlock -Description $Description
        }

    }

    $repo._repository.Tasks.ExecuteAdHocScript($ScriptBlock, $machineId, $environmentId, $roles , $Description)
    #Invoke-TaskScript -machineId 'Machines-419' -ScriptBlock '$env:computername'
}


#Invoke-Script -machineId 'Machines-419' -ScriptBlock '$env:computername'
