function Get-Runbook {
    <#
.SYNOPSIS
    Retrieves runbook objects from an Octopus Deploy instance.

.DESCRIPTION
    The Get-Runbook function retrieves runbook objects from Octopus Deploy. 
    
    When called without parameters, it returns all non-Configuration as Code (CaC) runbooks.
    
    When a Project is specified, it returns runbooks for that project. For projects stored in 
    Configuration as Code (CaC), you can optionally specify a branch name to retrieve runbooks 
    from a specific Git branch. If no branch is specified for a CaC project, the default branch 
    will be used.

.PARAMETER Project
    The project for which to retrieve runbooks. This parameter accepts a ProjectResource object 
    or a string that will be transformed into a ProjectResource using the ProjectSingleTransformation 
    attribute. This parameter is mandatory when using the 'byProject' parameter set.

.PARAMETER BranchName
    Optional. The Git branch name from which to retrieve runbooks for Configuration as Code projects. 
    This can be either the canonical name (e.g., './.git/refs/heads/main') or the short branch name 
    (e.g., 'main'). If not specified, the default branch will be used. This parameter is only valid 
    when used with the Project parameter.

.EXAMPLE
    PS C:\> Get-Runbook
    
    Retrieves all non-Configuration as Code runbooks from the current Octopus Deploy space.
    Note: This does not return CaC runbooks. To get CaC runbooks, use the -Project parameter.

.EXAMPLE
    PS C:\> Get-Runbook -Project 'Install RS'
    
    Retrieves all runbooks for the 'Install RS' project. If the project uses Configuration as Code,
    runbooks from the default branch will be returned.

.EXAMPLE
    PS C:\> Get-Runbook -Project 'Install RS' -BranchName 'main'
    
    Retrieves all runbooks for the 'Install RS' project from the 'main' branch (for CaC projects).

.EXAMPLE
    PS C:\> Get-Runbook -Project 'Install RS' -BranchName 'refs/heads/main'
    
    Retrieves all runbooks for the 'Install RS' project from a specific feature branch using the 
    canonical branch name.

.NOTES
    - Requires an active connection to Octopus Deploy (use Connect-Octopus first)
    - For Configuration as Code projects, branch information is retrieved to determine runbook versions
    - Non-CaC projects will return runbooks regardless of the BranchName parameter
    
.LINK
    Get-GitBranch
    Connect-Octopus
    Get-Project
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(mandatory = $true,
            ValueFromPipeline = $false,
            ParameterSetName = 'byProject' )]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]
        $Project,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            ParameterSetName = 'byProject' )]
        [String]
        $BranchName
    )
    begin {
        # Validate that we have an active connection to Octopus Deploy
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        
        # Retrieve all non-CaC runbooks from the repository (used for default parameter set)
        $all = $repo._repository.runbooks.findall()
    }
    process {
        # Handle the default parameter set - returns all non-CaC runbooks
        if ($PSCmdlet.ParameterSetName -eq 'default') {
            Write-Warning "This returns all non CaC runbooks. To get CaC runbooks add the project and optional branch."
            $repo._repository.runbooks.findall()
            return $all
            
        }
        # Handle the byProject parameter set - returns runbooks for a specific project
        elseif ($PSCmdlet.ParameterSetName -eq 'byProject') {
            # Get all branches for the specified project (returns empty if not a CaC project)
            $branches = Get-GitBranch -Project $Project
            
            # Check if a specific branch name was provided
            if ($BranchName) {
                # Filter to find the matching branch by name or canonical name
                $branches = $branches | Where-Object { $_.Name -eq $BranchName -or $_.CanonicalName -eq $BranchName}
                
                # If no matching branch is found, throw an error
                if (-not $branches) {
                    $myError = Get-CustomError -Message "Project $($Project.name) has no branch called $BranchName" -Category InvalidData -Exception Octopus.Client.Exceptions.OctopusResourceNotFoundException
                    $PSCmdlet.WriteError($myError)
                    return
                }
                Write-Verbose "Using branch $($branches.canonicalName) to get runbooks"
            }
            
            # If no branches exist, the project is not version controlled (not CaC)
            # Return all runbooks for the project without branch context
            if (-not $branches) {
                Write-Verbose "$($Project.name) is not version controlled or has no branches"
                return $repo._repository.Projects.GetAllRunbooks($Project)
            }
            else {
                # Multiple branches exist - if no specific branch was requested, use the default branch
                if ($branches.count -gt 1){
                    $branches = $branches | Where-Object { $_.IsDefault -eq $true}
                    Write-Verbose "Multiple branches found. Using default branch $($branches.canonicalName)"
                }
                
                # Return runbooks for the specified/default branch
                return $repo._repository.Projects.GetAllRunbooks($Project, $branches.CanonicalName)
            }
            
            # This line should never be reached - included as a safety check
            Write-Error "this code should not be reached"
        }

    }
    end {}
}

