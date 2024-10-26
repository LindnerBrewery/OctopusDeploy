function Get-RunbookRunPreview {
    <#
.SYNOPSIS
    Runs a runbook snapshot on one or more specified tenants
.DESCRIPTION
    Runs a runbook snapshot on one or more specified tenants. Scheduling is optional
.EXAMPLE
    PS C:\> Get-RunbookRunPreview -RunbookSnapshot "RunbookSnapshots-1541" -Tenant XXROM001  -Environment Production
    Runs the Runbook Snapshot with the ID "RunbookSnapshots-1541" on the defined tenant in th production environment
.EXAMPLE
    PS C:\> Get-RunbookRunPreview -Runbook "New Runbook" -Tenant XXROM001  -Environment Production
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

        [Parameter(Mandatory = $true,
            ParameterSetName = 'Snapshot')]
        [Parameter(Mandatory = $true,
            ParameterSetName = 'RunbookPublished')]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]
        $Tenant,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'Snapshot')]
        [Parameter(Mandatory = $true,
            ParameterSetName = 'RunbookPublished')]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]
        $Environment
    )

    begin {}

    process {
        # TODO: implement for non tenanted runbook runs
        if (!$runbook -and !$PSBoundParameters.confirm) {
            $runbook = Get-Runbook -ID $runbookSnapshot.RunbookId
        }
        if (! $runbookSnapshot) {
            $project = Get-Project -ID $runbook.ProjectId
            if ($null -eq $runbook.PublishedRunbookSnapshotId) {
                $message = "'{0}/{1}' hasn't got a published snapshot" -f $project.name , $runbook.name
                try {
                    Throw $message
                } catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
            $runbookSnapshot = Get-RunbookSnapshot -SnapshotID $runbook.PublishedRunbookSnapshotId
        } else {
            $project = Get-Project -ID $runbookSnapshot.ProjectId
        }

        # Tenanted runbookrun preview. Untenanted needs to be implemented
        # check if tenant, project environment combination is valid
        if (! ($Tenant.ProjectEnvironments[$Project.id] -contains $Environment.Id)) {
            $message = "'{0}' is not connected to '{1}' in '{2}'" -f $Tenant.name, $Project.name, $Environment.name

            try {
                Throw $message
            } catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }

        $runbookTemplate = $repo._repository.RunbookSnapshots.GetTemplate($runbookSnapshot)
        $promotion = ($runbookTemplate.TenantPromotions | Where-Object id -EQ $tenant.id).PromoteTo | Where-Object ID -EQ $environment.Id

        $preview = $repo._repository.RunbookSnapshots.GetPreview($promotion)

        # Go through all steps and return involved machines
        foreach ($step in $preview.StepsToExecute) {
            [PSCustomObject]@{
                Number             = $step.actionnumber
                Name               = $step.actionname
                Machine            = @($step.Machines.name | Where-Object { $_ -notin $step.UnavailableMachines.name }) -join ", "
                UnavailableMachine = @($step.UnavailableMachines.name) -join ", "
            }
        }

    }



    end {}
}
