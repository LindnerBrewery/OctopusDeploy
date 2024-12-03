function Get-ArtifactContent {
    <#
.SYNOPSIS
    Returns the content of and artifact as a string
.DESCRIPTION
    Returns the content of and artifact as a string
.EXAMPLE
    PS C:\> Get-Artifact -Id "Artifacts-1989" | Get-ArtifactContent
    Returns the content of the artifact as a string
.EXAMPLE
    PS C:\> Get-Project -Name 'Test Project' | Get-Release -Latest | Get-Artifact | Get-ArtifactContent -Encoding Unicode | Out-File $PWD/myfile.txt
    Saves the content of all found artifacts into a single file called myfile.txt
#>



    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0 )]
        [ValidateNotNullOrEmpty()]
        [Alias("ID")]
        [String[]]
        $ArtifactID,
        # Parameter help description
        [Parameter(Mandatory = $false)]
        [ValidateSet('Unicode', 'ASCII', 'UTF8')]
        [string]
        $Encoding

    )
    begin {
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    Process {
        foreach ($_ArtifactID in $ArtifactID) {
            Write-Verbose "Retrieving artifact for ID $_ArtifactID "
            $artifact = $repo._repository.Artifacts.Get("$_ArtifactID")
            Write-Verbose "Retrieving content from $($artifact.ID)"
            $content = $repo._repository.Artifacts.GetContent($artifact)

            switch ($Encoding) {
                "Unicode" {
                    $result = [System.Text.Encoding]::Unicode.GetString($content.ToArray())
                    break
                }
                "ASCII" {
                    $result = [System.Text.Encoding]::ASCII.GetString($content.ToArray())
                    break
                }
                "UTF8" {
                    $result = [System.Text.Encoding]::UTF8.GetString($content.ToArray())
                    break
                }
                Default {
                    $result = [System.Text.Encoding]::Default.GetString($content.ToArray())
                }
            }
            $result.substring(1)
        }
    }

    end {}

}


