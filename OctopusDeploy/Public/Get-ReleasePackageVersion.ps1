function Get-ReleasePackageVersion {
    <#
    .SYNOPSIS
        Returns a list of packages and version used in this release
    .DESCRIPTION
        Returns a list of packages and version used in this release. A specific release must be given
    .EXAMPLE
        PS C:\> Get-Release -Project 'Install Solution' -Version "7.15.6.1" | Get-ReleasePackageVersion
        Returns a list of all packages and package version used in the release
    .EXAMPLE
        PS C:\> Get-Release -Project 'Install Solution' -Version "7.15.6.1" | Get-ReleasePackageVersion -AsHashtable
        Returns a list of all packages and package version used in the release as a hashtable.
    #>

    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'default')]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.ReleaseResource]
        $Release,
        [Parameter(mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'default')]
        [switch]
        $AsHashtable

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
        Write-Verbose "Getting packages for $($release.Id) : $($release.version)"
        Write-Verbose "Link: $($repo.OctopusServerURL)$($release.Links.web)"
        $allActions = $repo._repository.DeploymentProcesses.get($release.ProjectDeploymentProcessSnapshotId).steps.actions

        $packageReference = [System.Collections.Generic.List[PSCustomObject]]::new()
        $selectedPackages = $release.SelectedPackages
        #check if any action as a ref to a package
        foreach ($action in $allActions) {

            if ($action.IsDisabled -eq $true) {
                continue
            }
            if ($packageID = ($action.Properties.GetEnumerator() | Where-Object key -Like "Octopus.Action.Package.PackageId" | Select-Object -ExpandProperty value).value) {
                $packageReference.Add([PSCustomObject]@{
                        action    = $action.Name
                        PackageId = $packageID
                    })
            }
            elseif ($packageID = ($action.Properties.Values.value -like "{`"PackageId`":*,`"FeedId`"*" | ConvertFrom-Json).PackageId) {
                $packageReference.Add([PSCustomObject]@{
                        action    = $action.Name
                        PackageId = $packageID
                    })
            }

        }
        #$packageReference = $allActions | ForEach-Object {$tmp = $_.Properties.Values.value -like "{`"PackageId`":*,`"FeedId`"*" | ConvertFrom-Json; if($tmp){$tmp | Add-Member -MemberType NoteProperty -Name Action -Value $_.name }; $tmp }
        # replace the PackageReferenceName with the real package id
        foreach ($packageRef in $packageReference) {
            if (($selectedPackages  | Where-Object Actionname -EQ $packageRef.action).count -gt 1) {
                ($selectedPackages  | Where-Object { $_.Actionname -EQ $packageRef.action -and $_.PackageReferenceName -eq '' }).PackageReferenceName = $packageRef.PackageId
            }
            else {
            ($selectedPackages  | Where-Object Actionname -EQ $packageRef.action).PackageReferenceName = $packageRef.PackageId
            }
        }
        $versions = $selectedPackages | Select-Object @{Name = 'Package'; Expression = { $_.PackageReferenceName } }, version

        if ($AsHashtable.isPresent) {
            $hash = [ordered]@{}
            $versions.ForEach({ $hash.add($_.package, $_.version) })
            return $hash
        }
        return $versions
    }
    end {}
}
