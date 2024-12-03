function Get-ReleaseTemplate {
    <#
.SYNOPSIS
    Returns a list of template packages
.DESCRIPTION
    Returns a list of template packages for a given project
.EXAMPLE
    PS C:\> Get-TemplatePackage -Project MyProject2
    Returns a list of template packages for MyProject2. This can then be used to find version of the package
#>
    [CmdletBinding(DefaultParameterSetName = 'project',
        PositionalBinding = $true)]
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

        # Deployment channel name
        [Parameter(mandatory = $false,
            ParameterSetName = 'Project')]
        [String]
        $Channel,

        # Git branch name. Optional if source controlled project
        [Parameter(mandatory = $false,
            ParameterSetName = 'Project' )]
        [String]
        $GitBranch
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
        # get a git reference if source controlled or git branch was passed in as a parameter
        # $GitReferenceResource = Get-GitReference -Project $project -GitBranch $GitBranch -ErrorAction Stop
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

        $deploymentProcess = Get-DeploymentProcess -Project $project -GitBranch $GitBranch
        # # Get deployment process
        # if($GitReferenceResource){
        #     $deploymentProcess = $repo._repository.DeploymentProcesses.Get($project,$GitReferenceResource.GitRef)
        # }else{
        #     $deploymentProcess = $repo._repository.DeploymentProcesses.Get($project)
        # }

        # Get template
        $template = $repo._repository.DeploymentProcesses.GetTemplate($deploymentProcess, $releaseChannel)
        #return the results
        return $template
    }

    end {}
}
