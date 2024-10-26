function Get-DeploymentProcessSteps {
    <#
.SYNOPSIS
    Returns the steps of a deployment for a given project or project
.DESCRIPTION
    Returns the steps of a deployment for a given project or release. If a version controlled project is used you can also define the branch
.EXAMPLE
    PS C:\> Get-DeploymentProcessSteps -Project "MyProject"
    Returns the steps of "MyProject" and default branch if version controlled
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
        Test-OctopusConnection | Out-Null
    }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'Project') {
            return (Get-DeploymentProcess -Project $Project -GitBranch $GitBranch).steps
        }
        return (Get-DeploymentProcess -Release $Release).steps
    }
}
