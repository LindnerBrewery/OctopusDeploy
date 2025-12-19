function Add-RoleToMachine {
    <#
.SYNOPSIS
    Add one or more Roles to a machine
.DESCRIPTION
    Add one or more Roles to a single machine
.EXAMPLE
    PS C:\> Add-RoleToMachine -Machine MyMachine -Role jdk8, Powershell
    Add the roles jdk8, Powershell to the MyMachine
.EXAMPLE
    PS C:\> Get-Machine -Environment Development -Tenant XXROM001 | Add-RoleToMachine -Role TestRole
    Add the role TestRole to all machines returned by Get-Machine
#>
    [CmdletBinding(DefaultParameterSetName = 'Parameter Set 1',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'http://www.octopus.com/',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        # Machine to add the roles to
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Parameter Set 1')]
        [MachineSingleTransformation()]
        [Octopus.Client.Model.MachineResource]
        $Machine,


        # Roles or role that will be added to the machine
        [Parameter(Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Parameter Set 1')]
        [String[]]
        $Role
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
        if ($role -gt 1) {
            $wiMessages = "Adding roles "
        }else{
            $wiMessages = "Adding role "
        }

        if ($pscmdlet.ShouldProcess("$($Machine.name)", "$wiMessages$($role -join ', ')")) {
            foreach ($_role in $Role) {
                $added = $Machine.Roles.Add($_role) 
                if ($added){
                    Write-Verbose "Added role $_role to machine $($Machine.Name)"
                }
                else {
                    Write-Verbose "Role $_role already exists on machine $($Machine.Name)"
                }
                try {
                    # Modify will return an update MachineResource. Only the last one will be returned to the user
                    $lastMachineUpdate = $repo._repository.Machines.Modify($Machine)
                } catch {
                    $pscmdlet.ThrowTerminatingError($_)
                }
            }
            return $lastMachineUpdate
        }
    }

    end {}
}
