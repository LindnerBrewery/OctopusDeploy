function Get-MachineConnectionStatus {
    <#
    .SYNOPSIS
        Returns the connection status of one or more machines.

    .DESCRIPTION
        This function returns the connection status of one or more machines. It takes an array of MachineResource objects as input and retrieves the connection status for each machine. Optionally, it can include the machine name in the output.

    .EXAMPLE
        PS C:\> Get-MachineConnectionStatus -Machine $machines -IncludeMachineName
        Returns the connection status of the specified machines and includes the machine name in the output.

    .INPUTS
        - Machine: An array of MachineResource objects representing the machines to check the connection status for.

    .OUTPUTS
        The function outputs the connection status of each machine as a MachineConnectionStatus object. If the -IncludeMachineName switch is used, the output includes the machine name as well.

    .NOTES
        This function requires a connection to the Octopus server. If no connection is available, an error is thrown.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Parameter Set 1')]
        [MachineTransformation()]
        [Octopus.Client.Model.MachineResource[]]
        $Machine,
        # Switch to add machine name to output
        [Parameter(Mandatory = $false,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Parameter Set 1')]
        [switch]
        $IncludeMachineName
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
        foreach ($_machine in $Machine) {
            $machineConnectionStatus = $repo._repository.Machines.GetConnectionStatus($_machine)
            if ($IncludeMachineName) {
                $machineConnectionStatus | Add-Member -MemberType NoteProperty -Name MachineName -Value $_machine.Name
            }
            $machineConnectionStatus
        }
    }

    end {}
}
