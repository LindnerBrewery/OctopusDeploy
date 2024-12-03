<#
.SYNOPSIS
Sets the current space for the Octopus connection and saves it to your configuration if one exists.

.DESCRIPTION
This function sets the current space for the Octopus connection and saves it to your configuration if one exists. It takes either the name or ID of the space as input.

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

function Set-Space {
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
    begin {
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        # call SetSpace to set the space
        SetSpace @PSBoundParameters

        #get space object
        if ($PSCmdlet.ParameterSetName -eq "name") {
            $space = Get-Space | Where-Object name -EQ $name
        } else {
            $space = Get-Space | Where-Object id -EQ $id
        }
        # save the space in the configuration file if one exists
        $config = Get-ConnectionConfiguration
        if (($config.space -ne $space.name) -and ($null -ne $config)) {
            Write-Verbose "Setting space in config file to $($space.name)"
            Set-ConnectionConfiguration -Space $space.name
        }

    }

}
