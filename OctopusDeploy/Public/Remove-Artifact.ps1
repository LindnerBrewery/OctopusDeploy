function Remove-Artifact {
<#
.SYNOPSIS
    Deletes an artifact
.DESCRIPTION
    Artifacts take a lot of space on the server and can be deleted with this function
.EXAMPLE
    PS C:\> Get-Artifact | Remove-Artifact
    Deletes all artifacts
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0 )]
        [ValidateNotNullOrEmpty()]
        [ArtifactSingleTransformation()]
        [Octopus.Client.Model.ArtifactResource]
        $Artifact

    )
    begin {
        Test-OctopusConnection | out-null
        $deletedCounter  = 0
    }
    Process {
        Write-Verbose "Deleting $($Artifact.Filename)"
        $repo._repository.Artifacts.Delete($Artifact)
        $deletedCounter++
    }
    end {
        Write-Verbose "$deletedCounter artifacts have been removed"
    }

}



