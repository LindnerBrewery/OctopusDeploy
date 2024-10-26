function Get-OctopusRepositoryObject {
<#
.SYNOPSIS
    Returns information about the current connection to octopus
.DESCRIPTION
    Returns information about the current connection to octopus - LogonType, ServerURL and current user
.EXAMPLE
    PS C:\> Get-OctopusRepositoryObject
#>

    [CmdletBinding()]
    [OutputType([Octopus.Client.OctopusClient])]
    param (

    )

    begin {
    }

    process {
        $script:repo
    }

    end {

    }
}
