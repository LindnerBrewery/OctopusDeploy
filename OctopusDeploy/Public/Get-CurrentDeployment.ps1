function Get-CurrentDeployment {
    <#
    .SYNOPSIS
        Gets a list of current deployments for a given project and environment
    .DESCRIPTION
        Gets a list of current deployments for a given project and environment. This is the same as the project overview on the website
    .EXAMPLE
        PS C:\> Get-CurrentDeployment -Projects 'test project' -Environment Production
        Returns a list with Project name, Tenant id, last success release version and the deployment object
    .EXAMPLE
        PS C:\> Get-CurrentDeployment -Project 'Test Project', "Install solution" -IncludeTenantNames
        Returns a list with Project name, Tenant name, and the deployment object
    #>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'default')]
        [ValidateNotNullOrEmpty()]
        [ProjectTransformation()]
        [Octopus.Client.Model.ProjectResource[]]
        $Project,

        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'default')]
        [EnvironmentTransformation()]
        [Octopus.Client.Model.EnvironmentResource[]]
        $Environment = (Get-Environment),


        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'default')]
        [switch]
        $IncludeTenantNames,
        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'default')]
        [switch]
        $IncludeAllSucessful

    )
    begin {
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        if ($IncludeTenantNames.IsPresent) {
            $tenant = Get-Tenant
        }
        #$tenant = Get-Tenant
    }
    process {
        if ($IncludeAllSucessful.IsPresent) {
            $deployments = $repo._repository.Dashboards.GetDynamicDashboard($Project.id, $Environment.id, [Octopus.Client.Model.DashboardItemsOptions]::IncludeCurrentAndPreviousSuccessfulDeployment).items
        } else {
            $deployments = $repo._repository.Dashboards.GetDynamicDashboard($Project.id, $Environment.id, [Octopus.Client.Model.DashboardItemsOptions]::IncludeCurrentDeploymentOnly).items
        }
        $deployments | ForEach-Object {
            if ($IncludeTenantNames.IsPresent) {
                $tenantproperty = ($tenant | Where-Object ID -EQ $_.TenantId).name
            } else {
                $tenantproperty = $_.TenantId
            }

            [ProjectDeploymentObject]::new((($project | Where-Object Id -EQ $_.projectid).name),
                $tenantproperty,
                (($Environment | Where-Object Id -EQ $_.environmentid).name),
                ($_.ReleaseVersion),
                ($_.State),
                $_
            )

            <#
            [PSCustomObject]@{
                PSTypeName   = 'ProjectDeploymentObject'
                Project      = ($project | Where-Object Id -EQ $_.projectid).name # | Select-Object Name
                Tenant       = $tenantproperty
                Environment = ($Environment | Where-Object Id -EQ $_.environmentid).name
                Version      = $_.ReleaseVersion
                Deployment   = $_
            }

            $TypeData = @{
                TypeName = 'ProjectDeploymentObject'
                DefaultDisplayPropertySet = 'Project','Environment'
            }
            Update-TypeData @TypeData
#>
        }
    }
    end {}
}
