function Save-Artifact {
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipelineByPropertyName = $true )]
        [ValidateNotNullOrEmpty()]
        [Alias("ID")]
        [String[]]
        $ArtifactID,
        [Parameter(mandatory = $true )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,
        # makes filename unique
        [Parameter(mandatory = $false )]
        [switch]
        $AddGUID

    )
    begin {
        Test-OctopusConnection | out-null
    }
    Process {
        foreach ($_ArtifactID in $ArtifactID) {
            Write-Verbose "Retrieving artifact for ID $_ArtifactID "
            $artifact = $repo._repository.Artifacts.Get("$_ArtifactID")
            Write-Verbose "Retrieving content from $($artifact.ID)"
            $content = $repo._repository.Artifacts.GetContent($artifact)
            # artifactts can have the same name. this makes the filename unique
            if ($AddGUID) {
                $guid = New-Guid
                $fn = $artifact.Filename
                $lastDot = $fn.LastIndexOf(".")
                if ($lastDot -eq -1) {
                    $filename = $fn + $guid
                } else {
                    $filename = $fn.Substring(0, $lastDot) + $guid + $fn.Substring($lastDot, $($fn.Length) - $lastDot)
                }

            } else {
                $filename = $artifact.Filename
            }

            Write-Verbose "Trying to save $filename) to $path"
            $fullPath = Join-Path $path $filename
            try {
                $file = [System.IO.File]::Create("$fullPath")
            } catch {
                Throw "Part of the path doesn't exist $path"
            }
            $content.CopyTo($file)
            $file.Close()
            $content.Close()
            get-item $file.name
        }
    }
    end {}

}



