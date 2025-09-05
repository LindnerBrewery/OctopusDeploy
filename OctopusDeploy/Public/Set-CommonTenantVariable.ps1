function Set-CommonTenantVariable {
    <#
    .SYNOPSIS
        Set a common tenant variable
    .DESCRIPTION
        A longer description of the function, its purpose, common use cases, etc.
    .PARAMETER Tenant
        The tenant to modify.
    .PARAMETER VariableSet
        The variable set to modify.
    .PARAMETER Name
        The name of the variable to modify.
    .PARAMETER Value
        The new value for the variable.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        Set-CommonTenantVariable -Tenant Tenant -VariableSet 'Customer Variables' -Name 'Password' -Value '123'
        Sets the variable to 123
    .EXAMPLE
        Set-CommonTenantVariable -Tenant Tenant -VariableSet 'Customer Variables' -Name 'Password' -Value ''
        Resets the variable back to default
    .EXAMPLE
        Set-CommonTenantVariable -Tenant Tenant -VariableSet 'Customer Variables' -VariableHash @{Port = "1111"; IP  = "1.2.3.4"}
        Sets multiple variables by passing a hashtable
    #>
    [CmdletBinding()]
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
        [LibraryVariableSetSingleTransformation()]
        [Octopus.Client.Model.LibraryVariableSetResource]$VariableSet,

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

        # get the library variable we want to modify
        $libVars = $TenantEditor.Variables.Instance.LibraryVariables."$($VariableSet.Id)"

        # Check that all the variable are defined in template
        foreach ($h in $VariableHash.GetEnumerator()) {
            if ($libVars.Templates.name -notcontains $h.Name) {
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
            $varTemplate = $libVars.Templates | Where-Object Name -EQ $h.name

            # set value
            $newValue = [Octopus.Client.Model.PropertyValueResource]::new($h.Value, $varTemplate.DefaultValue.IsSensitive)

            # Check if variable key exists an delete if there
            if ($libVars.Variables.ContainsKey($vartemplate.id)) {
                $message = "Removing old value {0} for {1}" -f $libVars.Variables."$($vartemplate.id)".value, $varTemplate.name
                Write-Verbose $message
                $libVars.Variables.Remove($vartemplate.id) | Out-Null
            }

            if ([string]::IsNullOrEmpty($h.Value)) {
                $message = "Resetting {0} to default value" -f $varTemplate.name
                Write-Verbose $message
            } else {

                # update variable
                $libVars.Variables.add($vartemplate.id, $newValue) | Out-Null
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

