function Get-CommonTenantVariable {
    <#
    .SYNOPSIS
        Returns a list of common tenant variables
    .DESCRIPTION
        Returns a list of common tenant variables for a specific tenant and variable set.
        This function retrieves variables from Library Variable Sets that are associated with the tenant.
        It returns both default values (from the Library Variable Set templates) and tenant-specific overridden values.
    .PARAMETER Tenant
        The tenant to retrieve variables for.
    .PARAMETER VariableSet
        The Library Variable Set to filter by. If not provided, all variable sets associated with the tenant are processed.
    .PARAMETER Environment
        The environment to filter by. If provided, only variables scoped to this environment (or unscoped variables) are returned.
    .EXAMPLE
        Get-CommonTenantVariable -Tenant XXROM001 -VariableSet 'Customer Variables'
        Returns all variables for tenant "XXROM001" from the "Customer Variables" set.
    .EXAMPLE
        Get-CommonTenantVariable -Tenant XXROM001
        Returns all common variables for tenant "XXROM001" from all associated variable sets.
    .EXAMPLE
        Get-CommonTenantVariable -Tenant XXROM001 -Environment Production
        Returns all common variables for tenant "XXROM001" that are relevant to the Production environment.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]$Tenant,
        [parameter(Mandatory = $false,
            ValueFromPipeline = $true)]
        [LibraryVariableSetSingleTransformation()]
        [Octopus.Client.Model.LibraryVariableSetResource]$VariableSet,
        [parameter(Mandatory = $false)]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]$Environment

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
        $result = GetCommonTenantVariable @PSBoundParameters
        $result | ForEach-Object {
                    if ($_.IsSensitive) {
                        $_.Value = "*****"
                    }
                    $_
                } | Select-Object -Property VariableSetName, Name , Value, IsDefaultValue, Scope
    }

    end {}

}

