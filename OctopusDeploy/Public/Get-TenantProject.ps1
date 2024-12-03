
function Get-TenantProject {
    <#
.SYNOPSIS
    Returns a list of Projects with Environments
.DESCRIPTION
    Returns a list of Projects with
.EXAMPLE
    PS C:\> Get-TenantProject
    Returns a list of all Projects with Environments connected for all tenants
.EXAMPLE
    PS C:\> Get-TenantProject -Tenant 'XXROM001'
    Returns a list of all Projects with Environments connected to the tenant named XXROM001
.EXAMPLE
PS C:\> Get-TenantProject -Tenant 'DEKAE99Z', 'CHZRZ99A'
Returns a list of all Projects with Environments connected to the tenants named DEKAE99Z and CHZRZ99A
.EXAMPLE
    PS C:\> Get-Tenant -Tag Region/AT | Get-TenantProject -Environment Production
    Returns a list of all Projects in 'Production' for all tenants with the tag  'Region/AT'
.
#>
    [CmdletBinding()]
    param (
        # tenant you want the variables for
        [parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ParameterSetName = "tenant")]
        [TenantTransformation()]
        [Octopus.Client.Model.TenantResource[]]$Tenant,

        # provide environment if you only want tenant vars for a certain environment
        [Parameter(Mandatory = $false,
            ParameterSetName = "tenant")]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]$Environment

    )
    begin {
        # testing connection to octopus
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        $allEnvs = Get-Environment
        $allproj = Get-Project

    }
    process {
        # variables types [System.Enum]::GetNames([Octopus.Client.Model.VariableSetContentType])
        if (! $Tenant){
            $Tenant = Get-Tenant
        }
        foreach ($_tenant in $Tenant) {
            $projEnv = $_tenant.ProjectEnvironments.GetEnumerator()
            if ($projEnv) {
                foreach ($pe in $projEnv) {
                    #$project = Get-Project -ID $pe.Key
                    $project = $allproj | Where-Object ID -EQ $pe.Key
                    foreach ($e in $pe.Value) {
                        # if environment was passed into function check if it the same as the current envirvonment. if not continuew
                        if ($Environment -and $e -ne $Environment.id) {
                            continue
                        }

                        $env = $allEnvs | Where-Object id -EQ $e

                        #"{0} - {1}" -f $project.name, $env.name
                        [PSCustomObject]@{
                            TenantName      = $_tenant.name
                            ProjectName     = $project.name
                            EnvironmentName = $env.name
                        }

                    }
                }
            }
        }
    }
    end {}

}
