function Get-MachinePolicy {
    <#
.SYNOPSIS
    Returns list of machine policies
.DESCRIPTION
    Returns list of machine policies for the current space
.EXAMPLE
    PS C:\> Get-MachinePolicy
    Returns list of machine policies
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byName' )]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Name,
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'byID' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID

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
        $result = [System.Collections.ArrayList]::new()
        if ($PSCmdlet.ParameterSetName -eq 'default') {
            $result = $repo._repository.MachinePolicies.GetAll()
        }
        if ($PSCmdlet.ParameterSetName -eq 'byName') {
            $result = $repo._repository.MachinePolicies.findbyname("$name")
        }
        if ($PSCmdlet.ParameterSetName -eq 'byID') {
            $result = $repo._repository.MachinePolicies.get("$id")
        }

        $result
    }
}
