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
            
            # Variable to preserve (not being updated)
            $variableToPreserve = $currentVariables | Where-Object { $_.name -notin $VariableHash.Keys -and -not $_.IsDefaultValue }
            foreach ($var in $variableToPreserve) {
                $newTenantCommonVariablePayloadSpat = @{
                    LibraryVariableSetId = $var.LibraryVariableSetId
                    TemplateId           = $var.TemplateId
                    Value                = $var.ValueObject
                    Scope                = $var.ScopeIds
                    VariableId           = $var.VariableId
                }
                $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                $payloads += $payload
            }

            $variablesToChange = $currentVariables | Where-Object { $_.name -in $VariableHash.Keys }
          

            if (-not $Environment) {
                # We are updating unscoped variables only
                # We will preserve all scoped variables as-is
                foreach ($var in $variablesToChange | Where-Object { $_.Scope }) {
                    $newTenantCommonVariablePayloadSpat = @{
                        LibraryVariableSetId = $var.LibraryVariableSetId
                        TemplateId           = $var.TemplateId
                        Value                = $var.ValueObject
                        Scope                = $var.ScopeIds
                        VariableId           = $var.VariableId
                    }
                    $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                    $payloads += $payload
                }
                # update only unscoped variables
                foreach ($var in $variablesToChange | Where-Object { -not $_.Scope }) {
                    if ($VariableHash.Keys -contains $Var.Name) {
                        $newTenantCommonVariablePayloadSpat = @{
                            LibraryVariableSetId = $var.LibraryVariableSetId
                            TemplateId           = $var.TemplateId
                            Value                = $VariableHash[$var.Name]
                            IsSensitive          = $var.IsSensitive
                            Scope                = @() # unscoped
                            VariableId           = if ($var.VariableId) { $var.VariableId } else { $null }
                        }
                        $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                        $payloads += $payload
                    }
                }
                # Execute update using new API with all variables - any excluded variables are deleted
                $command = [Octopus.Client.Model.TenantVariables.ModifyCommonVariablesByTenantIdCommand]::new($Tenant.Id, $Tenant.SpaceId, $payloads)
                $repo._repository.TenantVariables.Modify($command) | Out-Null
                return # exit function as we are done handling unscoped only case

            }
            # We are updating scoped variables
            # first we preserve all unscoped variables as-is
            foreach ($var in $variablesToChange | Where-Object { -not $_.Scope -and -not $_.IsDefaultValue}) {
                $newTenantCommonVariablePayloadSpat = @{
                    LibraryVariableSetId = $var.LibraryVariableSetId
                    TemplateId           = $var.TemplateId
                    Value                = $var.ValueObject
                    Scope                = $var.ScopeIds
                    VariableId           = $var.VariableId
                }
                $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
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
                            $newTenantCommonVariablePayloadSpat = @{
                                LibraryVariableSetId = $var.LibraryVariableSetId
                                TemplateId           = $var.TemplateId
                                Value                = $var.ValueObject
                                Scope                = $newVarScope
                                VariableId           = $var.VariableId
                            }
                            $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                            $payloads += $payload
                            
                        }
                        continue
                    }
                    Write-Host "Existing scope env Ids: $($Var.ScopeIds -join ',')"
                    Write-Host "Target scope env Ids: $($targetScope.EnvironmentIds -join ',')"
                    $comparison = Compare-EnvironmentScope -ExistingScope $var.ScopeIds -NewScope $Environment.id
                    $comparison | Out-String
                    # update old variable and new variable depending on comparison result
                    if ($comparison.Status -eq 'Disjoint') {
                        Write-Verbose 'Keeping old variable as-is and adding new variable with updated value and target scope'

                        # add old variable as-is to payloads
                        $newTenantCommonVariablePayloadSpat = @{
                            LibraryVariableSetId = $var.LibraryVariableSetId
                            TemplateId           = $var.TemplateId
                            Value                = $var.ValueObject
                            Scope                = $var.ScopeIds
                            VariableId           = $var.VariableId
                        }
                        $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                        # check the payload does not already exist before adding to $payloads

                       
                        $payloads += $payload
                        
                        # # add new variable with updated value and target scope
                        # $newTenantCommonVariablePayloadSpat = @{
                        #     LibraryVariableSetId = $var.LibraryVariableSetId
                        #     TemplateId           = $var.TemplateId
                        #     Value                = $VariableHash[$var.Name]
                        #     IsSensitive          = $var.IsSensitive
                        #     Scope                = $comparison.NewScope
                        # }
                        # $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                        # $payloads += $payload
                        # $newVariable | Where-Object { $_.Name -eq $var.Name } | ForEach-Object { $_.Added = $true }
                    }
                    elseif ($comparison.Status -in 'Equal', 'Contained') {
                        Write-Verbose 'Updating existing variable with new value'
                        $newTenantCommonVariablePayloadSpat = @{
                            LibraryVariableSetId = $var.LibraryVariableSetId
                            TemplateId           = $var.TemplateId
                            Value                = $VariableHash[$var.Name]
                            IsSensitive          = $var.IsSensitive
                            Scope                = if (-not $null -eq $comparison.ExistingScope) { $($comparison.ExistingScope) }else { $($comparison.NewScope) }
                            VariableId           = $var.VariableId
                        }
                        $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                        
                        $payloads += $payload
                        $newVariable | Where-Object { $_.Name -eq $var.Name } | ForEach-Object { $_.Added = $true }

                    }
                    elseif ($comparison.Status -eq 'Overlap') {
                        Write-Verbose 'Updating existing variable to remove overlapping scope and adding new variable with updated value and target scope'
                        # update old variable with new scope
                        $newTenantCommonVariablePayloadSpat = @{
                            LibraryVariableSetId = $var.LibraryVariableSetId
                            TemplateId           = $var.TemplateId
                            Value                = $var.ValueObject
                            Scope                = $comparison.ExistingScope
                            VariableId           = $var.VariableId
                        }
                        $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                        
                        $payloads += $payload
                        

                        # add new variable with updated value and target scope
                        $newTenantCommonVariablePayloadSpat = @{
                            LibraryVariableSetId = $var.LibraryVariableSetId
                            TemplateId           = $var.TemplateId
                            Value                = $VariableHash[$var.Name]
                            IsSensitive          = $var.IsSensitive
                            Scope                = $comparison.NewScope
                        }
                        $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                        
                        $payloads += $payload
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
                $newTenantCommonVariablePayloadSpat = @{
                    LibraryVariableSetId = $varInfo.LibraryVariableSetId
                    TemplateId           = $varInfo.TemplateID
                    Value                = $nv.Value
                    IsSensitive          = $varInfo.IsSensitive
                    Scope                = $Environment.Id
                }
                $payload = New-TenantCommonVariablePayload @newTenantCommonVariablePayloadSpat
                $payloads += $payload
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
