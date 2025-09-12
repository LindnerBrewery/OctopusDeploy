function Set-ProjectTenantVariable {
    <#
    .SYNOPSIS
        Sets a project tenant variable in Octopus Deploy scoped to a specific environment.
    .DESCRIPTION
        This function sets a project tenant variable in Octopus Deploy. It takes in a TenantResource object, a ProjectResource object, an EnvironmentResource object, and either a hashtable of variable names and values or a name-value pair of a single variable.
    .PARAMETER Tenant
        The tenant to modify.
    .PARAMETER Project
        The project of the variable.
    .PARAMETER Environment
        The environment to scope the variable to.
    .PARAMETER Name
        The name of the variable to modify.
    .PARAMETER Value
        The new value for the variable.
    .PARAMETER VariableHash
        A hashtable of variable names and values to set multiple variables at once.
    .EXAMPLE
        Set-ProjectTenantVariable -Tenant $tenant -Project $project -Environment $environment -Name "VariableName" -Value "VariableValue"
        Sets the variable "VariableName" to "VariableValue" for the specified tenant, project, and environment.
    .INPUTS
        TenantSingleTransformation: Accepts a single TenantResource object.
        ProjectSingleTransformation: Accepts a single ProjectResource object.
        EnvironmentSingleTransformation: Accepts a single EnvironmentResource object.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Parameter Set 1',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    param (
        [parameter(Mandatory = $true,
            ParameterSetName = 'Hash')]
        [parameter(Mandatory = $true,
            ParameterSetName = 'Value')]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]$Tenant,

        [parameter(Mandatory = $true,
            ParameterSetName = 'Hash')]
        [parameter(Mandatory = $true,
            ParameterSetName = 'Value')]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]$Project,

        [parameter(Mandatory = $true,
            ParameterSetName = 'Hash')]
        [parameter(Mandatory = $true,
            ParameterSetName = 'Value')]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]$Environment,

        [parameter(Mandatory = $true,
            ParameterSetName = 'Value')]
        [String]$Name,

        [parameter(Mandatory = $true,
            ParameterSetName = 'Value')]
        [AllowEmptyString()]
        [String]$Value,

        [parameter(Mandatory = $true,
            ParameterSetName = 'Hash')]
        [hashtable]$VariableHash
    )

    begin {
        # testing connection to octopus
        try {
            ValidateConnection
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        try {
            # Fix the parameter set name comparison (case sensitive)
            if ($PSCmdlet.ParameterSetName -eq "Value") {
                $VariableHash = @{}
                $VariableHash[$Name] = $Value
            }
            Write-Verbose "Processing variables: $($VariableHash | ConvertTo-Json -Compress)"

            # Get ALL existing project variables for this tenant
            $getRequest = [Octopus.Client.Model.TenantVariables.GetProjectVariablesByTenantIdRequest]::new($Tenant.Id, $Tenant.SpaceId)
            $allExistingVariables = $repo._repository.TenantVariables.Get($getRequest).Variables

            # Check that all the variables are defined in template
            foreach ($h in $VariableHash.GetEnumerator()) {
                $template = $repo._repository.Tenants.GetVariables($Tenant).ProjectVariables[$Project.Id].Templates | Where-Object { $_.Name -eq $h.Name }
                if (-not $template) {
                    $message = "Couldn't find variable '$($h.Name)' in project '$($Project.Name)' template. Please define it first."
                    throw $message
                } else {
                    $message = "Found variable '$($h.Name)' in project '$($Project.Name)' template."
                    Write-Verbose $message
                }
            }

            # Create payloads for all variables
            $payloads = @()
            
            # Add all existing variables (unchanged) to preserve them, except those we're updating
            $variablesToUpdate = $VariableHash.Keys
            foreach ($existingVar in $allExistingVariables) {
                $varTemplate = $repo._repository.Tenants.GetVariables($Tenant).ProjectVariables[$Project.Id].Templates | Where-Object Id -EQ $existingVar.TemplateId
                $isTargetVariable = $variablesToUpdate -contains $varTemplate.Name -and $Environment.Id -contains $existingVar.Scope.EnvironmentIds

                if (-not $isTargetVariable) {
                    # This is a different variable - preserve it as-is
                    $payload = [Octopus.Client.Model.TenantVariables.TenantProjectVariablePayload]::new(
                        $existingVar.ProjectId,
                        $existingVar.TemplateId,
                        $existingVar.Value,
                        $existingVar.Scope
                    )
                    $payload.Id = $existingVar.Id
                    $payloads += $payload
                }
            }

            # Now add/update each variable from the hash for EACH environment separately
            foreach ($h in $VariableHash.GetEnumerator()) {
                # Get the template object. Id is needed to identify and set variable
                $varTemplate = $repo._repository.Tenants.GetVariables($Tenant).ProjectVariables[$Project.Id].Templates | Where-Object Name -EQ $h.Name

                # Create scope for this specific environment only
                # $targetEnvIds = [Octopus.Client.Model.ReferenceCollection]::new()
                # $targetEnvIds.Add($Environment.Id) | Out-Null
                $targetScope = [Octopus.Client.Model.TenantVariables.ProjectVariableScope]::new($Environment.Id)

                # Find existing variable for this specific environment
                $targetVariable = $allExistingVariables | Where-Object { 
                    $_.ProjectId -eq $Project.Id -and 
                    $_.TemplateId -eq $varTemplate.Id -and
                    $_.Scope.EnvironmentIds.Contains($Environment.Id)
                }

                # Create payload for this environment-specific variable
                $payload = [Octopus.Client.Model.TenantVariables.TenantProjectVariablePayload]::new(
                    $Project.Id,
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
                Write-Verbose "Successfully processed '$($h.Name)' = '$($h.Value)' for tenant '$($Tenant.Name)' (scoped to: $($Environment.Name), $action)"
                
            }
    
            # Execute update using new API with all variables - any excluded variables are deleted
            $command = [Octopus.Client.Model.TenantVariables.ModifyProjectVariablesByTenantIdCommand]::new($Tenant.Id, $Tenant.SpaceId, $payloads)
            $repo._repository.TenantVariables.Modify($command) | Out-Null

        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    end {}
}
