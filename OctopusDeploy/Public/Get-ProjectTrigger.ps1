function Get-ProjectTrigger {
    <#
.SYNOPSIS
    Returns a list of project triggers with flexible filtering
.DESCRIPTION
    Returns project triggers (deployment and runbook). Without parameters, returns all triggers.
    Use -Name and/or -Project to filter by trigger name (wildcard) and project.
    Use -Tenant to return all triggers associated with a specific tenant (cannot be combined with -Name or -Project).
.EXAMPLE
    PS C:\> Get-ProjectTrigger
    Returns all project triggers across all projects.
.EXAMPLE
    PS C:\> Get-ProjectTrigger -Name "deploy"
    Returns all triggers whose name contains "deploy".
.EXAMPLE
    PS C:\> Get-ProjectTrigger -Project "My Project"
    Returns all triggers (deployment and runbook) for the specified project.
.EXAMPLE
    PS C:\> Get-ProjectTrigger -Project "My Project" -Name "nightly"
    Returns triggers for the specified project whose name contains "nightly".
.EXAMPLE
    PS C:\> Get-ProjectTrigger -Tenant "My Tenant"
    Returns all triggers that include the specified tenant in their tenant list.
.INPUTS
    Octopus.Client.Model.ProjectResource
    Octopus.Client.Model.TenantResource
.OUTPUTS
    Octopus.Client.Model.ProjectTriggerResource
.NOTES
    The -Tenant parameter cannot be combined with -Name or -Project.
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Name of a trigger. Supports wildcard matching. Returns all triggers whose name contains the specified string.
        [Parameter(mandatory = $false,
            Position = 0,
            ParameterSetName = "default")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,
        # Project to get the triggers from. Can be combined with -Name.
        [Parameter(mandatory = $false,
            ParameterSetName = "default",
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]
        $Project,
        # Tenant to filter triggers by. Returns triggers that include this tenant. Cannot be combined with -Name or -Project.
        [Parameter(mandatory = $true,
            ParameterSetName = "byTenant",
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]
        $Tenant
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
        $triggers = $repo._repository.ProjectTriggers.FindAll()

        if ($PSCmdlet.ParameterSetName -eq "byTenant") {
            return ($triggers | Where-Object { $_.Action.TenantIds -contains $Tenant.Id })
        }

        if ($PSBoundParameters.ContainsKey("Project")) {
            $triggers = $triggers | Where-Object ProjectId -EQ $Project.Id
        }

        if ($PSBoundParameters.ContainsKey("Name")) {
            $triggers = $triggers | Where-Object { $_.Name -like "*$Name*" }
        }

        $triggers
    }

    end {}
}
