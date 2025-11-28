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
        # variables types [System.Enum]::GetNames([Octopus.Client.Model.VariableSetContentType])
        $tenantVar = $repo._repository.Tenants.GetVariables($Tenant)

        $environments = Get-Environment
        # Determine which Variable Sets to process
        $VariableSets = @()
        if ($PSBoundParameters['VariableSet']) {
            $VariableSets = $VariableSet
        }
        else {
            $VariableSets = Get-VariableSet | Where-Object { $_.id -in $tenantVar.LibraryVariables.Keys }
        }
        $results = @()
        foreach ($vSet in $VariableSets) {
            # get default variables from each set
            $libVars = $tenantVar.LibraryVariables."$($vSet.Id)"
            $results += $libVars.Templates | ForEach-Object { $setvar = $libVars.Variables."$($_.id)";
                # only output default values that are not overridden
                if ((-not $setvar.Value) -and (-not $setvar.SensitiveValue)) {
                    [pscustomobject]@{
                        VariableSetName = $vSet.Name
                        Name            = $_.name
                        Value           = if ($_.DefaultValue.IsSensitive) { "*****" }else { $_.DefaultValue.value }
                        IsDefaultValue  = $true
                        Scope           = $null
                    }
                }  
            }
            # get all non default variables
            $c = [Octopus.Client.Model.TenantVariables.GetCommonVariablesByTenantIdRequest]::new($Tenant.id, $Tenant.SpaceId)
            $tenantVars = $repo._repository.TenantVariables.get($c)
        
           
            $vars = $tenantVars.Variables | Where-Object LibraryVariableSetId -EQ $vSet.Id
            
            $results += $vars | ForEach-Object {
                [pscustomobject]@{
                    VariableSetName = $vSet.Name
                    Name            = $_.template.name
                    Value           = if ($_.Value.IsSensitive) { '*****' }else { $_.value.value }
                    IsDefaultValue  = $false
                    Scope           = [String[]]($_.scope.EnvironmentIds | ForEach-Object { $environments | Where-Object id -Like $_ }).name
                }
            }
            # if an environment was specified, return all scoped variables for that environment and unscoped variables a far the variable has no environment scope
            if ($PSBoundParameters['Environment']) {
                [System.Array]$results = $results | Where-Object { ($_.Scope -contains $Environment.Name) -or ($null -eq $_.Scope -and ($results | Where-Object Name -EQ $_.name).count -eq 1) }  
            }
            
  
        
        }
        # order results and output
        $results = $results | Sort-Object VariableSetName, Name
        $results
    }

    end {}

}
#Get-CommonTenantVariable -Tenant XXROM001 -VariableSet "customer variables"
