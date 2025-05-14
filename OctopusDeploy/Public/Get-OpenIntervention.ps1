function Get-OpenIntervention {
    <#
    .SYNOPSIS
    Gets open manual interventions from Octopus Deploy.

    .DESCRIPTION
    This function retrieves a list of open manual interventions from Octopus Deploy. 
    It can filter the interventions based on various criteria such as project, environment, deployment, task, or tenant.
    The function paginates through all results to ensure all interventions are retrieved.

    .PARAMETER Regarding
    Optional filter to retrieve interventions related to specific resources. Can be IDs (DeploymentId, TaskId, ProjectId, EnvironmentId, or TenantId)
    or resource objects (Project, Environment, Deployment, Task, or Tenant).

    .EXAMPLE
    PS C:\> Get-OpenInterventions
    Returns all open manual interventions across all projects.

    .EXAMPLE
    PS C:\> Get-OpenInterventions -Regarding "MyProject"
    Returns all open manual interventions for the project named "MyProject".

    .EXAMPLE
    PS C:\> Get-Project "Portal" | Get-OpenInterventions
    Returns all open manual interventions for the "Portal" project.

    .EXAMPLE
    PS C:\> Get-OpenInterventions -Regarding "Environments-123"
    Returns all open manual interventions for the environment with ID "Environments-123".

    .NOTES
    This function requires a valid connection to the Octopus Deploy server. Ensure that a connection is established before calling this function using Connect-Octopus.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, 
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [InterventionRegardingStringTransformation()]
        [String]
        $Regarding
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
        $result = [System.Collections.ArrayList]::new()
        $skip = 0
        $take = 30
        
        $page = $null
        $page = $repo._repository.Interruptions.List($skip, $take, $true, $Regarding)
        $result = $page.Items
        
        if (-not [string]::IsNullOrEmpty($Regarding)) {
            $regardingText = "regarding: $($Regarding)"
        }
        Write-Verbose "Found $($page.TotalResults) open manual interventions $regardingText"
        while ($page.links['Page.Current'] -ne $page.links['Page.Last']) {
            $skip += $take
            $page = $repo._repository.Interruptions.List($skip, $take, $true, $Regarding)
            $result += $page.Items
        }

         # Return results
        if ($result.Count -eq 1) {
            # Return single object if only one result
            return $result[0]
        } 
        else {
            # Return collection
            return $result
        }
    }

    end {
    }
}
