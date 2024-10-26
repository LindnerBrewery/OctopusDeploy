function Get-CommonTenantVariable {
    <#
    .SYNOPSIS
        Returns a list of common tenant variables
    .DESCRIPTION
        Returns a list of common tenant variables for a specific tenant and variable set
    .EXAMPLE
        Get-CommonTenantVariable -Tenant XXROM001 -VariableSet 'Customer Variables'
        All variable from tenant "XXROM001" saved in "Customer Variables"
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]$Tenant,
        [parameter(Mandatory = $true,
        ValueFromPipeline = $true)]
        [LibraryVariableSetSingleTransformation()]
        [Octopus.Client.Model.LibraryVariableSetResource]$VariableSet

    )
    begin {
        # testing connection to octopus
        Test-OctopusConnection | Out-Null
    }
    process {
        # variables types [System.Enum]::GetNames([Octopus.Client.Model.VariableSetContentType])
            $tenantVar = $repo._repository.Tenants.GetVariables($Tenant)
            $libVars = $tenantVar.LibraryVariables."$($VariableSet.Id)"
            $libVars.Templates | ForEach-Object { $setvar = $libVars.Variables."$($_.id)"; [pscustomobject]@{
                    Name           = $_.name
                    Value          = if ($_.DefaultValue.IsSensitive) { "*****" }else { if ($setvar.value) { $setvar.value }else { $_.DefaultValue.value } }
                    IsDefaultValue = if ($setvar.value -or $setvar.SensitiveValue) { $false }else { $true }
                } }

    }
    end {}

}
#Get-CommonTenantVariable -Tenant XXROM001 -VariableSet "customer variables"
