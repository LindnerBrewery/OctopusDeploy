function Set-CommonTenantVariable {
    <#
    .SYNOPSIS
        Sets or resets a common variable for a tenant, optionally scoped to specific environments.
    .DESCRIPTION
        This function allows you to set or reset a common variable for a specified tenant in Octopus Deploy. 
        You can provide a single variable name and value, or a hashtable of multiple variables to set at once. 
        Additionally, you can scope the variable to specific environments if needed.
    .PARAMETER Tenant
        The tenant to modify.
    .PARAMETER VariableSet
        The variable set to modify.
    .PARAMETER Name
        The name of the variable to modify.
    .PARAMETER Value
        The new value for the variable.
    .PARAMETER VariableHash
        A hashtable of variable names and values to set multiple variables at once.
    .PARAMETER Environment
        An array of environment names to scope the variable to. If not provided, the variable will be unscoped.
    .EXAMPLE
        Set-CommonTenantVariable -Tenant Tenant -VariableSet 'Customer Variables' -Name 'Password' -Value '123'
        Sets the variable to 123
    .EXAMPLE
        Set-CommonTenantVariable -Tenant Tenant -VariableSet 'Customer Variables' -Name 'Password' -Value ''
        Resets the variable back to default
    .EXAMPLE
        Set-CommonTenantVariable -Tenant Tenant -VariableSet 'Customer Variables' -VariableHash @{Port = "1111"; IP  = "1.2.3.4"}
        Sets multiple variables by passing a hashtable
    .EXAMPLE
        Set-CommonTenantVariable -Tenant $tenant -VariableSet $variableSet -Name "DatabaseType" -Value "PostgreSQL" -Verbose -Environment $environment
        Sets the variable scoped to a specific environment
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true,
            ParameterSetName = 'Hash')]
        [parameter(Mandatory = $true,
            ParameterSetName = 'Value')]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]
        $Tenant,

        [parameter(Mandatory = $true,
            ParameterSetName = 'Hash')]
        [parameter(Mandatory = $true,
            ParameterSetName = 'Value')]
        [LibraryVariableSetSingleTransformation()]
        [Octopus.Client.Model.LibraryVariableSetResource]
        $VariableSet,

        [parameter(Mandatory = $true,
            ParameterSetName = 'Value')]
        [String]$Name,

        [parameter(Mandatory = $true,
            ParameterSetName = 'Value')]
        [AllowEmptyString()]
        [String]$Value,

        [parameter(Mandatory = $true,
            ParameterSetName = 'Hash')]
        [hashtable]$VariableHash,

        [parameter(Mandatory = $false,
            ParameterSetName = 'Hash')]
        [parameter(Mandatory = $false,
            ParameterSetName = 'Value')]
        [EnvironmentTransformation()]
        [Octopus.Client.Model.EnvironmentResource[]]$Environment
    )
    
    begin {
        # testing connection to octopus
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

    }
    process {
        try {
            # Create the variable hash if using Name/Value parameters
            if ($PSCmdlet.ParameterSetName -eq "Value") {
                $VariableHash = @{}
                $VariableHash[$Name] = $Value
            }
            
            if ($PSBoundParameters['Environment']) {
                $envString = $Environment.name -join ', ' 
            }
            Write-Verbose "Processing variables: $($VariableHash | ConvertTo-Json -Compress) $envString"
            ###################################################################################
            # new implementation
            $getCommonTenantVariableSpat = @{
                Tenant      = $Tenant
                VariableSet = $VariableSet
            }
            
            $currentVariables = GetCommonTenantVariable @getCommonTenantVariableSpat


            # Check that all the variables are defined in Variable Set
            foreach ($h in $VariableHash.GetEnumerator()) {
                if ($currentVariables.Name -notcontains $h.Name) {
                    $message = "Couldn't find {0} in variable set {1}" -f $h.Name, $VariableSet.Name
                    $err = [System.Management.Automation.ErrorRecord]::new(
                        [System.Management.Automation.ItemNotFoundException]::new("$message"),
                        'NotSpecified',
                        'InvalidData',
                        "$($Variableset.name) / $($h.name)"
                    )
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new("$message")
                    $errorDetails.RecommendedAction = "Check variable exists in variable set"
                    $err.ErrorDetails = $errorDetails
                    $PSCmdlet.ThrowTerminatingError($err)
                }
                else {
                    $message = "Found variable {0} in variable set {1}" -f $h.Name, $VariableSet.Name
                    Write-Verbose $message
                }
            }
            # Create the target scope we want to match
            $targetEnvIds = [Octopus.Client.Model.ReferenceCollection]::new($Environment.id)
            $targetScope = [Octopus.Client.Model.TenantVariables.CommonVariableScope]::new($targetEnvIds)


            # Create payloads for all variables
            $payloads = @()
            foreach ($existingVar in $currentVariables ) {
                # Get the variable template
                $varTemplate = Get-VariableTemplate -VariableSet $VariableSet -Name $existingVar.Name

                # Determine if this variable is one we want to update and if both are scoped
                if ($targetScope.EnvironmentIds.count -and $existingVar.Scope -and $VariableHash.Keys -contains $existingVar.Name) {
                    Write-Host "Existing scope env Ids: $($existingVar.ScopeIds -join ',')"
                    Write-Host "Target scope env Ids: $($targetScope.EnvironmentIds -join ',')"
                    $comparison = Compare-EnvironmentScope -ExistingScope $existingVar.ScopeIds -NewScope $Environment.id
                    $comparison | Out-String
                    # update old variable and new variable depending on comparison result
                    if ($comparison.Status -eq 'Disjoint'){
                        'keeping old variable as-is and adding new variable with updated value and target scope'
                    }elseif ($comparison.Status -in 'Equal', 'Contained') {
                        'updating existing variable with new value'
                    }elseif ($comparison.Status -eq 'Overlap') {
                        'updating existing variable to remove overlapping scope and adding new variable with updated value and target scope'
                    }else {
                        throw "Unhandled comparison status: $($comparison.Status)"
                    }

                }
                elseif ($VariableHash.Keys -contains $existingVar.Name -and -not $existingVar.Scope -and $targetScope.EnvironmentIds.count -eq 0) {
                    "old value for {0} : {1}" -f $existingVar.Name, ($existingVar.Value)
                    "new value for {0} : {1}" -f $existingVar.Name, $VariableHash[$existingVar.Name]
                    "IsDefault {0}" -f $existingVar.IsDefaultValue
                    
                    # add old variable with updated value to payloads or create new variable if IsDefaultValue
                    $variableId = if (-not $existingVar.IsDefaultValue) { $existingVar.VariableId } else { $null }
                    
                    $newTenantCommonVariablePayloadSpat = @{
                        LibraryVariableSetId = $existingVar.LibraryVariableSetId
                        TemplateId           = $existingVar.TemplateId
                        Value                = $VariableHash[$existingVar.Name]
                        Scope                = $targetScope
                        VariableId           = $variableId
                    }
                    $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                        
                    $payloads += $payload

                }
                else {
                    # add old variable as-is to payloads
                    "Preserving variable {0} as-is with scope {1}" -f $existingVar.Name, ($existingVar.Scope -join ',')
                    #Todo: check if sensitive ....
                    $newTenantCommonVariablePayloadSpat = @{
                        LibraryVariableSetId = $existingVar.LibraryVariableSetId
                        TemplateId           = $existingVar.TemplateId
                        Value                = $existingVar.Value
                        Scope                = $existingVar.Scope
                        VariableId           = $existingVar.VariableId
                    }
                    $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                        
                    $payloads += $payload
                }
            }
            $payloads
            exit



            

            ###################################################################################
            # old implementation
            ###################################################################################
            # Get variable set resource
            # $VariableSet = $repo._repository.LibraryVariableSets.FindByName($VariableSet)

            # Get ALL existing common variables for this tenant
            $getRequest = [Octopus.Client.Model.TenantVariables.GetCommonVariablesByTenantIdRequest]::new($Tenant.Id, $Tenant.SpaceId)
            $allExistingVariables = $repo._repository.TenantVariables.Get($getRequest).Variables
        
            # Check that all the variables are defined in template
            foreach ($h in $VariableHash.GetEnumerator()) {
                if ($VariableSet.Templates.name -notcontains $h.Name) {
                    $message = "Couldn't find {0} in variable set {1}" -f $h.Name, $VariableSet.Name
                    throw $message
                }
                else {
                    $message = "Found variable {0} in variable set {1}" -f $h.Name, $VariableSet.Name
                    Write-Verbose $message
                }
            }

            #

            # Create the target scope we want to match (move outside the loop)
            $targetEnvIds = [Octopus.Client.Model.ReferenceCollection]::new()
            foreach ($_environment in $Environment) {
                $envObj = $repo._repository.Environments.FindByName($_environment)
                if (-not $envObj) {
                    $message = "Couldn't find environment {0}" -f $_environment
                    throw $message
                }
                $message = "Found environment {0} with ID {1}" -f $envObj.Name, $envObj.Id
                Write-Verbose $message
                $targetEnvIds.Add($envObj.Id) | Out-Null
            }
            $targetScope = [Octopus.Client.Model.TenantVariables.CommonVariableScope]::new($targetEnvIds)

            # Create payloads for all variables
            $payloads = @()
            
            # Add all existing variables (unchanged) to preserve them, except those we're updating
            $variablesToUpdate = $VariableHash.Keys
            foreach ($existingVar in $allExistingVariables) {
                $varTemplate = $VariableSet.Templates | Where-Object Id -EQ $existingVar.TemplateId
                $isTargetVariable = $variablesToUpdate -contains $varTemplate.Name #-and (Test-ScopeMatch $existingVar.Scope $targetScope)
                
                if (-not $isTargetVariable) {
                    # This is a different variable - preserve it as-is
                    $payload = [Octopus.Client.Model.TenantVariables.TenantCommonVariablePayload]::new(
                        $existingVar.LibraryVariableSetId,
                        $existingVar.TemplateId,
                        $existingVar.Value,
                        $existingVar.Scope
                    )
                    $payload.Id = $existingVar.Id
                    $payloads += $payload
                }
            }

            # Now add/update each variable from the hash
            foreach ($h in $VariableHash.GetEnumerator()) {
                # get the template object. Id is needed to identify and set variable
                $varTemplate = $VariableSet.Templates | Where-Object Name -EQ $h.Name

                # Find the specific variable we want to update (match library set, template, and scope)
                $targetVariable = $allExistingVariables | Where-Object { 
                    $_.LibraryVariableSetId -eq $VariableSet.Id -and 
                    $_.TemplateId -eq $varTemplate.Id #-and 
                    #(Test-ScopeMatch $_.Scope $targetScope)
                }

                # Create payload for this variable
                $payload = [Octopus.Client.Model.TenantVariables.TenantCommonVariablePayload]::new(
                    $VariableSet.Id,
                    $varTemplate.Id,
                    [Octopus.Client.Model.PropertyValueResource]::new($h.Value, $false),
                    $targetScope
                )
                
                if ($targetVariable) {
                    $payload.Id = $targetVariable.Id
                    $action = "updated ID: $($targetVariable.Id)"
                }
                else {
                    $payload.Id = [string]::Empty
                    $action = "created new"
                }
                
                $payloads += $payload

                $scope = if ($Environment.Count -eq 0) { "unscoped" } else { "scoped to: $($Environment -join ', ')" }
                Write-Verbose "Successfully processed '$($h.Name)' = '$($h.Value)' for tenant '$($Tenant.Name)' ($scope, $action)"
            }
    
            # Execute update using new API with all variables - any excluded variables are deleted
            $command = [Octopus.Client.Model.TenantVariables.ModifyCommonVariablesByTenantIdCommand]::new($Tenant.Id, $Tenant.SpaceId, $payloads)
            $repo._repository.TenantVariables.Modify($command) | Out-Null

        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    
    end {}
}
