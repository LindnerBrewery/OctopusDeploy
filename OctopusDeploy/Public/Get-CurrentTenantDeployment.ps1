function Get-CurrentTenantDeployment {
    <#
    .SYNOPSIS
        Returns the latest successful deployments for a tenant.

    .DESCRIPTION
        Returns a list of the latest successful deployments for a tenant, grouped by project and environment.
        The function retrieves all successful deployment tasks for the specified tenant and parses the task
        description to extract project name, release version, environment, and tenant information.

    .EXAMPLE
        PS C:\> Get-CurrentTenantDeployment -Tenant 'XXRNDTCR'
        Returns all latest successful deployments for tenant XXRNDTCR across all environments.

    .EXAMPLE
        PS C:\> Get-CurrentTenantDeployment -Tenant 'XXRNDTCR' -Environment 'Test'
        Returns all latest successful deployments for tenant XXRNDTCR in the Test environment.

    .PARAMETER Tenant
        The tenant to filter by. This parameter is mandatory.

    .PARAMETER Environment
        The environment to filter by. This parameter is optional.
    #>
    [CmdletBinding(DefaultParameterSetName = 'default',
        SupportsShouldProcess = $false,
        PositionalBinding = $false,
        HelpUri = 'http://www.octopus.com/',
        ConfirmImpact = 'Low')]
    [Alias()]
    [OutputType([CurrentTenantDeployment])]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]
        $Tenant,

        [Parameter(Mandatory = $false,
            Position = 1)]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]
        $Environment
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
        # Build parameters for Get-Task
        $taskParams = @{
            Tenant   = $Tenant
            TaskType = 'Deploy'
        }

        if ($Environment) {
            $taskParams['Environment'] = $Environment
        }

        # Get all successful deployment tasks for the tenant
        $tasks = Get-Task @taskParams | Where-Object { $_.FinishedSuccessfully -eq $true }

        if (-not $tasks) {
            Write-Warning "No successful deployments found for tenant '$($Tenant.Name)'"
            return
        }

        # Parse description and group by Project+Environment to get latest
        $deploymentInfo = @{}

        foreach ($task in $tasks) {
            # Parse description: "Deploy Ris Server - Install 3rd Party Software release 2025.6.4 to Test for XXRNDTCR"
            # Split on: 'Deploy ', ' release ', ' to ', ' for '
            $description = $task.Description

            # Extract project name (between "Deploy " and " release ")
            if ($description -match '^Deploy (.+?) release (.+?) to (.+?) for (.+)$') {
                $projectName = $Matches[1]
                $version = $Matches[2]
                $envName = $Matches[3]
                $tenantName = $Matches[4]

                # Create a unique key for project+environment combination
                $key = "$projectName|$envName"

                # Check if we already have this combination and if current task is newer
                if (-not $deploymentInfo.ContainsKey($key)) {
                    $deploymentInfo[$key] = @{
                        Project     = $projectName
                        Environment = $envName
                        Tenant      = $tenantName
                        Version     = $version
                        Date        = $task.CompletedTime.DateTime
                        HasWarnings = $task.HasWarningsOrErrors
                        Task        = $task
                    }
                }
                else {
                    # Compare dates and keep the latest
                    if ($task.CompletedTime -gt $deploymentInfo[$key].Date) {
                        $deploymentInfo[$key] = @{
                            Project     = $projectName
                            Environment = $envName
                            Tenant      = $tenantName
                            Version     = $version
                            Date        = $task.CompletedTime
                            HasWarnings = $task.HasWarningsOrErrors
                            Task        = $task
                        }
                    }
                }
            }
            else {
                Write-Verbose "Could not parse task description: $description"
            }
        }

        # Output as CurrentTenantDeployment objects, sorted by Environment (A-Z) then Date (newest first)
        $result = foreach ($item in $deploymentInfo.Values) {
            [CurrentTenantDeployment]::new(
                $item.Tenant,
                $item.Environment,
                $item.Project,
                $item.Version,
                $item.Date,
                $item.HasWarnings,
                $item.Task
            )
        }
        return $result | Sort-Object -Property Environment, @{Expression = 'Date'; Descending = $true }
    }
    end {}
}
