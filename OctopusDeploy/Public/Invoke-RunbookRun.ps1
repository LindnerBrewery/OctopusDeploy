function Invoke-RunbookRun {
    <#
.SYNOPSIS
    Runs a runbook snapshot on one or more specified tenants
.DESCRIPTION
    Runs a runbook snapshot on one or more specified tenants. Scheduling is optional
.EXAMPLE
    PS C:\> Invoke-RunbookRun -RunbookSnapshot "RunbookSnapshots-1541" -Tenant XXROM001  -Environment Production
    Runs the Runbook Snapshot with the ID "RunbookSnapshots-1541" on the defined tenant in th production environment
.EXAMPLE
    PS C:\> Invoke-RunbookRun -Runbook "" -Tenant XXROM001  -Environment Production
    Runs the Runbook Snapshot with the ID "RunbookSnapshots-1541" on the defined tenant in th production environment

#>
    [CmdletBinding(DefaultParameterSetName = 'default',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'http://www.google.com/',
        ConfirmImpact = 'High')]
    param (
        # If only runbook is provided then the published snapshot should be used
        # Parameter help description
        [Parameter(Mandatory = $true,
            ParameterSetName = 'RunbookPublished')]
        [RunbookSingleTransformation()]
        [Octopus.Client.Model.RunbookResource]
        $Runbook,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'Snapshot')]
        [RunbookSnapshotSingleTransformation()]
        [Octopus.Client.Model.RunbookSnapshotResource]
        $RunbookSnapshot,

        [Parameter(Mandatory = $false)]
        [TenantTransformation()]
        [Octopus.Client.Model.TenantResource[]]
        $Tenant,

        [Parameter(Mandatory = $true)]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]
        $Environment,

        # property help
        [Parameter(Mandatory = $false)]
        [Datetime]
        $QueueTime,

        # property help
        [Parameter(Mandatory = $false)]
        [Int16]
        $ExpiryInMin = 60,
        
        # Formvalue. Accepts a dictionary with the variable id as key and value as value
        [Parameter(Mandatory = $false)]
        [Hashtable]$FormValue,

        [Parameter(Mandatory = $false)]
        [switch]
        $Force
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
        if (!$runbook -and !$PSBoundParameters.confirm) {
            $runbook = Get-Runbook -ID $runbookSnapshot.RunbookId
        }
        if (! $runbookSnapshot) {
            $project = Get-Project -ID $runbook.ProjectId
            if ($null -eq $runbook.PublishedRunbookSnapshotId) {
                $message = "'{0}/{1}' hasn't got a published snapshot" -f $project.name , $runbook.name
                try {
                    Throw $message
                }
                catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
            $runbookSnapshot = Get-RunbookSnapshot -ID $runbook.PublishedRunbookSnapshotId
        }
        else {
            $project = Get-Project -ID $runbookSnapshot.ProjectId
        }
        #if tenant is provided check if project allows tenanted deployments
        if ($Tenant) {
            # check if project supports tenanted deployments
            if ($project.TenantedDeploymentMode -eq 'Untenanted') {
                $message = "'{0}' does not support tenanted deployments" -f $project.name
                try {
                    Throw $message
                }
                catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
        }
        else {
            # check if project supports untenanted deployments
            if ($project.TenantedDeploymentMode -eq 'Tenanted') {
                $message = "'{0}' does not support untenanted deployments" -f $project.name
                try {
                    Throw $message
                }
                catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
        }

        if ($force -or $PSCmdlet.ShouldProcess($shouldMessage1 , $shouldMessage2 )) {

            # Create a new runbook run object
            $runbookRun = [Octopus.Client.Model.RunbookRunResource]::new()
            $runbookRun.EnvironmentId = $environment.Id
            $runbookRun.ProjectId = $RunbookSnapshot.ProjectId
            $runbookRun.RunbookSnapshotId = $RunbookSnapshot.ID
            $runbookRun.RunbookId = $RunbookSnapshot.RunbookId
            $runbookRun.TenantId = $_tenant.Id
            if ($QueueTime) {
                $runbookRun.QueueTime = $QueueTime
                $runbookRun.QueueTimeExpiry = $QueueTime.AddMinutes($ExpiryInMin)
            }

            # Add variables to runbook run if passed in
            if ($FormValue) {
                foreach ($key in $FormValue.keys) {
                    $runbookRun.FormValues.Add($key, $FormValue[$key])
                }
            }
            if ($Tenant) {
                #run Tenanted runbook for each tenant
                foreach ($_tenant in $Tenant) {
                    # before running the runbook check if the tenant is connected to the project environment
                    if (! ($_tenant.ProjectEnvironments[$Project.id] -contains $Environment.Id)) {
                        $message = "'{0}' is not connected to '{1}' in '{2}'" -f $_tenant.name, $Project.name, $Environment.name

                        try {
                            Throw $message
                        }
                        catch {
                            $PSCmdlet.WriteError($_)
                        }
                    }

                    $runbookRun.TenantId = $_tenant.id
                    try {
                        $repo._repository.RunbookRuns.Create($runbookRun)
                    }
                    catch {
                        $PSCmdlet.WriteError($_)
                    }
                }
            }
            else {
                # Execute runbook without tenant
                try {
                    $repo._repository.RunbookRuns.Create($runbookRun)
                }
                catch {
                    $PSCmdlet.WriteError($_)
                }
            }

        }

    }

    end {}
}
