function Get-GitReference {
    <#
.SYNOPSIS
    Returns the git reference resource
.DESCRIPTION
    Returns the git reference resource for a given git branch
.EXAMPLE
    PS C:\> Get-GitReference -Project MyProject2 -GitBranch main
    Returns git reference  object of a project
.EXAMPLE
    PS C:\> Get-GitReference -Project MyProject2
    Returns git reference object for the default branch of a project
#>
    [CmdletBinding(DefaultParameterSetName = 'Project',
        PositionalBinding = $false)]
    Param (
        # Param1 help description
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = 'Project')]
        [ValidateNotNullOrEmpty()]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]
        $Project,
        # Git branch name. Optional if source controlled project
        [Parameter(mandatory = $false,
            ParameterSetName = 'Project' )]
        [String]
        $GitBranch
    )

    begin {
        Test-OctopusConnection | Out-Null
    }

    process {
        $projectBranch = Get-GitBranch -Project $project
        $gitReference = $null
        if (!$projectBranch -and $GitBranch) {
            $myError = Get-CustomError -Message "Project $($projec.name) is not version controlled and has no branch called $GitBranch" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
            $PSCmdlet.WriteError($myError)
            return
        } elseif (!$projectBranch) {
            return
        } elseif ($GitBranch -and $projectBranch) {
            if ($projectBranch.name -contains $GitBranch) {
                $gitReference = ($projectBranch | Where-Object name -EQ $GitBranch).CanonicalName
            } else {
                $myError = Get-CustomError -Message "Project $($projec.name) has no branch called $GitBranch" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
                $PSCmdlet.WriteError($myError)
                return
            }
        } elseif ($projectBranch -and (-not $GitBranch)) {
            $gitReference = ($projectBranch | Where-Object IsDefault -EQ $true).CanonicalName
        } elseif ((-not $projectBranch) -and $GitBranch) {
            $myError = Get-CustomError -Message "Project $($projec.name) is not source controlled" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
            $PSCmdlet.WriteError($myError)
            return
        }
        if ($gitReference) {
            $GitReferenceResource = [Octopus.Client.Model.SnapshotGitReferenceResource]::new()
            $GitReferenceResource.GitRef = $gitReference
        }
        return $GitReferenceResource
    }

    end {}
}
