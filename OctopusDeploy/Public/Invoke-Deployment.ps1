function Invoke-Deployment {
    <#
.SYNOPSIS
    Deploys a (tenanted) release - Work in progress
.DESCRIPTION
    Deploys a  release. Currently only tenanted deployments are supported
.EXAMPLE
    PS C:\> Invoke-Deployment -Release (Get-Release -Project 'Microsoft Dot Net Framework' -latest) -tenant XXROM001 -Environment Development -whatif
    Returns what step would be executed on which targets
.EXAMPLE
    PS C:\> Invoke-Deployment -Release (Get-Release -Project 'Microsoft Dot Net Framework' -latest) -tenant XXROM001 -Environment Development
    Invokes the deployment
.EXAMPLE
    PS C:\> $exampleFormValue = @{
                'Variable1' = 'Value1'
                'Variable2' = 'Value2'
    }
    PS C:\> Invoke-Deployment -Release (Get-Release -Project 'Microsoft Dot Net Framework' -latest) -Tenant XXROM001 -Environment Development -FormValue $exampleFormValue
#>
    [CmdletBinding(SupportsShouldProcess = $true,
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
        $Environment,

        # Formvalue. Accepts a dictionary with the variable id as key and value as value
        [Parameter(Mandatory = $false)]
        [Hashtable]$FormValue,

         # StepsToSkip.List of Step Ids to skip
         [Parameter(Mandatory = $false)]
         [String[]]$StepIdToExclude,

        # property help
        [Parameter(Mandatory = $false)]
        [Datetime]
        $QueueTime,

        # property help
        [Parameter(Mandatory = $false)]
        [Int16]
        $ExpiryInMin = 60,

        # property help
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
        $project = Get-Project -ID $release.ProjectId

        $shouldMessage1 = "{0} in {1}" -f $tenant.name, $environment.name
        $shouldMessage2 = "Deploy {0} {1}" -f $project.name, $release.Version
        if ($Tenant) {
            # check if project supports tenanted deployments
            if ($project.TenantedDeploymentMode -eq 'Untenanted') {
                $message = "'{0}' does not support tenanted deployments" -f $project.name
                try {
                    Throw $message
                } catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }

            # check if tenant, project environment combination is valid for a tenanted deployment
            if (! ($Tenant.ProjectEnvironments[$Project.id] -contains $Environment.Id)) {
                $message = "'{0}' is not connected to '{1}' in '{2}'" -f $Tenant.name, $Project.name, $Environment.name

                try {
                    Throw $message
                } catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
        }else {
            # check if project supports untenanted deployments
            if ($project.TenantedDeploymentMode -eq 'Tenanted') {
                $message = "'{0}' does not support untenanted deployments" -f $project.name
                try {
                    Throw $message
                } catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
        }
        if ($force -or $PSCmdlet.ShouldProcess($shouldMessage1 , $shouldMessage2 ) ) {
            # convert steps to skip to a
            $stepSkipList = [System.Collections.Generic.List[string]]::new()
            foreach ($step in $StepIdToExclude) {
                $stepSkipList.Add($step)
            }

            $deployment = [Octopus.Client.Model.DeploymentResource]::new()
            $deployment.ReleaseId = $release.Id
            $deployment.ProjectId = $release.ProjectId
            $deployment.EnvironmentId = $environment.Id
            if ($Tenant) {
                $deployment.TenantId = $tenant.id
            }
            if ($QueueTime) {
                $deployment.QueueTime = $QueueTime
                $deployment.QueueTimeExpiry = $QueueTime.AddMinutes($ExpiryInMin)
            }

            if ($stepSkipList) {
                $deployment.SkipActions = $stepSkipList
            }

            # Add variables to deployment if passed in
            if ($FormValue) {
                foreach ($key in $FormValue.keys) {
                    $deployment.FormValues.Add($key, $FormValue[$key])
                }
            }
            try {
                $repo._repository.Deployments.Create($deployment)
            } catch {
                $PSCmdlet.WriteError($_)
            }
        }
    }

    end {}
}

