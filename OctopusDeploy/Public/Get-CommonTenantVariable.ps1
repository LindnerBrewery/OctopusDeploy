function Get-CommonTenantVariable {
    <#
    .SYNOPSIS
        Returns a list of common tenant variables
    .DESCRIPTION
        Returns a list of common tenant variables for a specific tenant and variable set.
        This function retrieves variables from Library Variable Sets that are associated with the tenant.
        It returns both default values (from the Library Variable Set templates) and tenant-specific overridden values.
        Sensitive values are masked as *****.

        By default VariableSetName, Name, Value, IsDefaultValue and Scope are displayed. The returned objects also
        contain ScopeIds, TemplateId, IsSensitive, VariableId, LibraryVariableSetId and ValueObject.
    .PARAMETER Tenant
        The tenant to retrieve variables for.
    .PARAMETER VariableSet
        The Library Variable Set to filter by. If not provided, all variable sets associated with the tenant are processed.
    .PARAMETER Environment
        The environment to resolve the values for. If provided, one value per variable is returned:
        the value scoped to this environment if one exists, otherwise the unscoped tenant value, otherwise the default value.
    .EXAMPLE
        Get-CommonTenantVariable -Tenant XXROM001 -VariableSet 'Customer Variables'
        Returns all variables for tenant "XXROM001" from the "Customer Variables" set.
    .EXAMPLE
        Get-CommonTenantVariable -Tenant XXROM001
        Returns all common variables for tenant "XXROM001" from all associated variable sets.
    .EXAMPLE
        Get-CommonTenantVariable -Tenant XXROM001 -Environment Production
        Returns the common variable values for tenant "XXROM001" that apply to the Production environment.
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
        # properties shown by default, all other properties are still available on the objects
        $defaultDisplaySet = [System.Management.Automation.PSPropertySet]::new('DefaultDisplayPropertySet', [string[]]('VariableSetName', 'Name', 'Value', 'IsDefaultValue', 'Scope'))
        $standardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplaySet)
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
        # get all non default variables
        $commonTenantVarRequest = [Octopus.Client.Model.TenantVariables.GetCommonVariablesByTenantIdRequest]::new($Tenant.id, $Tenant.SpaceId)
        $tenantVars = $repo._repository.TenantVariables.get($commonTenantVarRequest)

        $results = @()
        foreach ($vSet in $VariableSets) {
            # get default variables from each set
            $libVars = $tenantVar.LibraryVariables."$($vSet.Id)"
            $results += $libVars.Templates | ForEach-Object { $setvar = $libVars.Variables."$($_.id)";
                # only output default values that are not overridden
                if ((-not $setvar.Value) -and (-not $setvar.SensitiveValue)) {
                    [pscustomobject]@{
                        VariableSetName      = $vSet.Name
                        Name                 = $_.name
                        Value                = $_.DefaultValue.value
                        ValueObject          = $_.DefaultValue
                        IsDefaultValue       = $true
                        Scope                = $null
                        ScopeIds             = $null
                        TemplateID           = $_.id
                        IsSensitive          = $_.DefaultValue.IsSensitive
                        VariableId           = $null
                        LibraryVariableSetId = $vSet.Id
                        origObject           = $_
                    }
                }
            }

            $vars = $tenantVars.Variables | Where-Object LibraryVariableSetId -EQ $vSet.Id

            $results += $vars | ForEach-Object {
                [pscustomobject]@{
                    VariableSetName      = $vSet.Name
                    Name                 = $_.template.name
                    Value                = $_.value.value
                    ValueObject          = $_.value
                    IsDefaultValue       = $false
                    Scope                = [String[]]($_.scope.EnvironmentIds | ForEach-Object { $environments | Where-Object id -Like $_ }).name
                    ScopeIds             = [String[]]($_.scope.EnvironmentIds)
                    TemplateID           = $_.TemplateId
                    IsSensitive          = $_.Value.IsSensitive
                    VariableId           = $_.Id
                    LibraryVariableSetId = $_.LibraryVariableSetId
                    origObject           = $_
                }
            }
        }
        # if an environment was specified, resolve the effective value per variable (template):
        # the value scoped to that environment if one exists, otherwise the unscoped tenant value, otherwise the default value
        if ($PSBoundParameters['Environment']) {
            $results = $results | Group-Object LibraryVariableSetId, TemplateID | ForEach-Object {
                $scoped = $_.Group | Where-Object { $_.ScopeIds -contains $Environment.Id }
                if ($scoped) {
                    $scoped
                }
                else {
                    $unscoped = $_.Group | Where-Object { -not $_.ScopeIds }
                    $unscopedTenantValue = $unscoped | Where-Object { -not $_.IsDefaultValue }
                    if ($unscopedTenantValue) { $unscopedTenantValue } else { $unscoped }
                }
            }
        }
        # mask sensitive values, set default display properties, order results and output
        $results | ForEach-Object {
            if ($_.IsSensitive) {
                $_.Value = "*****"
            }
            $_ | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $standardMembers -Force
            $_
        } | Sort-Object VariableSetName, Name
    }

    end {}

}
