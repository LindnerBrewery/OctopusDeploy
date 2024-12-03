function Get-DeploymentPreview {
    <#
.SYNOPSIS
    Returns a preview of what would be executed if the deployment would be invoked
.DESCRIPTION
    Returns a preview of what would be executed if the deployment would be invoked. Currently only tenanted deployments are supported
.EXAMPLE
    PS C:\>  Get-DeploymentPreview -Release (Get-Release -Project 'Microsoft Dot Net Framework' -latest) -tenant XXROM001 -Environment Development
    Returns what step would be executed on which targets
#>
    [CmdletBinding(SupportsShouldProcess = $false,
        ConfirmImpact = 'High')]
    param (
        # property help
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [Octopus.Client.Model.ReleaseResource]
        $Release,

        # property help
        [Parameter(Mandatory = $false)]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]
        $Tenant,

        # property help
        [Parameter(Mandatory = $true)]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]
        $Environment
        #[Switch]        $PerTarget # has to be implemented by retrieving all targets in preview an then creating single runs for each target
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
        $project = Get-Project -ID $release.ProjectId
        $releaseTemplate = $repo._repository.Releases.GetTemplate($release);

        # ToDo: implement untenanted deployments and preview. The current code will only work with tenanted deployments
        #$promotion = $releaseTemplate.PromoteTo | Where ID -eq $environment.Id

        # check if tenant, project environment combination is valid
        if (! ($Tenant.ProjectEnvironments[$Project.id] -contains $Environment.Id)) {
            $message = "'{0}' is not connected to '{1}' in '{2}'" -f $Tenant.name, $Project.name, $Environment.name
            Throw $message
        }

        # tenanted deployment preview
        $promotion = ($releaseTemplate.TenantPromotions | Where-Object id -EQ $tenant.id).PromoteTo | Where-Object ID -EQ $environment.Id
        try {
            $preview = $repo._repository.Releases.GetPreview($promotion)
        } catch {
            Throw "Can't preview deployment. Are you sure the combination of parameters are right?"
        }

        # Go through all steps and return involved machines
        foreach ($step in $preview.StepsToExecute) {
            [PSCustomObject]@{
                ActionNumber       = $step.actionnumber
                ActionName         = $step.actionname
                ActionID           = $step.actionid
                Machine            = @($step.Machines.name | Where-Object { $_ -notin $step.UnavailableMachines.name }) -join ", "
                UnavailableMachine = @($step.UnavailableMachines.name) -join ", "
            }
        }

    }

    end {}
}

