function Get-Runbook {
    <#
.SYNOPSIS
    Returns a list of runbook objects
.DESCRIPTION
    Returns a list of runbook objects. Either all runbooks or only the runbooks for a given project
.EXAMPLE
    PS C:\> Get-Runbook
    Returns a list of all runbook objects
.EXAMPLE
    PS C:\> Get-Runbook -Project 'Install RS'
    Returns a list of all runbook objects in the 'Install RS' project.
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description

        [Parameter(mandatory = $true,
            ValueFromPipeline = $false,
            ParameterSetName = 'byProject' )]
        [Parameter(mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'byName' )]
        [ProjectTransformation()]
        [Octopus.Client.Model.ProjectResource[]]
        $Project



    )
    begin {
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        $all = $repo._repository.runbooks.findall()
    }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'default') {
            $repo._repository.runbooks.findall()
            Write-Warning "This return all non CaC runbooks. To get CaC runbooks add the project and optional branch."
            return $all
        }
    }
    end {}
}

