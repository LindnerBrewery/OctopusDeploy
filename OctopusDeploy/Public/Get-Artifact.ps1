function Get-Artifact {
    <#
.SYNOPSIS
    Returns a list of artifacts
.DESCRIPTION
    Returns a list of artifacts that are saved on the octopus server. Regarding refers to a runbook snapshot or project deployment
.EXAMPLE
    PS C:\> Get-Artifact
    Returns all artifacts saved on the server
.EXAMPLE
    PS C:\> Get-Artifact -Id "Artifacts-1989"
    Returns a single artifact
.EXAMPLE
    PS C:\>  $snapshot = Get-Runbook -Name "Get Customer Configuration" | Get-RunbookSnapshot -latest
    PS C:\> Get-Artifact -Regarding $snap
    Returns all artifacts a the latest runbook snapshot
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            ParameterSetName = 'byID' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID,
        # Task or runbook snapshot object. Do not pass in a ID. It must be an object (Octopus.Client.Extensibility.IResource resource)
        [Parameter(mandatory = $false,
            ValueFromPipeline = $true,
            ParameterSetName = 'byRegarding' )]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.Resource]
        $Regarding,
        # Changes the amount of results that are return. Default is 1000, 0 is unlimited
        [Parameter(Mandatory = $false,
            ParameterSetName = 'default')]
        [int]
        $ResultLimit = 1000


    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {

        $result = [System.Collections.ArrayList]::new()
        if ($PSCmdlet.ParameterSetName -eq 'default') {
            $script:counter = 0
            $script:handbreak = $ResultLimit

            $arr = [System.Collections.Generic.list[Octopus.Client.Model.ArtifactResource]]::new()
            try {
                # if result should be unlimited the use findAll() as it is faster
                if ($script:handbreak -eq 0 ) {
                    Write-Verbose "Limit has been turned off. Getting all artifacts"
                    $arr = $repo._repository.Artifacts.FindAll()
                } else {
                    $repo._repository.Artifacts.FindMany({ param($t)
                            if ($script:counter -lt $script:handbreak) {
                                #Write-Host $($PSBoundParameters.keys)
                                $arr.Add($t)
                                $script:counter++
                            } else {
                                Throw 'Reached max'
                            }

                        })
                }
            } catch {
                #Write-Host $_
            }

            finally {
                $arr
                if ($counter -eq $handbreak -and -not $handbreak -eq 0) {
                    Write-Warning "We returned $handbreak results. There are more left on the server. Search explicitly an Artifact or consider deleting artifacts"
                }
            }

        }
        if ($PSCmdlet.ParameterSetName -eq 'byID') {
            $repo._repository.Artifacts.get($ID)
        }
        if ($PSCmdlet.ParameterSetName -eq 'byRegarding') {
            $collection = $repo._repository.Artifacts.FindRegarding($Regarding)
            $collectionPages = [System.Collections.ArrayList]::new()
            $func = { param($a) foreach ($item in $a) {
                    $collectionPages.Add($item)
                    $true
                }
            }
            $repo._repository.Artifacts.Paginate($func, $collection.links['self'])
            $collectionPages.items
        }
    }
    end {}
}

