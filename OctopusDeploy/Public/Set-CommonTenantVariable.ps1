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
        [string[]]$Environment = @()
    )
    begin {
        # testing connection to octopus
        try {
            ValidateConnection
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        # Function to compare environment scopes
        # function Test-ScopeMatch($scope1, $scope2) {
        #     $env1 = @($scope1.EnvironmentIds | Sort-Object)
        #     $env2 = @($scope2.EnvironmentIds | Sort-Object)
    
        #     if ($env1.Count -ne $env2.Count) { return $false }
    
        #     for ($i = 0; $i -lt $env1.Count; $i++) {
        #         if ($env1[$i] -ne $env2[$i]) { return $false }
        #     }
    
        #     return $true
        # }
    }
    process {
        try {
            # Fix the parameter set name comparison (case sensitive)
            if ($PSCmdlet.ParameterSetName -eq "Value") {
                $VariableHash = @{}
                $VariableHash[$Name] = $Value
            }
            Write-Verbose "Processing variables: $($VariableHash | ConvertTo-Json -Compress)"
            
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
                } else {
                    $message = "Found variable {0} in variable set {1}" -f $h.Name, $VariableSet.Name
                    Write-Verbose $message
                }
            }

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
                } else {
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

        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    
    end {}
}
