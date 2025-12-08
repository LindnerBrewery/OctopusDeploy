function GetCommonTenantVariable {
   
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
                        Value           = $_.DefaultValue.value
                        IsDefaultValue  = $true
                        Scope           = $null
                        ScopeIds        = $null
                        TemplateID      = $_.id
                        IsSensitive     = $_.DefaultValue.IsSensitive
                        VariableId      = $null
                        LibraryVariableSetId = $vSet.Id
                    }
                }  
            }
            # get all non default variables
            $commonTenantVarRequest = [Octopus.Client.Model.TenantVariables.GetCommonVariablesByTenantIdRequest]::new($Tenant.id, $Tenant.SpaceId)
            $tenantVars = $repo._repository.TenantVariables.get($commonTenantVarRequest)
        
           
            $vars = $tenantVars.Variables | Where-Object LibraryVariableSetId -EQ $vSet.Id
            
            $results += $vars | ForEach-Object {
                [pscustomobject]@{
                    VariableSetName = $vSet.Name
                    Name            = $_.template.name
                    Value           = $_.value.value
                    IsDefaultValue  = $false
                    Scope           = [String[]]($_.scope.EnvironmentIds | ForEach-Object { $environments | Where-Object id -Like $_ }).name
                    ScopeIds        = [String[]]($_.scope.EnvironmentIds)
                    TemplateID      = $_.TemplateId
                    IsSensitive     = $_.Value.IsSensitive
                    VariableId      = $_.Id
                    LibraryVariableSetId = $_.LibraryVariableSetId
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

