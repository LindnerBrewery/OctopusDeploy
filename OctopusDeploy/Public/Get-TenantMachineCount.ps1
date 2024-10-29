function Get-TenantMachineCount {
    <#
    .SYNOPSIS
    Returns an list of tenants with their machines and the amount of machine which match the criteria
    .EXAMPLE
    PS C:\> Get-TenantMachineCount -Tenant Tenantname -Online
    Returns then tenant name, all machines that where online during the last health check and the amount of machines meeting the criteria
    .EXAMPLE
    PS C:\> Get-Tenant -Tag  "region/ch" | Get-TenantMachineCount -Environment Production -MachineRole 'databaseserver'
    A list of tenants with the specified tenant tag is piped to Get-TenantMachine. Get-TenantMachine will return a list of all tenants, the machines and machine count with the role 'databaseserver'
    Returns then tenant name, all machines that where online during the last health check and the amount of machines meeting the criteria
    .PARAMETER online
    If set only machines are returned that where online during the last health check
    #>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            valueFromPipeline = $true)]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [TenantTransformation()]
        [Octopus.Client.Model.TenantResource[]]
        $Tenant,
        [Parameter(mandatory = $false)]
        [EnvironmentTransformation()]
        [Octopus.Client.Model.EnvironmentResource[]]
        $Environment,
        [Parameter(mandatory = $false)]
        [String[]]
        $MachineRole,

        # Only Returns machine which where online during last heath check
        [Parameter()]
        [switch]
        $Online

    )
    begin {
        Test-OctopusConnection | Out-Null
        $boundParams = $PSBoundParameters
        <#$splat = @{}
        if ($boundParams.online) {
            $splat.online = $true
        }#>

        #remove tenant from boundparams and use the rest to get the machines
        if ($boundParams.Tenant) { $boundParams.Remove('Tenant') | Out-Null }
        $machine = Get-Machine @boundParams
    }
    process {
        if (!$Tenant) { $Tenant = Get-Tenant }
        foreach ($_tenant in $Tenant) {

            $resultHash = [PSCustomObject]@{
                Tenant  = $_tenant.name
                Count   = 0
                Machine = [Octopus.Client.Model.MachineResource[]]
            }
            $resultHash.machine = $machine | Where-Object TenantIds -EQ "$($_tenant.ID)"
            $resultHash.count = $resultHash.machine.count
            $resultHash
        }
    }
    end {

    }

}
