function Get-DeploymentProcess {
    <#
.SYNOPSIS
    Returns the deployment process for a given project or release
.DESCRIPTION
    Returns the deployment process for a given project or release. If a version controlled project is used you can also define the branch
.EXAMPLE
    PS C:\> Get-DeploymentProcess -Project "MyProject"
    Returns the deployment process for "MyProject" and default branch if version controlled
.EXAMPLE
    PS C:\> Get-DeploymentProcessSteps -Project "MyProject" -GitBranch "featureBranch"
    Returns the steps of "MyProject" defined in the given branch
.EXAMPLE
    PS C:\>  Get-DeploymentProcessSteps -Release (Get-Release -Project "MyProject" -Latest)
    Returns the steps for the latest "MyProject"

#>
    [CmdletBinding(DefaultParameterSetName = "Project")]
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
        # Git branch name. Optional if source controlled project
        [Parameter(mandatory = $false,
            ParameterSetName = 'Project' )]
        [String]
        $GitBranch,

        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromPipeline = $true,
            ParameterSetName = 'byRelease' )]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.ReleaseResource]
        $Release
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
        if ($PSCmdlet.ParameterSetName -eq 'Project') {
            $GitReferenceResource = Get-GitReference -Project $project -GitBranch $GitBranch -ErrorAction Stop
            # Get deployment process
            if ($GitReferenceResource) {
                return $repo._repository.DeploymentProcesses.Get($project, $GitReferenceResource.GitRef)
            } else {
                return $repo._repository.DeploymentProcesses.Get($project)
            }
        }
        return $repo._repository.DeploymentProcesses.Get($release.ProjectDeploymentProcessSnapshotId)

    }
}
