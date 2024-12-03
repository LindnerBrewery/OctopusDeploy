<#
.SYNOPSIS
    Sets a project tenant variable in Octopus Deploy.
.DESCRIPTION
    This function sets a project tenant variable in Octopus Deploy. It takes in a TenantResource object, a ProjectResource object, an EnvironmentResource object, and either a hashtable of variable names and values or a name-value pair of a single variable.
.EXAMPLE
    PS C:\> Set-ProjectTenantVariable -Tenant $tenant -Project $project -Environment $environment -Name "VariableName" -Value "VariableValue"
    Sets the variable "VariableName" to "VariableValue" for the specified tenant, project, and environment.
.INPUTS
    TenantSingleTransformation: Accepts a single TenantResource object.
    ProjectSingleTransformation: Accepts a single ProjectResource object.
    EnvironmentSingleTransformation: Accepts a single EnvironmentResource object.
#>
function Set-ProjectTenantVariable {
    [CmdletBinding(DefaultParameterSetName = 'Parameter Set 1',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
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

        # provide environment if you only want tenant vars for a certain environment
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
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        # variables types [System.Enum]::GetNames([Octopus.Client.Model.VariableSetContentType])
        if ($PSCmdlet.ParameterSetName -eq "value") {
            $VariableHash = @{}
            $VariableHash[$Name] = $Value
        }
        $TenantEditor = $repo._repository.Tenants.CreateOrModify($Tenant.Name)

        # get the project variable we want to modify
        $projVars = $TenantEditor.Variables.Instance.ProjectVariables."$($project.id)"

        # Check that all the variable are defined in template
        foreach ($h in $VariableHash.GetEnumerator()) {
            if ($projVars.Templates.name -notcontains $h.Name) {
                $message = "Couldn't find {0} in variable set {1}" -f $h.Name, $VariableSet.Name
                Throw $message
            } else {
                $message = "Found variable {0}  in variable set {1}" -f $h.Name, $VariableSet.Name
                Write-Verbose $message
            }
        }

        # update each variable
        foreach ($h in $VariableHash.GetEnumerator()) {

            # get the template object. Id is needed to identiy and set variable
            $varTemplate = $projVars.Templates | Where-Object Name -EQ $h.name

            # set value
            # Check if value is sensitive
            if ($varTemplate.DisplaySettings['Octopus.ControlType'] -eq 'Sensitive'){
                $isSensitive = $true
            }else {
                $isSensitive = $false
            }
            # $newValue = [Octopus.Client.Model.PropertyValueResource]::new($h.Value, $varTemplate.DefaultValue.IsSensitive) # old implementation
            $newValue = [Octopus.Client.Model.PropertyValueResource]::new($h.Value, $isSensitive)

            # Check if variable key exists an delete if there
            if ($projVars.Variables."$($environment.id)".ContainsKey($vartemplate.id)) {
                $message = "Removing old value {0} for {1}" -f $projVars.Variables."$($environment.id)"."$($vartemplate.id)".value, $varTemplate.name
                Write-Verbose $message
                $projVars.Variables."$($environment.id)".Remove($vartemplate.id) | Out-Null
            }

            if ([string]::IsNullOrEmpty($h.Value)) {
                $message = "Resetting {0} to default value" -f $varTemplate.name
                Write-Verbose $message
            } else {

                # update variable
                $projVars.Variables."$($environment.id)".add($vartemplate.id, $newValue) | Out-Null
            }

        }

        try {
            #save modified tenant object
            $TenantEditor.Save() | Out-Null
            Write-Verbose "Saved changes to $($Tenant.Name)"
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

    }

    end {}
}
