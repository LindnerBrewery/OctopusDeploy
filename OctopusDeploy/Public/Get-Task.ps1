function Get-Task {
    <#
    .SYNOPSIS
        Returns a list of tasks.

    .DESCRIPTION
        Returns a list of tasks depending on the given parameters.

    .EXAMPLE
        C:\ PS> Get-Task -TaskType RunbookRun -ResultLimit 10
        Returns the latest 10 Runbook runs.

    .EXAMPLE
        C:\ PS> Get-Task -Tenant XXROM001 -Environment Development -TaskType Deploy
        Returns all deployments of XXROM001 in development environment.

    .EXAMPLE
        C:\ PS> Get-Task -Regarding $runbookSnapshot
        Returns all tasks regarding the given runbook snapshot.

    .EXAMPLE
        C:\ PS> Get-Task -Regarding  (Get-Release -Project 'MyProject' -Latest)
        Returns all tasks regarding the given release.

    .PARAMETER TaskID
        The ID of the task to retrieve. This parameter is mandatory when using the 'byID' parameter set.

    .PARAMETER TaskType
        The type of task to filter by. This parameter is optional.

    .PARAMETER Tenant
        The tenant to filter by. This parameter is optional.

    .PARAMETER Environment
        The environment to filter by. This parameter is optional.

    .PARAMETER Regarding
        The task or runbook snapshot object to filter by. Do not pass in an ID. It must be an object of type Octopus.Client.Extensibility.IResource. This parameter is optional.

    .PARAMETER ResultLimit
        The maximum number of results to retrieve. The default value is 10000. This parameter is optional.
    #>
    [CmdletBinding(DefaultParameterSetName = 'default',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'http://www.octopus.com/',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    param (
        [Parameter(mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'byID',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [String]
        $TaskID,

        [Parameter(mandatory = $false,
            ParameterSetName = 'default')]
        [string]
        $TaskType,

        [Parameter(mandatory = $false,
            ParameterSetName = 'default')]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]
        $Tenant,

        [Parameter(mandatory = $false,
            ParameterSetName = 'default')]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]
        $Environment,

        [Parameter(mandatory = $false,
            ValueFromPipeline = $true,
            ParameterSetName = 'byRegarding')]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.Resource]
        $Regarding,

        [Parameter(mandatory = $false,
            ParameterSetName = 'default')]
        [int]
        $ResultLimit
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
        if ($PSCmdlet.ParameterSetName -eq 'ByID') {
            $repo._repository.Tasks.Get($TaskID)
        }
        if ($PSCmdlet.ParameterSetName -eq 'Default') {
            $path = '/api/tasks'
            function checkpath ($path) {
                if ($path -eq '/api/tasks') {
                    return '/api/tasks?'
                } else { return ($path + "&") }
            }

            # always add space
            $space = Get-CurrentSpace
            $path = (checkpath $path) + "spaces=$($space.id)"

            # setting up searchlink
            if ($TaskType) { $path = (checkpath $path) + "name=$tasktype" }
            if ($Tenant) { $path = (checkpath $path) + "tenant=$($Tenant.id)" }
            if ($Environment) { $path = (checkpath $path) + "environment=$($Environment.id)" }

            # setting up resultlimit
            if (! $ResultLimit) {
                $ResultLimit = 10000
            }
            if ($ResultLimit) { $path = (checkpath $path) + "take=$ResultLimit" }

            Write-Verbose "Calling $path"

            #$repo._repository.Tasks.Paginate({param($t) $arr.add($t);break},'/api/tasks?skip=150&tenant=Tenants-563&spaces=Spaces-1&includeSystem=false') #link '/api/tasks?name=AdHocScript'
            #/api/tasks?skip=150&tenant=Tenants-563&spaces=Spaces-1&includeSystem=false

            try {

                # Using the generic method to get the list of tasks. This is the fastest way to get the list of tasks
                # Using $repo._repository.Tasks.FindMany($path) returns wrong results.
                # Make Generic List method
                $genericMethod = $repo._repository.Client.GetType().GetMethod("List").MakeGenericMethod([Octopus.Client.Model.TaskResource])

                # Set path parameters for call
                $pathParameters = [System.Collections.Generic.Dictionary[String, Object]]::new()
                # Set generic method parameters
                $parameters = [System.Collections.Generic.List[Object]]::new()
                #[Object[]] $parameters = $path, $pathParameters
                $parameters = $path, $pathParameters

                # Invoke the List method
                $results = $genericMethod.Invoke($repo._client, $parameters)
                if ($results.Items.count -lt $results.TotalResults) {
                    Write-Warning "There are more results than the ResultLimit. Please increase the ResultLimit parameter."
                    Write-Warning "Results: $($results.Items.count) of $($results.TotalResults)"
                }
                return $results.Items

            } catch {

                Throw $_
            }


        }

        if ($PSCmdlet.ParameterSetName -eq 'byRegarding') {

            foreach ($r in $Regarding) {
                if ($r -is [Octopus.Client.Model.RunbookSnapshotResource]) {
                    $tasks = (Get-RunbookRun -RunbookSnapshot $r).links.task
                } elseif ($r -is [Octopus.Client.Model.ReleaseResource]) {
                    $tasks = (Get-Deployment -Release $r).links.task
                }
                foreach ($t in $tasks) {
                    $repo._repository.Tasks.get((($t -split '/')[-1]))
                }
            }
        }

    }
    end {}

}
