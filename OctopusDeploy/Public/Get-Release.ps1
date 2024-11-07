function Get-Release {
<#
.SYNOPSIS
    Returns a list of release object of a project
.DESCRIPTION
    Returns a list of release object of a project depending on the input parameters. A release object are needed to get e.g. deployments or artifacts
.EXAMPLE
    PS C:\> Get-Release -Project 'Install Solution'
    Returns a list of all release of the project 'Install Solution'
.EXAMPLE
    PS C:\> Get-Release -Project 'Install Solution' -Latest
    Returns the latest release of the project 'Install Solution' ignoring any channels
.EXAMPLE
    PS C:\> Get-Release -Project 'Install Solution' -Latest -Channel default
    Returns the latest release in the 'default' channel of the project 'Install Solution'
.EXAMPLE
    PS C:\> Get-Release -Project 'Install Solution' -Latest -Channel default
    Returns the latest release in the 'default' channel of the project 'Install Solution'
.EXAMPLE
    PS C:\> Get-Release -Project 'Install Solution' -Version '7.15.6.1'
    Returns the release for the version '7.15.6.1'
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'Project')]
        [ValidateNotNullOrEmpty()]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]
        $Project,

        [Parameter(mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'Project' )]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Version,
        [Parameter(mandatory = $true,
            ParameterSetName = 'byID' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID,

        # Deployment channel name
        [Parameter(mandatory = $false,
            ParameterSetName = 'Project' )]
        [String]
        $Channel,
        [Parameter(mandatory = $false,
            ParameterSetName = 'Project' )]
        [Parameter(mandatory = $false,
            ParameterSetName = 'default' )]
        [switch]
        $Latest

    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'default') {
            $result = $repo._repository.Releases.findall()
        }

        if ($PSCmdlet.ParameterSetName -eq 'byID') {
            $result = $repo._repository.Releases.get("$id")
        }

        if ($PSCmdlet.ParameterSetName -eq 'Project') {

            # create a string that can be modified and used as a delegate
            $deligate = 'param ($r) ($r.ProjectId -eq $project.id)'


            # Add Channel filter to delegate
            if ($Channel) {
                $channelObj = Get-Channel -Name $channel -Project $Project -ErrorAction stop
                if ($channelObj) {
                    Write-Verbose "Found Channel: $($channelObj.name) - $($channelobj.id)"
                    $deligate += "-and `$r.ChannelId -eq `'$($channelobj.id)`'"
                }
            }
            #Write-verbose "Deletgate: $deligate"
            if ($latest.ispresent) {
                $result = $repo._repository.Releases.FindOne([scriptblock]::Create($deligate))
            } else {

                $result = $repo._repository.Releases.FindMany([scriptblock]::Create($deligate))
            }

            # filter out a specific version
            if ($Version) {
                $result = $result | Where-Object version -Like $version
            }
        }
        $result
    }
    end {}
}
