function Remove-Release {
    <#
.SYNOPSIS
    Removes an release of a project
.DESCRIPTION
    Removes an release of a project. If no version is provided the latest release will be removed

.EXAMPLE
    PS C:\> Remove-Release -Project "Install Project" -Version "1.2.3"
    Removes the release with the version "1.2.3"
.EXAMPLE
    PS C:\> New-Release -Project "Install Project"
    Removes the latest release
.EXAMPLE
    PS C:\> Get-Release -Project $project -Latest | Remove-Release -force
    Removes the release piped to Remove-Release without confirmation

#>
    [CmdletBinding(DefaultParameterSetName = "Release",
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = 'Project')]
        [ValidateNotNullOrEmpty()]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]
        $Project,

        [Parameter(mandatory = $false,
            ValueFromPipeline = $false,
            Position = 1,
            ParameterSetName = 'Project' )]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Version,

        #Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = 'Release')]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.ReleaseResource]
        $Release,

        [switch]$Force

    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Project') {
            if ($version) {
                $releaseToRemove = Get-Release -Project $project -Version $version
                if (! $releaseToRemove) {
                    $myError = Get-CustomError -Message "Couldn't find release with version:$version" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
                    $PSCmdlet.WriteError($myError)
                    return
                }
            } else {
                $releaseToRemove = Get-Release -Project $project -Latest
            }
        }
        if ($PSCmdlet.ParameterSetName -eq 'Release') {
            $releaseToRemove = $Release
        }
        if ($Force.IsPresent -or $PSCmdlet.ShouldProcess("$($releaseToRemove.version)", "Delete release")) {
            try {

                $repo._repository.Releases.Delete($releaseToRemove)
                Write-Host ("Removed release {0}" -f $releaseToRemove.version)
            } catch {
                Throw $_
            }
        }
    }
    end {}
}
