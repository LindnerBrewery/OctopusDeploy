function Invoke-RunbookRun {
    <#
.SYNOPSIS
    Runs a runbook on one or more specified tenants or untenanted. Supports both traditional snapshots and Configuration as Code (CaC) runbooks.

.DESCRIPTION
    Runs a runbook on one or more specified tenants or untenanted. Scheduling is optional.
    
    The function automatically detects whether the project uses Configuration as Code (CaC) or traditional snapshots:
    - For CaC projects: Runs the runbook directly from a Git branch (defaults to the project's default branch)
    - For traditional projects: Runs a published runbook snapshot
    
    When using CaC runbooks, if no BranchName is specified, the function will automatically use the project's default branch.

.PARAMETER Runbook
    The runbook to run. Can be a RunbookResource object or a string that will be transformed to a RunbookResource.
    This parameter is used for Configuration as Code (CaC) projects. When specified, the runbook will be run directly 
    from a Git branch. If no BranchName is provided, the project's default branch will be used automatically.
    This parameter is mandatory when using the 'Runbook' parameter set.

.PARAMETER RunbookSnapshot
    The runbook snapshot to run for traditional (non-CaC) projects. This parameter is used to run a published 
    snapshot of a runbook from projects that do not use Configuration as Code. This parameter is mandatory 
    when using the 'Snapshot' parameter set.

.PARAMETER BranchName
    Optional. The Git branch name to use for Configuration as Code projects. Can be either:
    - Short branch name (e.g., 'main', 'develop')
    - Canonical branch name (e.g., 'refs/heads/main')
    
    If not specified for CaC projects, the project's default branch will be used automatically.
    This parameter is ignored for traditional (non-CaC) projects.

.PARAMETER Tenant
    Optional. One or more tenants for which to run the runbook. Only valid if the project's TenantedDeploymentMode 
    is set to 'Tenanted' or 'TenantedOrUntenanted'. Each tenant will be validated to ensure it is connected to the 
    specified project and environment before execution.

.PARAMETER Environment
    Required. The environment in which to run the runbook. Must be a valid environment in the current Octopus space.

.PARAMETER QueueTime
    Optional. Schedule the runbook run to start at a specific date and time.

.PARAMETER ExpiryInMin
    Optional. Number of minutes until the scheduled run expires. Default is 60 minutes. Only applicable when 
    QueueTime is specified.

.PARAMETER FormValue
    Optional. A hashtable of form values (prompted variables) to pass to the runbook. The key should be the 
    variable name or ID, and the value is the variable value to use during the runbook run.

.PARAMETER Force
    Optional. Bypass confirmation prompts.

.EXAMPLE
    PS C:\> Invoke-RunbookRun -Runbook "test git runbook" -Environment Test
    
    Runs a CaC runbook using the project's default branch (auto-detected), untenanted.

.EXAMPLE
    PS C:\> Invoke-RunbookRun -Runbook "testgitrunbook" -Environment Test -BranchName "test"
    
    Runs a CaC runbook from the 'test' branch, untenanted.

.EXAMPLE
    PS C:\> Invoke-RunbookRun -Runbook "test git runbook" -Environment Production -BranchName "refs/heads/main" -Tenant XXROM001
    
    Runs a CaC runbook from the 'main' branch (using canonical name) for a specific tenant.

.EXAMPLE
    PS C:\> Invoke-RunbookRun -RunbookSnapshot "RunbookSnapshots-1541" -Tenant XXROM001 -Environment Production
    
    Runs a traditional runbook snapshot for a specific tenant in the Production environment.

.EXAMPLE
    PS C:\> Invoke-RunbookRun -RunbookSnapshot (Get-RunbookSnapshot -Runbook "Maintenance" -Latest) -Environment Test
    
    Runs the latest published runbook snapshot (for traditional projects) in the Test environment, untenanted.

.EXAMPLE
    PS C:\> Invoke-RunbookRun -Runbook "MaintenanceRunbook" -Tenant XXROM001, XXROM002 -Environment Production -FormValue @{'VariableName' = 'value'}
    
    Runs a CaC runbook for multiple tenants and sets a prompted variable value.

.EXAMPLE
    PS C:\> Invoke-RunbookRun -Runbook "ScheduledTask" -Environment Production -QueueTime (Get-Date).AddHours(2) -ExpiryInMin 120
    
    Schedules a CaC runbook to run in 2 hours with an expiry time of 120 minutes.

.NOTES
    - Requires an active connection to Octopus Deploy (use Connect-Octopus first)
    - The function uses parameter sets to distinguish between CaC runbooks (Runbook parameter) and traditional snapshots (RunbookSnapshot parameter)
    - For CaC projects, if no BranchName is specified, the project's default branch is used automatically
    - The BranchName parameter is only applicable to CaC projects and will be ignored for traditional projects
    - Tenant support depends on the project's TenantedDeploymentMode setting (Tenanted, Untenanted, or TenantedOrUntenanted)
    - When using the Runbook parameter, the project must be a Configuration as Code project
    - When using the RunbookSnapshot parameter, the project must be a traditional (non-CaC) project
    - The Force parameter bypasses the confirmation prompt (ConfirmImpact is set to 'High')

#>
    [CmdletBinding(DefaultParameterSetName = 'Runbook',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'http://www.google.com/',
        ConfirmImpact = 'High')]
    param (
        # If only runbook is provided then the published snapshot should be used
        # Parameter help description
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Runbook')]
        [RunbookSingleTransformation()]
        [Octopus.Client.Model.RunbookResource]
        $Runbook,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'Snapshot')]
        [RunbookSnapshotSingleTransformation()]
        [Octopus.Client.Model.RunbookSnapshotResource]
        $RunbookSnapshot,

        # Git branch name for Configuration as Code runbooks (optional - defaults to project default branch)
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Runbook')]
        [String]
        $BranchName,

        [Parameter(Mandatory = $false)]
        [TenantTransformation()]
        [Octopus.Client.Model.TenantResource[]]
        $Tenant,

        [Parameter(Mandatory = $true)]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]
        $Environment,

        # property help
        [Parameter(Mandatory = $false)]
        [Datetime]
        $QueueTime,

        # property help
        [Parameter(Mandatory = $false)]
        [Int16]
        $ExpiryInMin = 60,
        
        # Formvalue. Accepts a dictionary with the variable id as key and value as value
        [Parameter(Mandatory = $false)]
        [Hashtable]$FormValue,

        [Parameter(Mandatory = $false)]
        [switch]
        $Force
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
        if ($PSCmdlet.ParameterSetName -eq 'snapshot') {
            $Runbook = Get-Runbook -ID $RunbookSnapshot.RunbookId -ErrorAction Stop
            $project = Get-Project -ID $runbookSnapshot.ProjectId -ErrorAction Stop
        }

        if ($PSCmdlet.ParameterSetName -eq 'Runbook') {
            $project = Get-Project -ID $Runbook.ProjectId -ErrorAction Stop

            # There is an edge case where the project id CaC but the runbook is not
            # this is the case when the runbook has not Link
            if ($project.isVersionControlled -and $Runbook.Links.count -gt 0) {
                Write-Verbose "Runbook '$($Runbook.Name)' is a Configuration as Code runbook."
            }
            elseif (-not $project.isVersionControlled) {
                Write-Verbose "Project '$($project.name)' is not a Configuration as Code project. Use the RunbookSnapshot parameter to run a traditional runbook snapshot."
                $message = "'{0}' is not a Configuration as Code project. Use the RunbookSnapshot parameter to run a traditional runbook snapshot." -f $project.name
                $myError = Get-CustomError -Message $message -Category InvalidData -Exception System.ArgumentException
                $PSCmdlet.WriteError($myError)
                return
            }
            else {
                Write-Verbose "Runbook '$($Runbook.Name)' is not a Configuration as Code runbook. Use the RunbookSnapshot parameter to run a traditional runbook snapshot."
                $message = "'{0}' is not a Configuration as Code runbook. Use the RunbookSnapshot parameter to run a traditional runbook snapshot." -f $Runbook.Name
                $myError = Get-CustomError -Message $message -Category InvalidData -Exception System.ArgumentException
                $PSCmdlet.WriteError($myError)
                return
            }
        }
        
        # Validate tenant mode
        if ($Tenant) {
            # check if project supports tenanted deployments
            if ($project.TenantedDeploymentMode -eq 'Untenanted') {
                $message = "'{0}' does not support tenanted deployments" -f $project.name
                $myError = Get-CustomError -Message $message -Category InvalidData -Exception System.ArgumentException
                $PSCmdlet.WriteError($myError)
                return
            }
        }
        else {
            # check if project supports untenanted deployments
            if ($project.TenantedDeploymentMode -eq 'Tenanted') {
                $message = "'{0}' does not support untenanted deployments" -f $project.name
                $myError = Get-CustomError -Message $message -Category InvalidData -Exception System.ArgumentException
                $PSCmdlet.WriteError($myError)
                return
            }
        }
    
        if ($PSCmdlet.ParameterSetName -eq 'snapshot') {
            # Traditional Project Path - use snapshot-based execution
            Write-Verbose "Project '$($project.name)' uses traditional runbook snapshots"
            
            # Prepare ShouldProcess messages
            $shouldMessage1 = "Run runbook snapshot '{0}' in environment '{1}'" -f $runbookSnapshot.Name, $environment.Name
            $shouldMessage2 = "Run {0}/{1}" -f $project.Name, $runbook.Name
            
            if ($force -or $PSCmdlet.ShouldProcess($shouldMessage1, $shouldMessage2)) {
                
                # Create a new runbook run object
                $runbookRun = [Octopus.Client.Model.RunbookRunResource]::new()
                $runbookRun.EnvironmentId = $environment.Id
                $runbookRun.ProjectId = $RunbookSnapshot.ProjectId
                $runbookRun.RunbookSnapshotId = $RunbookSnapshot.ID
                $runbookRun.RunbookId = $RunbookSnapshot.RunbookId
                
                if ($QueueTime) {
                    $runbookRun.QueueTime = $QueueTime
                    $runbookRun.QueueTimeExpiry = $QueueTime.AddMinutes($ExpiryInMin)
                }
                
                # Add variables to runbook run if passed in
                if ($FormValue) {
                    foreach ($key in $FormValue.keys) {
                        $runbookRun.FormValues.Add($key, $FormValue[$key])
                    }
                }
                
                if ($Tenant) {
                    # Run tenanted runbook for each tenant
                    foreach ($_tenant in $Tenant) {
                        # Validate tenant is connected to project environment
                        if (! ($_tenant.ProjectEnvironments[$Project.id] -contains $Environment.Id)) {
                            $message = "'{0}' is not connected to '{1}' in '{2}'" -f $_tenant.name, $Project.name, $Environment.name
                            try {
                                throw $message
                            }
                            catch {
                                $PSCmdlet.WriteError($_)
                                continue
                            }
                        }
                        
                        $runbookRun.TenantId = $_tenant.id
                        try {
                            Write-Verbose "Running traditional runbook snapshot for tenant '$($_tenant.Name)'"
                            return $repo._repository.RunbookRuns.Create($runbookRun)
                        }
                        catch {
                            $PSCmdlet.WriteError($_)
                        }
                    }
                }
                else {
                    # Execute runbook without tenant
                    try {
                        Write-Verbose "Running traditional runbook snapshot (untenanted)"
                        return $repo._repository.RunbookRuns.Create($runbookRun)
                    }
                    catch {
                        $PSCmdlet.WriteError($_)
                    }
                }
            }
        }
      

        # Branch logic based on project type
        if ($PSCmdlet.ParameterSetName -eq 'Runbook') {
          
            
            # Resolve Git branch
            $branches = Get-GitBranch -Project $Project
            
            if ($BranchName) {
                # Filter to find the matching branch by name or canonical name
                $selectedBranch = $branches | Where-Object { $_.Name -eq $BranchName -or $_.CanonicalName -eq $BranchName }
                
                if (-not $selectedBranch) {
                    $availableBranches = ($branches | ForEach-Object { $_.Name }) -join ', '
                    $message = "Project '$($Project.name)' has no branch called '$BranchName'. Available branches: $availableBranches"
                    $myError = Get-CustomError -Message $message -Category InvalidData -Exception System.ArgumentException
                    $PSCmdlet.ThrowTerminatingError($myError)
                }
                Write-Verbose "Using branch '$($selectedBranch.CanonicalName)' to run runbook"
            }
            else {
                # Use default branch
                $selectedBranch = $branches | Where-Object { $_.IsDefault -eq $true }
                
                if (-not $selectedBranch) {
                    $message = "Project '$($Project.name)' has no default branch configured"
                    $myError = Get-CustomError -Message $message -Category InvalidData -Exception System.InvalidOperationException
                    $PSCmdlet.ThrowTerminatingError($myError)
                }
                Write-Verbose "Using default branch '$($selectedBranch.CanonicalName)' to run runbook"
            }
            
            # Get the runbook slug
            $runbookSlug = $runbook.Slug
            
            # Prepare ShouldProcess messages
            $shouldMessage1 = "Run runbook '{0}' from branch '{1}' in environment '{2}'" -f $runbook.Name, $selectedBranch.Name, $environment.Name
            $shouldMessage2 = "Run {0}/{1}" -f $project.Name, $runbook.Name
            
            if ($force -or $PSCmdlet.ShouldProcess($shouldMessage1, $shouldMessage2)) {
                
                if ($Tenant) {
                    # Run tenanted runbook for each tenant
                    foreach ($_tenant in $Tenant) {
                        # Validate tenant is connected to project environment
                        if (! ($_tenant.ProjectEnvironments[$Project.id] -contains $Environment.Id)) {
                            $message = "'{0}' is not connected to '{1}' in '{2}'" -f $_tenant.name, $Project.name, $Environment.name
                            try {
                                throw $message
                            }
                            catch {
                                $PSCmdlet.WriteError($_)
                                continue
                            }
                        }
                        
                        # Create GitRunbookRunParameters for this tenant
                        $gitRunParams = [Octopus.Client.Model.GitRunbookRunParameters]::new($environment.Id)
                        $gitRunParams.TenantId = $_tenant.Id
                        
                        if ($QueueTime) {
                            $gitRunParams.QueueTime = $QueueTime
                            $gitRunParams.QueueTimeExpiry = $QueueTime.AddMinutes($ExpiryInMin)
                        }
                        
                        # Add form values if provided
                        if ($FormValue) {
                            foreach ($key in $FormValue.Keys) {
                                $gitRunParams.FormValues.Add($key, $FormValue[$key])
                            }
                        }
                        
                        # Create wrapper RunGitRunbookParameters
                        $runbookRunParams = [Octopus.Client.Model.RunGitRunbookParameters]::new($environment.Id)
                        $runbookRunParams.Runs = @($gitRunParams)
                        
                        try {
                            Write-Verbose "Running CaC runbook '$runbookSlug' for tenant '$($_tenant.Name)'"
                            $repo._repository.Runbooks.Run($project, $selectedBranch.CanonicalName, $runbookSlug, $runbookRunParams)
                        }
                        catch {
                            $PSCmdlet.WriteError($_)
                        }
                    }
                }
                else {
                    # Execute untenanted runbook
                    # Create GitRunbookRunParameters (no tenant)
                    $gitRunParams = [Octopus.Client.Model.GitRunbookRunParameters]::new($environment.Id)
                    
                    if ($QueueTime) {
                        $gitRunParams.QueueTime = $QueueTime
                        $gitRunParams.QueueTimeExpiry = $QueueTime.AddMinutes($ExpiryInMin)
                    }
                    
                    # Add form values if provided
                    if ($FormValue) {
                        foreach ($key in $FormValue.Keys) {
                            $gitRunParams.FormValues.Add($key, $FormValue[$key])
                        }
                    }
                    
                    # Create wrapper RunGitRunbookParameters
                    $runbookRunParams = [Octopus.Client.Model.RunGitRunbookParameters]::new($environment.Id)
                    $runbookRunParams.Runs = @($gitRunParams)
                    
                    try {
                        Write-Verbose "Running CaC runbook '$runbookSlug' (untenanted)"
                        $repo._repository.Runbooks.Run($project, $selectedBranch.CanonicalName, $runbookSlug, $runbookRunParams)
                    }
                    catch {
                        $PSCmdlet.WriteError($_)
                    }
                }
            }
        }
        else {
            
        }
    }

    end {}
}
