function Get-CurrentSpace {
<#
.SYNOPSIS
    Returns Name and ID of the current space
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.EXAMPLE
    PS C:\> Get-CurrentSpace
    A longer description of the function, its purpose, common use cases, etc.
#>
    [CmdletBinding()]
    param (

    )
    Test-OctopusConnection | out-null
    $spaceID = split-path ($repo._repository.LoadSpaceRootDocument().links.self) -Leaf
    $repo._repository.Spaces.Get($spaceID) | Select-object Name, ID

}
