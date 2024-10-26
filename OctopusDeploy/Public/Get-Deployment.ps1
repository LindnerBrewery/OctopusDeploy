function Get-Deployment {
<# TODO:
.SYNOPSIS
    Returns a list of deployments
.DESCRIPTION
    Returns a list of deployments depending on input parameters
.EXAMPLE
    PS C:\> Get-RunbookRun
    Returns all runbook runs
.EXAMPLE
    PS C:\> Get-Deployment -ID Deployments-16969
    Returns the deployment with the id Deployments-16969
.EXAMPLE
    PS C:\> Get-Release -Project "install solution" -latest -channel default | Get-Deployment
    Returns all deployments of the latest "install Solution" release
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'byID' )]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $ID,
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromPipeline = $true,
            ParameterSetName = 'byRelease' )]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.ReleaseResource]
        $Release

    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'byID') {
            return $repo._repository.Deployments.get($ID)
        }
        if ($PSCmdlet.ParameterSetName -eq 'byRelease') {
            $func = {
                param($ff)
                $true
            }
            return $repo._repository.Deployments.FindMany($func, $Release.Links.Deployments)
        }
    }
    end {}
}

