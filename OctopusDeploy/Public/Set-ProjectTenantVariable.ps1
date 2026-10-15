function Set-ProjectTenantVariable {
    <#
    .SYNOPSIS
        Sets a project tenant variable in Octopus Deploy, either unscoped or scoped to one or more environments.
    .DESCRIPTION
        This function sets a project tenant variable in Octopus Deploy. It takes in a TenantResource object, a ProjectResource object,
        optionally one or more EnvironmentResource objects, and either a hashtable of variable names and values or a name-value pair of a single variable.

        Without -Environment the unscoped value is created or updated. Scoped values are not touched.

        With -Environment the value is set for exactly these environments. As an environment can only be in one scope per variable,
        existing scoped values are adjusted:
          - scope doesn't overlap:    kept unchanged
          - same scope:               value updated
          - scope fully covered:      removed, the new value covers it
          - scope partially covered:  the given environments are removed from its scope, its value is kept
        The unscoped value is never touched when setting a scoped value.
    .PARAMETER Tenant
        The tenant to modify.
    .PARAMETER Project
        The project of the variable.
    .PARAMETER Environment
        The environment(s) to scope the variable to. If omitted, the unscoped value is set.
    .PARAMETER Name
        The name of the variable to modify.
    .PARAMETER Value
        The new value for the variable.
    .PARAMETER VariableHash
        A hashtable of variable names and values to set multiple variables at once.
    .EXAMPLE
        Set-ProjectTenantVariable -Tenant $tenant -Project $project -Name "VariableName" -Value "VariableValue"
        Sets the unscoped value of "VariableName" to "VariableValue" for the specified tenant and project.
    .EXAMPLE
        Set-ProjectTenantVariable -Tenant $tenant -Project $project -Environment $environment -Name "VariableName" -Value "VariableValue"
        Sets the variable "VariableName" to "VariableValue" for the specified tenant, project, and environment.
    .EXAMPLE
        Set-ProjectTenantVariable -Tenant XXROM001 -Project 'Install RS' -Environment Development, Test -VariableHash @{ Var1 = 'a'; Var2 = 'b' }
        Sets Var1 and Var2 to a single value each, scoped to Development and Test. Existing values scoped to these environments are adjusted.
    .INPUTS
        TenantSingleTransformation: Accepts a single TenantResource object.
        ProjectSingleTransformation: Accepts a single ProjectResource object.
        EnvironmentTransformation: Accepts one or more EnvironmentResource objects.
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

        [parameter(Mandatory = $false,
            ParameterSetName = 'Hash')]
        [parameter(Mandatory = $false,
            ParameterSetName = 'Value')]
        [EnvironmentTransformation()]
        [Octopus.Client.Model.EnvironmentResource[]]$Environment,

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

            # Target environments. No environment means the unscoped value is set
            $targetEnvs = @($Environment | Where-Object { $_ } | Sort-Object Id -Unique)
            $targetIds = @(foreach ($env in $targetEnvs) { $env.Id })
            $scopeText = if ($targetIds) { "scoped to: $($targetEnvs.Name -join ', ')" } else { 'unscoped' }

            # Check that the project and environments are connected to the tenant
            if (-not $Tenant.ProjectEnvironments.ContainsKey($Project.Id)) {
                throw "Project '$($Project.Name)' is not connected to tenant '$($Tenant.Name)'."
            }
            $connectedEnvIds = $Tenant.ProjectEnvironments[$Project.Id]
            foreach ($env in $targetEnvs) {
                if ($connectedEnvIds -notcontains $env.Id) {
                    throw "Environment '$($env.Name)' is not connected to tenant '$($Tenant.Name)' for project '$($Project.Name)'."
                }
            }

            # Get ALL existing project variables for this tenant
            $getRequest = [Octopus.Client.Model.TenantVariables.GetProjectVariablesByTenantIdRequest]::new($Tenant.Id, $Tenant.SpaceId)
            $allExistingVariables = $repo._repository.TenantVariables.Get($getRequest).Variables


            $variableTemplate = $repo._repository.Tenants.GetVariables($Tenant).ProjectVariables[$Project.Id].Templates
            # Check that all the variables are defined in template
            foreach ($h in $VariableHash.GetEnumerator()) {
                $template = $variableTemplate | Where-Object { $_.Name -eq $h.Name }
                if (-not $template) {
                    $message = "Couldn't find variable '$($h.Name)' in project '$($Project.Name)' template. Please define it first."
                    throw $message
                } else {
                    $message = "Found variable '$($h.Name)' in project '$($Project.Name)' template."
                    Write-Verbose $message
                }
            }

            # Creates a payload for a value of this project with the given scope. No environment ids means unscoped
            function NewPayload ([string]$Id, [string]$TemplateId, $Value, [string[]]$EnvironmentIds) {
                $envIds = [Octopus.Client.Model.ReferenceCollection]::new([string[]]@($EnvironmentIds))
                $scope = [Octopus.Client.Model.TenantVariables.ProjectVariableScope]::new($envIds)
                $payload = [Octopus.Client.Model.TenantVariables.TenantProjectVariablePayload]::new($Project.Id, $TemplateId, $Value, $scope)
                $payload.Id = if ($Id) { $Id } else { [string]::Empty }
                $payload
            }

            # Create payloads for all variables
            $payloads = @()

            # Add all existing variables of other templates and projects (unchanged) to preserve them
            $targetTemplateIds = @(foreach ($t in $variableTemplate | Where-Object Name -In $VariableHash.Keys) { $t.Id })
            foreach ($existingVar in $allExistingVariables) {
                if ($existingVar.ProjectId -ne $Project.Id -or $targetTemplateIds -notcontains $existingVar.TemplateId) {
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

            # Now add/update each variable from the hash. An environment can only be in one scope per template,
            # so existing scoped values that overlap the target environments are adjusted:
            #   - no overlap:              kept unchanged
            #   - same scope:              updated (keeps its Id)
            #   - scope fully covered:     removed, the new value covers it
            #   - scope partially covered: target environments are removed from its scope, its value is kept
            # Without target environments only the unscoped value is created or updated
            foreach ($h in $VariableHash.GetEnumerator()) {
                # Get the template object. Id is needed to identify and set variable
                $varTemplate = $variableTemplate | Where-Object Name -EQ $h.Name
                $existingVars = @($allExistingVariables | Where-Object { $_.ProjectId -eq $Project.Id -and $_.TemplateId -eq $varTemplate.Id })
                $targetVariableId = $null

                foreach ($existingVar in $existingVars) {
                    $scopeIds = @($existingVar.Scope.EnvironmentIds)
                    $overlapIds = @($scopeIds | Where-Object { $targetIds -contains $_ })
                    $remainingIds = @($scopeIds | Where-Object { $targetIds -notcontains $_ })

                    if ($scopeIds.Count -eq 0 -and $targetIds.Count -eq 0) {
                        # existing unscoped value is the target
                        $targetVariableId = $existingVar.Id
                    } elseif ($overlapIds.Count -eq 0) {
                        # unscoped or no overlap - keep unchanged
                        $payloads += NewPayload $existingVar.Id $existingVar.TemplateId $existingVar.Value $scopeIds
                    } elseif ($remainingIds.Count -eq 0 -and $scopeIds.Count -eq $targetIds.Count) {
                        # same scope - this is the target
                        $targetVariableId = $existingVar.Id
                    } elseif ($remainingIds.Count -eq 0) {
                        # scope fully covered by the new value - drop it
                        Write-Verbose "Removing value of '$($h.Name)' (ID: $($existingVar.Id)), its scope is covered by the new value"
                    } else {
                        # scope partially covered - remove the target environments from its scope
                        Write-Verbose "Removing environments '$($overlapIds -join ', ')' from scope of '$($h.Name)' (ID: $($existingVar.Id))"
                        $payloads += NewPayload $existingVar.Id $existingVar.TemplateId $existingVar.Value $remainingIds
                    }
                }

                $newValue = [Octopus.Client.Model.PropertyValueResource]::new($h.Value, $($varTemplate.DefaultValue.IsSensitive))
                $payloads += NewPayload $targetVariableId $varTemplate.Id $newValue $targetIds

                $action = if ($targetVariableId) { "updated ID: $targetVariableId" } else { "created new" }
                Write-Verbose "Successfully processed '$($h.Name)' for tenant '$($Tenant.Name)' ($scopeText, $action)"
            }

            # Execute update using new API with all variables - any excluded variables are deleted
            if ($PSCmdlet.ShouldProcess("$($Tenant.Name) / $($Project.Name)", "Set variables '$($VariableHash.Keys -join "', '")' ($scopeText)")) {
                $command = [Octopus.Client.Model.TenantVariables.ModifyProjectVariablesByTenantIdCommand]::new($Tenant.Id, $Tenant.SpaceId, $payloads)
                $repo._repository.TenantVariables.Modify($command) | Out-Null
            }

        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    end {}
}
