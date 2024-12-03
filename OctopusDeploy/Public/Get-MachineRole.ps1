function Get-MachineRole {
    <#
.SYNOPSIS
    Returns a list of all machine roles
.DESCRIPTION
    Returns a list of all machine roles for the current space
.EXAMPLE
    PS C:\> Get-MachineRole
    Returns a list of all machine roles
#>
    [CmdletBinding(DefaultParameterSetName = 'Parameter Set 1',
        SupportsShouldProcess = $false)]
    [Alias()]
    [OutputType([String[]])]
    Param ()

    begin {
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        $repo._repository.MachineRoles.GetAllRoleNames()
    }

    end {}
}
