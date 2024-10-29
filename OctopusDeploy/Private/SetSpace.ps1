<#
.SYNOPSIS
Sets the current space for the Octopus connection.

.DESCRIPTION
This function sets the current space for the Octopus connection. It takes either the name or ID of the space as input.

.PARAMETER Name
Specifies the name of the space to set.

.PARAMETER Id
Specifies the ID of the space to set.

.EXAMPLE
Set-Space "MySpace"
Sets the current space to the space with the name "MySpace".

.EXAMPLE
Set-Space -Id "Spaces-1"
Sets the current space to the space with the ID "Spaces-1".

.NOTES
This function requires an active connection to an Octopus server. Use Test-OctopusConnection to test the connection before calling this function.
#>

function SetSpace {
    [cmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = "Name",
            ValueFromPipeline = $true)]
        [Alias("SpaceName")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [Parameter(Mandatory = $true,
            ParameterSetName = "ID",
            ValueFromPipelineByPropertyName = $true)]
        [Alias("SpaceId")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Id

    )
    if (! (Test-OctopusConnection)) {
        Throw "No connection to octopus server"
    }
    if ($PSCmdlet.ParameterSetName -eq "Name") {
        $space = Get-Space | Where-Object name -EQ $name
        if ($null -eq $space) {
            $err = [System.Management.Automation.ErrorRecord]::new(
                [Octopus.Client.Exceptions.OctopusResourceNotFoundException]::new('Space with name $name not found'),
                'PSOctopusdeploy.InvalidSpace',
                'InvalidArgument',
                $space
            )
            $errorDetails = [System.Management.Automation.ErrorDetails]::new('Space with name $name not found')
            $errorDetails.RecommendedAction = 'Double check the saved space with Get- and Set-ConnectionConfiguration'
            $err.ErrorDetails = $errorDetails
            $PSCmdlet.ThrowTerminatingError($err)
        }
    }
    if ($PSCmdlet.ParameterSetName -eq "ID") {
        $space = Get-Space | Where-Object Id -EQ $Id
        if ($null -eq $space) {
            $err = [System.Management.Automation.ErrorRecord]::new(
                [Octopus.Client.Exceptions.OctopusResourceNotFoundException]::new('Space with name $name not found'),
                'PSOctopusdeploy.InvalidSpace',
                'InvalidArgument',
                $space
            )
            $errorDetails = [System.Management.Automation.ErrorDetails]::new('Space with name $name not found')
            $errorDetails.RecommendedAction = 'Double check the saved space with Get- and Set-ConnectionConfiguration'
            $err.ErrorDetails = $errorDetails
            $PSCmdlet.ThrowTerminatingError($err)
        }
    }
    $script:repo.SetSpace($space.ID)
}
