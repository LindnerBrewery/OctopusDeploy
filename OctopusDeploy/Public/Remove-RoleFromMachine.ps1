function Remove-RoleFromMachine {
    <#
.SYNOPSIS
    Add one or more Roles to a machine
.DESCRIPTION
    Add one or more Roles to a machine
.EXAMPLE
    PS C:\> Remove-RoleFromMachine -Machine MyMachine -Role jdk8, Powerhsell
    Add the roles jdk8, Powerhsell to the MyMachine
.EXAMPLE
    PS C:\> Get-Machine -Environment Development -Tenant XXROM001 | Remove-RoleFromMachine -Role TestRole
    Add the role TestRole to all machines of Get-Machine
.OUTPUTS
    [Octopus.Client.Model.MachineResource[]]
.NOTES
    General notes
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

        switch ($role.count) {
            1 { $wiMessages = "Removing role " ; break }
            { $_ -gt 1 } { $wiMessages = "Removing roles " ; break }
        }

        <#
        if ($role -gt 1) {
            $wiMessages = "Removing roles "
        }else{
            $wiMessages = "Removing role "

#>

        if ($pscmdlet.ShouldProcess("$($Machine.name)", "$wiMessages$($role -join ', ')")) {
            foreach ($_role in $Role) {
                $Machine.Roles.RemoveWhere({ param($t) $t -eq $_role }) | Out-Null # returns 0/1
                # This line would do the exactly the same thing as the predicate approach
                # $Machine.Roles.Remove("$_role") # will return true or false
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
