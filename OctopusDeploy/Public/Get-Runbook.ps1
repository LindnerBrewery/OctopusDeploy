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
        $Project,

        [Parameter(mandatory = $true,
            ValueFromPipelineByPropertyName = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'byName' )]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Name,

        [Parameter(mandatory = $true,
            ValueFromPipelineByPropertyName = $false,
            ParameterSetName = 'byID' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID



    )
    begin {
        Test-OctopusConnection | Out-Null
        $all = $repo._repository.runbooks.findall()
    }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'default') {
            return $all
        }
        if ($PSCmdlet.ParameterSetName -eq 'byName') {
            if ($Project) {
                return $all | Where-Object {$_.name -like $Name -and $_.ProjectID -eq $Project.ID}
            } else {
                return $all | Where-Object name -like $Name
            }
        }
        if ($PSCmdlet.ParameterSetName -eq 'byID') {
            return $repo._repository.Runbooks.get($ID)
        }
        if ($PSCmdlet.ParameterSetName -eq 'byProject') {
            return ($project | ForEach-Object {$all  | Where-Object ProjectID -EQ $_.ID})
        }
    }
    end {}
}

