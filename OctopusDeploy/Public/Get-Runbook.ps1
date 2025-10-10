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
        # [Parameter(mandatory = $false,
        #     ValueFromPipeline = $false,
        #     ParameterSetName = 'byName' )]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]
        $Project,
        # Optional parameter branch name. This can either be the canonical name or the branch name. ./.git/refs/heads/main or main. 
        # If no branch is specified the default branch will be used
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'byProject' )]
        [String]
        $BranchName
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
            Write-Warning "This returns all non CaC runbooks. To get CaC runbooks add the project and optional branch."
            $repo._repository.runbooks.findall()
            return $all
            
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'byProject') {
            # Get the branches for the project
            $branches = Get-GitBranch -Project $Project
            # Check if the optional branch name parameter is provided
            if ($BranchName) {
                $branches = $branches | Where-Object { $_.Name -eq $BranchName -or $_.CanonicalName -eq $BranchName}
                if (-not $branches) {
                    $myError = Get-CustomError -Message "Project $($Project.name) has no branch called $BranchName" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
                    $PSCmdlet.WriteError($myError)
                    return
                }
                Write-Verbose "Using branch $($branches.canonicalName) to get runbooks"
            }
            # If no branches exist return all runbooks for the project
            if (-not $branches) {
                Write-Verbose "$($Project.name) is not version controlled or has no branches"
                return $repo._repository.Projects.GetAllRunbooks($Project)
            }else{
                # get default branch if no branch name is provided
                if ($branches.count -gt 1){
                    $branches = $branches | Where-Object { $_.IsDefault -eq $true}
                    Write-Verbose "Multiple branches found. Using default branch $($branches.canonicalName)"
                }
                return $repo._repository.Projects.GetAllRunbooks($Project, $branches.CanonicalName)
            }
            Write-Error "this code should not be reached"
        }

    }
    end {}
}

