function Set-CommonTenantVariable {
    <#
    .SYNOPSIS
        Sets or resets common tenant variables with support for environment scoping.
    .DESCRIPTION
        This function manages common tenant variables in Octopus Deploy, allowing you to set or reset variable values 
        with optional environment scoping. The function intelligently handles scope conflicts by comparing existing and 
        new scopes, preserving non-overlapping values while updating target environments.
        
        Key features:
        - Set single or multiple variables at once using a hashtable
        - Scope variables to specific environments or leave unscoped
        - Automatically handles scope conflicts (disjoint, overlapping, equal, contained)
        - Reset variables to default by providing an empty string value
        - Preserves all other tenant variables not being modified
        
        When updating scoped variables, the function compares the existing scope with the target scope:
        - Disjoint: Keeps existing scoped value and adds new value with target scope
        - Equal/Contained: Updates the existing variable with the new value
        - Overlap: Splits the variable - preserves non-overlapping environments with old value, updates target environments with new value
    .PARAMETER Tenant
        The tenant to modify. Accepts tenant name, ID, or TenantResource object.
    .PARAMETER VariableSet
        The library variable set containing the common variables. Accepts variable set name, ID, or LibraryVariableSetResource object.
    .PARAMETER Name
        The name of the variable to modify. Used when setting a single variable.
    .PARAMETER Value
        The new value for the variable. Use an empty string ('') to reset the variable to its default value.
    .PARAMETER VariableHash
        A hashtable of variable names and values to set multiple variables in a single operation. 
        Example: @{Port = "1111"; IP = "1.2.3.4"}
    .PARAMETER Environment
        An array of environment names to scope the variable to. If not provided, the variable will be unscoped.
        Accepts environment names, IDs, or EnvironmentResource objects.
    .EXAMPLE
        Set-CommonTenantVariable -Tenant 'Acme Corp' -VariableSet 'Customer Variables' -Name 'Password' -Value 'P@ssw0rd'
        
        Sets the unscoped variable 'Password' to 'P@ssw0rd' for tenant 'Acme Corp'.
    .EXAMPLE
        Set-CommonTenantVariable -Tenant 'Acme Corp' -VariableSet 'Customer Variables' -Name 'Password' -Value ''
        
        Resets the 'Password' variable back to its default value.
    .EXAMPLE
        Set-CommonTenantVariable -Tenant 'Acme Corp' -VariableSet 'Customer Variables' -VariableHash @{Port = "1111"; IP = "1.2.3.4"}
        
        Sets multiple unscoped variables at once using a hashtable.
    .EXAMPLE
        Set-CommonTenantVariable -Tenant 'Acme Corp' -VariableSet 'Customer Variables' -Name 'DatabaseType' -Value 'PostgreSQL' -Environment 'Production'
        
        Sets the 'DatabaseType' variable to 'PostgreSQL' scoped to the Production environment only.
    .EXAMPLE
        Set-CommonTenantVariable -Tenant 'Acme Corp' -VariableSet 'Customer Variables' -Name 'ConnectionString' -Value 'Server=new-server' -Environment 'Test','QA','Production'
        
        Sets the 'ConnectionString' variable scoped to multiple environments. If the variable already has values in other environments, 
        those will be preserved while the Test, QA, and Production environments will be updated with the new value.
    .EXAMPLE
        Set-CommonTenantVariable -Tenant 'Acme Corp' -VariableSet 'Customer Variables' -VariableHash @{Port = "5432"; DatabaseType = "PostgreSQL"} -Environment 'Development'
        
        Sets multiple variables scoped to a specific environment using a hashtable.
    .NOTES
        This function uses the Octopus Deploy Client API to modify tenant variables. All changes are atomic - 
        either all variables are updated successfully or none are changed.
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
                $envString = " scoped to environments: $($Environment.name -join ', ')"
                Write-Verbose "Processing variables for tenant '$($Tenant.Name)' in variable set '$($VariableSet.Name)'$envString"
            }
            else {
                Write-Verbose "Processing unscoped variables for tenant '$($Tenant.Name)' in variable set '$($VariableSet.Name)'"
            }
            Write-Verbose "Variables to update: $($VariableHash.Keys -join ', ')"
            
       
            # check the tenant has variables from the variable set passed in as a parameter
            $currentVariables = GetCommonTenantVariable -Tenant $Tenant
            if ($currentVariables.LibraryVariableSetId -notcontains $VariableSet.Id) {
                $message = "Tenant $($Tenant.Name) does not have any variables from variable set `"$($VariableSet.Name)`""
                $err = [System.Management.Automation.ErrorRecord]::new(
                    [System.Management.Automation.ItemNotFoundException]::new("$message"),
                    'NotSpecified',
                    'InvalidData',
                    "$($Tenant.name) / $($Variableset.name)"
                )
                $errorDetails = [System.Management.Automation.ErrorDetails]::new("$message")
                $errorDetails.RecommendedAction = "Ensure tenant has variables from variable set"
                $err.ErrorDetails = $errorDetails
                $PSCmdlet.ThrowTerminatingError($err)
            }

            # Check that the variables to set exist in the variable set
            $currentVarNames = ($currentVariables | Where-Object { $_.LibraryVariableSetId -eq $VariableSet.id }).Name
            $missingVars = @()
            foreach ($varName in $VariableHash.Keys) {
                if ($currentVarNames -notcontains $varName) {
                    $missingVars += $varName
                }
            }
            if ($missingVars) {
                $message = "The following variables were not found in variable set {0}: {1}" -f $VariableSet.Name, ($missingVars -join ', ')
                $err = [System.Management.Automation.ErrorRecord]::new(
                    [System.Management.Automation.ItemNotFoundException]::new("$message"),
                    'NotSpecified',
                    'InvalidData',
                    "$($Variableset.name) / $($missingVars -join ', ')"
                )
                $errorDetails = [System.Management.Automation.ErrorDetails]::new("$message")
                $errorDetails.RecommendedAction = "Check variable names exist in variable set"
                $err.ErrorDetails = $errorDetails
                $PSCmdlet.ThrowTerminatingError($err)
            }

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
            
            # Variable to preserve (not being updated)
            $variableToPreserve = $currentVariables | Where-Object { ($_.name.ToLower() -notin $VariableHash.Keys.ToLower() -and -not $_.IsDefaultValue -and $_.LibraryVariableSetId -eq $VariableSet.id ) -or 
                (-not $_.IsDefaultValue -and $_.LibraryVariableSetId -ne $VariableSet.id ) }

            if ($variableToPreserve) {
                Write-Verbose "Preserving $($variableToPreserve.Count) existing variable(s)"
            }
            foreach ($var in $variableToPreserve) {
                $newTenantCommonVariablePayloadSplat = @{
                    LibraryVariableSetId = $var.LibraryVariableSetId
                    TemplateId           = $var.TemplateId
                    Value                = $var.ValueObject
                    Scope                = $var.ScopeIds
                    VariableId           = $var.VariableId
                }
                $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSplat
                $payloads += $payload
            }

            $variablesToChange = $currentVariables | Where-Object { $_.name -in $VariableHash.Keys }
          

            if (-not $Environment) {
                Write-Verbose "Updating unscoped variables only"
                # We are updating unscoped variables only
                # We will preserve all scoped variables as-is
                foreach ($var in $variablesToChange | Where-Object { $_.Scope }) {
                    $newTenantCommonVariablePayloadSplat = @{
                        LibraryVariableSetId = $var.LibraryVariableSetId
                        TemplateId           = $var.TemplateId
                        Value                = $var.ValueObject
                        Scope                = $var.ScopeIds
                        VariableId           = $var.VariableId
                    }
                    $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSplat
                    $payloads += $payload
                }
                # update only unscoped variables
                foreach ($var in $variablesToChange | Where-Object { -not $_.Scope }) {
                    if ($VariableHash.Keys -contains $Var.Name) {
                        $newTenantCommonVariablePayloadSplat = @{
                            LibraryVariableSetId = $var.LibraryVariableSetId
                            TemplateId           = $var.TemplateId
                            Value                = $VariableHash[$var.Name]
                            IsSensitive          = $var.IsSensitive
                            Scope                = @() # unscoped
                            VariableId           = if ($var.VariableId) { $var.VariableId } else { $null }
                        }
                        $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSplat
                        $payloads += $payload
                    }
                }
                # Execute update using new API with all variables - any excluded variables are deleted
                Write-Verbose "Applying $($payloads.Count) variable payload(s) to tenant '$($Tenant.Name)'"
                $command = [Octopus.Client.Model.TenantVariables.ModifyCommonVariablesByTenantIdCommand]::new($Tenant.Id, $Tenant.SpaceId, $payloads)
                $repo._repository.TenantVariables.Modify($command) | Out-Null
                Write-Verbose "Successfully updated unscoped variables for tenant '$($Tenant.Name)'"
                return # exit function as we are done handling unscoped only case

            }
            # We are updating scoped variables
            Write-Verbose "Updating scoped variables"
            # first we preserve all unscoped variables as-is
            foreach ($var in $variablesToChange | Where-Object { -not $_.Scope -and -not $_.IsDefaultValue }) {
                $newTenantCommonVariablePayloadSplat = @{
                    LibraryVariableSetId = $var.LibraryVariableSetId
                    TemplateId           = $var.TemplateId
                    Value                = $var.ValueObject
                    Scope                = $var.ScopeIds
                    VariableId           = $var.VariableId
                }
                $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSplat
                $payloads += $payload
            }

           

            # convert the value hashtable to an array and add property to remember if already added
            $newVariable = $VariableHash.GetEnumerator() | ForEach-Object {
                [PSCustomObject]@{
                    Name  = $_.Name
                    Value = $_.Value
                    Added = $false
                }
            }

            foreach ($var in $variablesToChange | Where-Object { $_.Scope }) {
                # Determine if this variable is one we want to update and if both are scoped
                if ($newVariable.name -contains $var.Name) {
                    if ($newVariable | Where-Object { $_.Name -eq $var.Name -and $_.Added -eq $true } ) {
                        # var already added. remove scope. if one or more scoping we need to update
                        # remove target scope from variable scope
 
                        $newVarScope = $var.ScopeIds | Where-Object { $Environment.id -notcontains $_ }
                        
                        if ($newVarScope) {
                            # update existing variable with new scope
                            $newTenantCommonVariablePayloadSplat = @{
                                LibraryVariableSetId = $var.LibraryVariableSetId
                                TemplateId           = $var.TemplateId
                                Value                = $var.ValueObject
                                Scope                = $newVarScope
                                VariableId           = $var.VariableId
                            }
                            $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSplat
                            $payloads += $payload
                            
                        }
                        continue
                    }
                    $comparison = Compare-EnvironmentScope -ExistingScope $var.ScopeIds -NewScope $Environment.id
                    Write-Verbose "Scope comparison for variable '$($var.Name)': $($comparison.Status)"
                    # update old variable and new variable depending on comparison result
                    if ($comparison.Status -eq 'Disjoint') {
                        Write-Verbose "Variable '$($var.Name)': Keeping existing scope and adding new scoped value"

                        # add old variable as-is to payloads
                        $newTenantCommonVariablePayloadSplat = @{
                            LibraryVariableSetId = $var.LibraryVariableSetId
                            TemplateId           = $var.TemplateId
                            Value                = $var.ValueObject
                            Scope                = $var.ScopeIds
                            VariableId           = $var.VariableId
                        }
                        $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSplat
                        # check the payload does not already exist before adding to $payloads

                       
                        $payloads += $payload
                        
                    }
                    elseif ($comparison.Status -in 'Equal', 'Contained') {
                        Write-Verbose "Variable '$($var.Name)': Updating existing scoped variable with new value"
                        $newTenantCommonVariablePayloadSplat = @{
                            LibraryVariableSetId = $var.LibraryVariableSetId
                            TemplateId           = $var.TemplateId
                            Value                = $VariableHash[$var.Name]
                            IsSensitive          = $var.IsSensitive
                            Scope                = if (-not $null -eq $comparison.ExistingScope) { $($comparison.ExistingScope) }else { $($comparison.NewScope) }
                            VariableId           = $var.VariableId
                        }
                        $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSplat
                        
                        if ($payload) { $payloads += $payload }
                        $newVariable | Where-Object { $_.Name -eq $var.Name } | ForEach-Object { $_.Added = $true }

                    }
                    elseif ($comparison.Status -eq 'Overlap') {
                        Write-Verbose "Variable '$($var.Name)': Splitting overlapping scope - preserving non-overlapping environments and updating target environments"
                        # update old variable with new scope
                        $newTenantCommonVariablePayloadSplat = @{
                            LibraryVariableSetId = $var.LibraryVariableSetId
                            TemplateId           = $var.TemplateId
                            Value                = $var.ValueObject
                            Scope                = $comparison.ExistingScope
                            VariableId           = $var.VariableId
                        }
                        $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSplat
                        
                        $payloads += $payload
                        
                        # there seems to be and issue with setting sensitive variables to empty string in overlapping scope scenario
                        # workaround is to set a value to something else first then set to empty string in a second call
                        if ($var.IsSensitive -and [string]::IsNullOrEmpty($VariableHash[$var.Name])) {
                            Set-CommonTenantVariable -Tenant $Tenant -VariableSet $VariableSet -Name $var.Name -Value 'TemporaryValueForSensitiveVariable' -Environment $Environment -Verbose:$false
                        }

                        # add new variable with updated value and target scope
                        $newTenantCommonVariablePayloadSplat = @{
                            LibraryVariableSetId = $var.LibraryVariableSetId
                            TemplateId           = $var.TemplateId
                            Value                = $VariableHash[$var.Name]
                            IsSensitive          = $var.IsSensitive
                            Scope                = $comparison.NewScope
                        }
                        $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSplat
                        
                        if ($payload) { $payloads += $payload }
                        $newVariable | Where-Object { $_.Name -eq $var.Name } | ForEach-Object { $_.Added = $true }
                    }
                    else {
                        throw "Unhandled comparison status: $($comparison.Status)"
                    }

                }
            }

            # Add any new variables that were not already added
            foreach ($nv in $newVariable | Where-Object { $_.Added -eq $false }) {
                $varInfo = $currentVariables | Where-Object { $_.Name -eq $nv.Name } | Select-Object -First 1
                $newTenantCommonVariablePayloadSplat = @{
                    LibraryVariableSetId = $varInfo.LibraryVariableSetId
                    TemplateId           = $varInfo.TemplateID
                    Value                = $nv.Value
                    IsSensitive          = $varInfo.IsSensitive
                    Scope                = $Environment.Id
                }
                $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSplat
                if ($payload) { $payloads += $payload }
            }

            
            # Execute update using new API with all variables - any excluded variables are deleted
            Write-Verbose "Applying $($payloads.Count) variable payload(s) to tenant '$($Tenant.Name)'"
            $command = [Octopus.Client.Model.TenantVariables.ModifyCommonVariablesByTenantIdCommand]::new($Tenant.Id, $Tenant.SpaceId, $payloads)
            $repo._repository.TenantVariables.Modify($command) | Out-Null
            Write-Verbose "Successfully updated scoped variables for tenant '$($Tenant.Name)'"
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    
    end {}
}
