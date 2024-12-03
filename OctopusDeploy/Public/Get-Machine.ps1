function Get-Machine {
<#
.SYNOPSIS
    Returns a list of machines/targets
.DESCRIPTION
    Returns a list of machines/targets depending on the input parameters
.EXAMPLE
    PS C:\> Get-Machine
    Returns a list of all machine object in the current space
.EXAMPLE
    PS C:\> Get-Machine | select name, healthstatus
    Returns a list of all machine names and their current status
.EXAMPLE
    PS C:\> (Get-Machine -Tenant XXROM001).count
    Returns the number of machines associated with a tenant
.EXAMPLE
    PS C:\> Get-Machine -Tenant XXROM001 -Role UpdateAgent.service -Environment Production
    Returns a list of all machine of a tenant with a specific role and environment
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            ParameterSetName = 'byName' )]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Name,
        [Parameter(mandatory = $false,
            ParameterSetName = 'byID' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID,
        [Parameter(mandatory = $false)]
        [EnvironmentTransformation()]
        [Octopus.Client.Model.EnvironmentResource[]]
        $Environment,
        [Parameter(mandatory = $false)]
        [Alias("MachineRole")]
        [String[]]
        $Role,

        [Parameter(mandatory = $false,
            ValueFromPipeline = $true)]
        [TenantTransformation()]
        [Octopus.Client.Model.TenantResource[]]
        $Tenant,

        # Only Returns machine which where online during last heath check
        [Parameter()]
        [switch]
        $Online

    )
    begin {
        # testing connection to octopus
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        $boundParams = $PSBoundParameters

        # we only need all machine if we are not looking by name or id
        if ($boundParams.keys -notin @('ID','name')) {
            $allmachines = $repo._repository.Machines.getall()
        }
    }
    process {
        #Test-OctopusConnection | Out-Null
        $result = $allmachines
        if ($PSCmdlet.ParameterSetName -eq 'byName') {
            $result = $repo._repository.Machines.findbyname("$name")
        }
        if ($PSCmdlet.ParameterSetName -eq 'byID') {
            $result = $repo._repository.Machines.get("$id")
        }
        if ($online.IsPresent) {
            $result = $result | Where-Object HealthStatus -In  @('Healthy', 'HasWarnings')
        }
        if ($Environment) {
            $result = $result | Where-Object EnvironmentIDs -In $Environment.Id
        }
        if ($Role) {
            $result = $result | Where-Object { (Compare-Object -ReferenceObject ([system.collections.Generic.List[String]]@($_.Roles)) -DifferenceObject $Role -ExcludeDifferent) }
        }
        if ($tenant) {
            $result = $result | Where-Object TenantIDs -In $Tenant.Id
        }
        return $result
    }
    end {}
}
