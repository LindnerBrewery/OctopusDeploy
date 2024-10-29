function Get-SourceScriptsInGit {
    <#
    .SYNOPSIS
        Retrieves the source scripts in a Git repository for a given Octopus Deploy project.

    .DESCRIPTION
        The Get-SourceScriptsInGit function retrieves the source scripts in a Git repository for a specified Octopus Deploy project. It iterates through each project, retrieves the deployment steps, and checks if the script source is a Git repository. If so, it creates a custom object with the project name, step name, Git repository URL, and script name.

    .PARAMETER Project
        Specifies the Octopus Deploy project for which to retrieve the source scripts. This parameter is mandatory and can be provided via the pipeline.

    .EXAMPLE
        Get-SourceScriptsInGit -Project $project

        Retrieves the source scripts in a Git repository for the specified Octopus Deploy project.
    .EXAMPLE
        Get-Projects | Get-SourceScriptsInGit

        Retrieves the source scripts in a Git repository for all Octopus Deploy projects.

    .INPUTS
        Octopus.Client.Model.ProjectResource

    .OUTPUTS
        System.Management.Automation.PSCustomObject

    #>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = 'default',
            HelpMessage = "Specifies the Octopus Deploy project for which to retrieve the source scripts.")]
        [ValidateNotNullOrEmpty()]
        [ProjectTransformation()]
        [Octopus.Client.Model.ProjectResource[]]
        $Project,

        # Runbook to use
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            Position = 1,
            ParameterSetName = 'default',
            HelpMessage = "Specifies the Octopus Deploy runbook for which to retrieve the source scripts.")]
        [ValidateNotNullOrEmpty()]
        [RunbookTransformation()]
        [Octopus.Client.Model.RunbookResource[]]
        $Runbook,
        # add string to define if only runbooks processes project deployment processes or both should be returned (ProjectDeployment, Runbook or both. default is both)
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            Position = 2,
            ParameterSetName = 'default',
            HelpMessage = "Specifies the Octopus Deploy runbook for which to retrieve the source scripts.")]
        [ValidateSet("ProjectDeployment", "Runbook", "Both")]
        [String]
        $Type = "Both"

    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {
        # pass $runbook to $runb to ensure that runbook transformation isn't called when $runbook is assigned.
        $runb = $runbook
        # if runbook and project are specified, throw error that you cannot specify both
        if ($null -ne $Project -and $null -ne $runb) {
            Throw "You cannot specify both a project and a runbook. Please specify only one."
        }

        # If runbook and project are not specified, get all projects and runbooks
        if ($null -eq $Project -and $null -eq $runb) {
            $Project = Get-Project
            $runb = Get-Runbook
        }

        # if online project is specified, get the project and runbooks for those projects
        if ($null -ne $Project -and $null -eq $runb) {
            try {
                $runb = Get-Runbook -Project $Project -ErrorAction stop
            }
            catch {
                throw $_
            }
        }
        if ($null -ne $runb -and $null -eq $Project) {
            $type = "Runbook"
        }

        # create progress bars
        # switch statement to check $type
        switch ($type) {
            'ProjectDeployment' { Write-Progress -Activity "Deployment Processes" -Id 1 -PercentComplete 0}
            'Runbook' { Write-Progress -Activity "Runbook Processes" -Id 2 -PercentComplete 0}
            'Both' {
                Write-Progress -Activity "Deployment Processes" -Id 1 -PercentComplete 0
                Write-Progress -Activity "Runbook Processes" -Id 2 -PercentComplete 0 -Status "Waiting for Deployment Processes to finish"
            }
            Default {}
        }

        if ($Type -eq "ProjectDeployment" -or $Type -eq "Both") {
            $Project = $Project | Sort-Object -Property name
            foreach ($proj in $project) {
                # only write process if there are more than one project
                if ($project.Count -gt 1) {
                    Write-Progress -Id 1 -Activity "Deployment Processes" -Status "Processing $($project.IndexOf($proj) + 1) of $($project.Count): $($proj.name)" -PercentComplete (($project.IndexOf($proj) + 1) / $project.Count * 100)
                }
                $steps = Get-DeploymentProcessSteps -Project $proj
                foreach ($step in $steps) {
                    $script = $step.actions.properties."Octopus.Action.Script.ScriptFileName".value
                    if ($null -ne $script -and $($step.actions.properties."Octopus.Action.Script.ScriptSource".value) -eq "GitRepository") {
                        [pscustomobject]@{
                            Project = $proj.name
                            Runbook = $null
                            Step    = $step.name
                            GitRepo = $step.actions.gitdependencies.RepositoryUri
                            Script  = $script
                        }
                    }
                }
            }

        }
        if (($Type -eq "Runbook" -or $Type -eq "Both") -and $null -ne $runb) {
            $runb = $runb | Sort-Object -Property name
            foreach ($rb in $runb) {
                # only write process if there are more than one project
                if ($runb.Count -gt 1) {
                    Write-Progress -Id 2 -Activity "Runbook Processes" -Status "Processing $($runb.IndexOf($rb) + 1) of $($runb.Count): $($rb.name)" -PercentComplete (($runb.IndexOf($rb) + 1) / $runb.Count * 100)
                }
                $steps = Get-RunbookProcessStep -Runbook $rb
                foreach ($step in $steps) {
                    $script = $step.actions.properties."Octopus.Action.Script.ScriptFileName".value
                    if ($null -ne $script -and $($step.actions.properties."Octopus.Action.Script.ScriptSource".value) -eq "GitRepository") {
                        [pscustomobject]@{
                            Project = (Get-Project -ID $rb.ProjectId).name
                            Runbook = $rb.name
                            Step    = $step.name
                            GitRepo = $step.actions.gitdependencies.RepositoryUri
                            Script  = $script
                        }
                    }
                }
            }

        }
        Write-Progress -Id 1 -Activity "Deployment Processes" -Completed
        Write-Progress -Id 2 -Activity "Runbook Processes" -Completed
    }
    end {
    }
}
