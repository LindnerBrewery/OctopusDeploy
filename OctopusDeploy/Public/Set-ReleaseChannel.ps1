<#
.SYNOPSIS
Sets the release channel for a given Octopus Deploy release.

.DESCRIPTION
The Set-ReleaseChannel function updates the channel of a specified release in Octopus Deploy.
It validates the provided channel name against the available channels in the project and updates the release if the channel is found.

.PARAMETER Release
The release object that needs to be updated. This parameter is mandatory and accepts pipeline input.

.PARAMETER Channel
The name of the channel to set for the release. This parameter is mandatory and accepts pipeline input.

.EXAMPLE
$release = Get-Release -ProjectName "MyProject" -Version "1.0.0"
Set-ReleaseChannel -Release $release -Channel "Default"

This example retrieves a release and sets its channel to "Default".

.NOTES
This function requires an active connection to the Octopus Deploy server. Ensure that the Test-OctopusConnection function is available and correctly configured.

#>
function Set-ReleaseChannel {

    [CmdletBinding()]
    param (
        [Parameter(mandatory = $true,
            ParameterSetName = "default",
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.ReleaseResource]
        $Release,

        [Parameter(mandatory = $true,
            ParameterSetName = "default",
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Channel
    )
    begin {
        Test-OctopusConnection | Out-Null
    }

    process {
        $project = Get-Project -ID $Release.ProjectId
        $channels = Get-Channel -Project $project
        if ($channels.name -notcontains $Channel) {
            $channelsString = $channels.name -join ", "
            $err = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Channel '$Channel' not found in project '$($project.Name)'. Possible channels are: $channelsString"),
                "ChannelNotFound",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($err)
        } 

        $c = $channels | Where-Object { $_.Name -eq $Channel }
        Write-Verbose "Found Channel: $($c.Name) - $($c.Id)"

        $Release.ChannelId = $c.Id

        try {
            $repo._repository.Releases.Modify($Release)
            Write-Verbose "Release channel successfully updated to '$Channel'."
        } catch {
            $err = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Could not set Channel '$Channel' in Release $($Release.Version) of project '$($project.Name)'."),
                "ChannelNotSet",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($err)
        }
    }

    end {}
}
