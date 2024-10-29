function Get-PackageVersion {
    <#
.SYNOPSIS
    Returns a list of versions of a package
.DESCRIPTION
    Returns a list of versions of a package from a given TemplatePackage
.EXAMPLE
    PS C:\> Get-PackageVersion -TemplatePackage $package
    Returns all versions of the template package $pac
.EXAMPLE
    PS C:\> get-ReleaseTemplate -Project 'Install Solution' | select -ExpandProperty Packages | Get-PackageVersion
    Returns all versions of all packages for the given project
.EXAMPLE
    PS C:\> $packages = get-ReleaseTemplate -Project 'Install Solution' | select -ExpandProperty Packages
    PS C:\> $packages | Where packageid -like notepad* | Get-PackageVersion | select version
    Returns all versions of notepad that can be used in the project
#>
    [CmdletBinding(DefaultParameterSetName = 'Parameter Set 1')]
    [OutputType([String])]
    Param (
        # Param1 help description
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [Octopus.Client.Model.ReleaseTemplatePackage]$TemplatePackage,

        # Param3 help description
        [Parameter(Mandatory = $false)]
        [switch]$Latest
    )

    begin {
        Test-OctopusConnection | Out-Null
    }

    process {
        try {
            # get feed
            $packageFeed = $repo._repository.Feeds.Get($TemplatePackage.FeedId)
            [string]$path = $packageFeed.Links["SearchPackageVersionsTemplate"]

            # Make Generic List method
            $genericMethod = $repo._repository.Client.GetType().GetMethod("List").MakeGenericMethod([Octopus.Client.Model.PackageResource])

            # Set path parameters for call
            $pathParameters = [System.Collections.Generic.Dictionary[String, Object]]::new()
            $pathParameters.Add("PackageId", $TemplatePackage.PackageId)
            $pathParameters.Add("take", 1000)
            # Set generic method parameters
            $parameters = [System.Collections.Generic.List[Object]]::new()
            #[Object[]] $parameters = $path, $pathParameters
            $parameters = $path, $pathParameters

            # Invoke the List method
            $results = $genericMethod.Invoke($repo._client, $parameters)

            # return results
            if ($latest.IsPresent) {
                return $results.Items | Select-Object -First 1
            }
            return , $results.Items
        } catch {
            $PSCmdlet.WriteError($_)
        }
    }

    end {}
}
