function New-TenantCommonVariablePayload {
    <#
    .SYNOPSIS
        Creates a TenantCommonVariablePayload object.
    .DESCRIPTION
        Helper function to create the payload for updating tenant common variables.
    .PARAMETER LibraryVariableSetId
        The ID of the library variable set.
    .PARAMETER TemplateId
        The ID of the variable template.
    .PARAMETER Value
        The value of the variable. Can be a string or PropertyValueResource.
    .PARAMETER Scope
        The scope of the variable. Can be CommonVariableScope, ReferenceCollection, or array of environment IDs.
    .PARAMETER VariableId
        The ID of the existing variable, if updating.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LibraryVariableSetId,

        [Parameter(Mandatory = $true)]
        [string]$TemplateId,

        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        $Scope,

        [Parameter(Mandatory = $false)]
        [string]$VariableId
    )

    process {
        # Handle Value
        if ($Value -isnot [Octopus.Client.Model.PropertyValueResource]) {
            $Value = [Octopus.Client.Model.PropertyValueResource]::new($Value, $false)
        }

        # Handle Scope
        if ($Scope -isnot [Octopus.Client.Model.TenantVariables.CommonVariableScope]) {
            if ($Scope -is [Octopus.Client.Model.ReferenceCollection]) {
                $Scope = [Octopus.Client.Model.TenantVariables.CommonVariableScope]::new($Scope)
            }
            elseif ($Scope -is [System.Collections.IEnumerable] -and $Scope -isnot [string]) {
                $collection = [Octopus.Client.Model.ReferenceCollection]::new($Scope)
                $Scope = [Octopus.Client.Model.TenantVariables.CommonVariableScope]::new($collection)
            }
            else {
                # Assume it's a single ID or empty
                $collection = [Octopus.Client.Model.ReferenceCollection]::new(@($Scope))
                $Scope = [Octopus.Client.Model.TenantVariables.CommonVariableScope]::new($collection)
            }
        }

        $payload = [Octopus.Client.Model.TenantVariables.TenantCommonVariablePayload]::new(
            $LibraryVariableSetId,
            $TemplateId,
            $Value,
            $Scope
        )

        if (-not [string]::IsNullOrEmpty($VariableId)) {
            $payload.Id = $VariableId
        }
        else {
            $payload.Id = [string]::Empty
        }

        return $payload
    }
}
