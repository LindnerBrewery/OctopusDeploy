function New-Release {
    <#
.SYNOPSIS
    Creates an new release for a project
.DESCRIPTION
    Creates an new release for a project with the provided package version. If no versions are provided the new release will have the same package versions as the last one.

.EXAMPLE
    PS C:\> $package = @{myFirstPackage = '1.1.2'
                            aDifferentPackage = '5.0.1.6'}
    PS C:\> New-Release -Project "Install Project" -Package $package
    Creates a new release with the defined package versions and the latest packages for all other packages (if they exist)
.EXAMPLE
    PS C:\> New-Release -Project "Install Project"
    Creates a new release with the latest packages that can be found in the repository. Process changes will be part of the new release
.EXAMPLE
    PS C:\> $packages = @{myFirstPackage = 1.1.2
                            aDifferentPackage = 5.0.1.6}
    PS C:\> New-Release -Project "Install Project" -Package $packages -Version "1.2.3.4-Dev"
    Creates a new release with the defined package versions and the latest packages for all other packages (if they exist) and the release gets the version "1.2.3.4-Dev".
.EXAMPLE
    PS C:\>
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
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
            ParameterSetName = 'Project' )]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Version,

        [Parameter(mandatory = $false,
            ParameterSetName = 'Project' )]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $Package,

        [Parameter(mandatory = $false,
            ParameterSetName = 'Project' )]
        [ValidateNotNullOrEmpty()]
        [string]$ReleaseNotes,


        # Git branch name. Optional if source controlled project
        [Parameter(mandatory = $false,
            ParameterSetName = 'Project' )]
        [String]
        $GitBranch,

        # Deployment channel name
        [Parameter(mandatory = $false,
            ParameterSetName = 'Project' )]
        [String]
        $Channel

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
        # moved to Get-GitReference
        # $projectBranch = Get-GitBranch -Project $project
        # $gitReference = $null
        # if ($GitBranch -and $projectBranch) {
        #     if ($projectBranch.name -contains $GitBranch) {
        #         $gitReference = ($projectBranch | Where-Object name -EQ $GitBranch).CanonicalName
        #     }else{
        #         $myError = Get-CustomError -Message "Project $($projec.name) has no branch called $GitBranch" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
        #         $PSCmdlet.WriteError($myError)
        #         return
        #     }
        # } elseif ($projectBranch -and (-not $GitBranch)) {
        #     $gitReference = ($projectBranch | Where-Object IsDefault -eq $true).CanonicalName
        # } elseif  ((-not $projectBranch) -and $GitBranch) {
        #     $myError = Get-CustomError -Message "Project $($projec.name) is not source controlled" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
        #     $PSCmdlet.WriteError($myError)
        #     return
        # }
        # if ($gitReference){
        #     $GitReferenceResource = [Octopus.Client.Model.SnapshotGitReferenceResource]::new()
        #     $GitReferenceResource.GitRef = $gitReference
        # }
        $GitReferenceResource = Get-GitReference -Project $project -GitBranch $GitBranch -ErrorAction Stop
        # get the release channel
        if ($Channel) {
            $releaseChannel = Get-Channel -Name $Channel -Project $project
            if (! $releaseChannel) {
                $myError = Get-CustomError -Message "Couldn't find release channel: $channel" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
                $PSCmdlet.WriteError($myError)
                return
            }
        } else {
            # use default channel
            $releaseChannel = Get-Channel -Project $project | Where-Object isdefault
        }

        # Create a new release resource
        $release = [Octopus.Client.Model.ReleaseResource]::new()
        $release.ProjectId = $Project.Id
        $release.ChannelId = $releaseChannel.Id
        $release.GitReference = $GitReferenceResource
        $release.ReleaseNotes = $ReleaseNotes
        # add version if provided
        if ($Version) { $release.Version = $Version }

        # add a empty list of package to release
        $release.SelectedPackages = [System.Collections.Generic.List[Octopus.Client.Model.SelectedPackage]]::new()

        # replaced with Get-ReleaseTemplate
        # # Get deployment process
        # if($gitReference){
        #     $deploymentProcess = $repo._repository.DeploymentProcesses.Get($project,$GitReferenceResource.GitRef)
        # }else{
        #     $deploymentProcess = $repo._repository.DeploymentProcesses.Get($project)
        # }

        # # Get template
        # $template = $repo._repository.DeploymentProcesses.GetTemplate($deploymentProcess, $releaseChannel)
        $template = Get-ReleaseTemplate -Project $Project -Channel $Channel -GitBranch $GitBranch
        # set release version
        if ($Version) {
            $release.Version = $version
        } else {
            $release.Version = $template.NextVersionIncrement
        }
        #Validate that packages exist in project
        if ($Package) {
            foreach ($_package in $Package.GetEnumerator()) {
                if ($template.Packages.PackageId -notcontains $_package.key) {
                    $myError = Get-CustomError -Message "$($Project.Name) doesn't have a package named $($_package.key)" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
                    $PSCmdlet.WriteError($myError)
                    return
                }
            }
        }
        # add the newest version or given version to release object

        foreach ($_package in $template.Packages) {
            $packageVersions = Get-PackageVersion -TemplatePackage $_package

            # evaluate if a package and version was set for the current package and look for the given version
            if ($package.keys -contains $_package.PackageId) {
                $packageVersion = $package["$($_package.PackageId)"]
                if ($packageVersions.Version -contains $packageVersion) {
                    $version = $packageVersion
                } else {
                    $myError = Get-CustomError -Message "$($_package.PackageId) does not have a version $packageVersion" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
                    $PSCmdlet.WriteError($myError)
                    return
                }

                # Validation doesn't work as GetVersions only returns the latest element of the feed
                # $version = $repo._repository.Feeds.GetVersions($packageFeed, ([String[]]$_package.PackageId)) | Where-Object Version -EQ $packageVersion
                # if (! $version) {
                #     $myError = Get-CustomError -Message "$($_package.PackageId) does not have a version $packageVersion" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
                #     $PSCmdlet.WriteError($myError)
                #     return
                # }
            } else {
                # newest
                $version = $packageVersions[0].Version
            }
            $selectedPackage = [Octopus.Client.Model.SelectedPackage]::new()
            $selectedPackage.ActionName = $_package.ActionName
            $selectedPackage.PackageReferenceName = $_package.PackageReferenceName
            $selectedPackage.Version = $version

            # add to release
            $release.SelectedPackages.Add($selectedPackage)
        }
        # create release

        try {
            $repo._repository.Releases.Create($release, $false)
        } catch {
            Throw $_
        }
    }
    end {}
}
