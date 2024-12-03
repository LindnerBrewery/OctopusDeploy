function Copy-MachinePolicy {
    <#
.SYNOPSIS
    Function not finished but working
    Creates a copy of a given machine policy
.DESCRIPTION
    Creates a copy of a given machine policy. This can be used to used to reduce the amount of machines in a machine policy be copying the policy and redistributing the machines
.EXAMPLE
    PS C:\> No Example yet
#>
    [CmdletBinding()]
    param(
        [String]$Name,
        [Octopus.Client.Model.MachinePolicyResource]$MachinePolicy,
        [Switch]$IsDefault
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
        # TODO: update params with completers and documentation
        Test-OctopusConnection | Out-Null
        $newPolicy = [Octopus.Client.Model.MachinePolicyResource]::new()
        $newPolicy = $MachinePolicy = $repo._repository.MachinePolicies.Get($MachinePolicy.ID)
        $newPolicy.Name = $Name
        if (-not ($IsDefault.isPresent)) {
            $newPolicy.IsDefault = $False
        }
        $repo._repository.MachinePolicies.Create($newPolicy)# | Out-Null
    }
}


