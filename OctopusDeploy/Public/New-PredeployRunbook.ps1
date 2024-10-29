
function New-PredeployRunbook {
    <#
.SYNOPSIS
    Creates or updates a predeploy runbook which can be used to transfer packages before deployment
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    [CmdletBinding(DefaultParameterSetName = 'Parameter Set 1',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Medium')]
    [Alias("Update-PredeployRunbook")]
    #[OutputType([String])]

    Param (
        # octopus project the runbook is for
        [Parameter(mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ParameterSetName = 'Project')]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.ReleaseResource[]]
        $Release,
        # Name of the runbook.
        [Parameter(Mandatory = $false,
            Position = 1,
            HelpMessage = "Optional Name of the Runbook")]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $false,
            Position = 2,
            HelpMessage = "If set the Runbook Snapshot will be directly published")]
        [Switch]$Publish
    )

    begin {}

    process {

        $project = Get-Project -ID $release.ProjectId
        $channel = Get-Channel -ID $release.ChannelId
        # get release process snapshot for the release
        $releaseprocesses = $repo._repository.DeploymentProcesses.get($release.ProjectDeploymentProcessSnapshotId)


        # get each step of deployment process
        $steps = $releaseprocesses.Steps
        $stepsPackagesRoles = [System.Collections.ArrayList]::new()
        # iterate through each step and extract all actions that are relevant for the deployment
        foreach ($step in $steps) {
            Write-Verbose "Analyzing Step `"$($step.name)`""
            if ($step.Actions.packages) {
                Write-Verbose "Step `"$($step.name)`" contains `"$($step.Actions.packages.count)`" packages"
                foreach ($action in $step.Actions) {
                    if ($action.packages.Count -gt 0) {
                        Write-Verbose "Action `"$($step.name)/$($action.name)`" contains `"$($action.packages.Count)`" packaged"
                        if (($action.channels -contains $release.ChannelId -or $action.channels.count -eq 0) -And $action.IsDisabled -ne $true ) {
                            Write-Verbose "Action `"$($step.name)/$($action.name)`" is enabled and is part of deployment channel `"$($channel.name)`""
                            $null = $stepsPackagesRoles.add([PSCustomObject]@{
                                    StepName             = $step.Name
                                    ActionName           = $action.name
                                    TargetRoles          = $step.properties["Octopus.Action.TargetRoles"]
                                    Packages             = @($action.packages)
                                    TenantTags           = $action.TenantTags
                                    Environments         = $action.Environments
                                    ExcludedEnvironments = $action.ExcludedEnvironments
                                    ActionType           = $action.ActionType
                                })
                        } else {
                            Write-Verbose "Action `"$($step.name)/$($action.name)`" is disabled or doesn't belong to the same channel"
                        }
                    } else {
                        Write-Verbose "Action `"$($step.name)/$($action.name)`" doesn't contain any packages"
                    }
                }

            }

        }
        if (!($stepsPackagesRoles)) {
            Throw "`"$($project.name)`" - `"$($release.version)`" doesn't have any packages"
        }
        if (-not $name) {
            #set default name
            $name = "Predeploy - " + (Get-Channel -ID $release.ChannelId).name
        }
        if ($pscmdlet.ShouldProcess($repo._endpoint.OctopusServer.ToString(), "Create a predeploy runbook for the project $($project.name) release $($release.Version)")) {
            # create or modify the
            Write-Verbose "Creating or updating runbook `"$name`""
            $runbookEditor = $repo._repository.Runbooks.CreateOrModify($project , $name, "This runbook pre-deploys packages for this project")
            $runbookEditor.Instance.MultiTenancyMode = $project.TenantedDeploymentMode
            $runbookEditor.Instance.ConnectivityPolicy.AllowDeploymentsToNoTargets = $project.ProjectConnectivityPolicy.AllowDeploymentsToNoTargets
            $runbookEditor.Instance.ConnectivityPolicy.ExcludeUnhealthyTargets = $project.ProjectConnectivityPolicy.ExcludeUnhealthyTargets
            #update runbook
            $repo._repository.Runbooks.Modify($runbookEditor.Instance) | Out-Null

            #remove all existing steps from runbook
            $runbookprocess = $runbookEditor.RunbookProcess.Instance
            $runbookprocess.ClearSteps() | Out-Null
            #$runbookprocess = $repo.RunbookProcesses.Modify($runbookprocess)

            # Create a package deploy step for each package
            # This is only a reference to a package but not to a specific version.
            foreach ($_stepsPackagesRoles in $stepsPackagesRoles) {
                if ($_stepsPackagesRoles.Packages) {
                    $Stepname = $_stepsPackagesRoles.StepName
                    $role = $_stepsPackagesRoles.TargetRoles
                    $step = $runbookprocess.AddOrUpdateStep($Stepname)
                    $step.Condition = [Octopus.Client.Model.DeploymentStepCondition]::Success # Step run condition (Success = Only run if previous step succeeds)
                    if (! ($step.Properties."Octopus.Action.TargetRoles")) {
                        $step.Properties.Add("Octopus.Action.TargetRoles", $role)
                    }
                    foreach ($package in $_stepsPackagesRoles.Packages ) {
                        $scriptAction = [Octopus.Client.Model.DeploymentActionResource]::new() # Create the steps action type
                        $scriptAction.ActionType = "Octopus.TentaclePackage" # This will define this as a Script step "Octopus.Script", "Octopus.TentaclePackage"

                        # depending on ActionType the identifier to find the right version is PackageReferenceName (e.g. script step) or actionname (e.g. deploy step)
                        # Octopus.TentaclePackage step only contains one packages and the release.SelectedPackages has no PackageReferenceName. In this case the package is not identified by the the package identifier in PackageReferenceName but by the action name and therefor has to be identical to the one in the release
                        if ($_stepsPackagesRoles.actionType -eq 'Octopus.TentaclePackage') {
                            $scriptAction.Name = ($_stepsPackagesRoles.ActionName)
                        } else {
                            $scriptAction.Name = ($_stepsPackagesRoles.ActionName + "_" + $package.PackageId)
                        }
                        $pack = [Octopus.Client.Model.PackageReference]::new()
                        $pack = $package
                        $pack.name = $null
                        $scriptAction.Packages.Add($pack)
                        $step.Actions.Add($scriptAction)
                    }
                    $runbookprocess = $repo._repository.RunbookProcesses.Modify($runbookprocess)
                }

            }
            #create release publish

            # create snapshot resource
            $runbookSnapshot = [Octopus.Client.Model.RunbookSnapshotResource]::new()

            $runbookSnapshot.RunbookId = $RunbookEditor.Instance.id
            $runbookSnapshot.FrozenRunbookProcessId = $runbookprocess.Id
            $runbookSnapshot.SpaceId = $runbookprocess.SpaceId
            $runbookSnapshot.ProjectId = $runbookprocess.ProjectId

            #create short random snapshot name
            $shortRandom = ([System.IO.Path]::GetRandomFileName()).Split(".")[0]
            $runbookSnapshot.Name = $release.version + " - " + $shortRandom

            # add package version to each step to snapshot
            foreach ($rbStep in $runbookprocess.Steps) {
                foreach ($rbActions in $rbStep.Actions) {
                    foreach ($rbPackage in $rbActions.packages) {
                        $selectedPackages = [Octopus.Client.Model.SelectedPackage]::new()
                        $selectedPackages.StepName = $rbStep.Name
                        $selectedPackages.ActionName = $rbActions.Name

                        # depending on ActionType the identifier is PackageReferenceName (e.g. script step) or the action name must be the same (e.g. deploy step)
                        $selectedPackages.Version = ($release.SelectedPackages | Where-Object PackageReferenceName -EQ $rbPackage.PackageId).Version
                        if (!($selectedPackages.Version)) {
                            $selectedPackages.Version = ($release.SelectedPackages | Where-Object ActionName -EQ $rbActions.Name).Version
                        }
                        $runbookSnapshot.SelectedPackages.Add($selectedPackages)
                    }
                }
            }

            # create snapshot
            $runbookSnapshot = $repo._repository.RunbookSnapshots.Create($runbookSnapshot)

            # publish the new runbook snapshot
            if ($Publish.IsPresent) {
                Write-Verbose "Publishing runbook `"$name`" as `"$($runbookSnapshot.Name)`" in project `"$($project.name)`""
                $runbookEditor.Instance.PublishedRunbookSnapshotId = $runbookSnapshot.id
                $null = $repo._repository.Runbooks.Modify($RunbookEditor.instance)
            }
        }
    }

    end {}
}
