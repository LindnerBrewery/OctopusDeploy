function Get-GitBranch {
    <#
.SYNOPSIS
    Returns the git branches of a project
.DESCRIPTION
    Returns the git branches of a project with the information wfich is the default branch
.EXAMPLE
    PS C:\> Get-GitBranch -project 'MyProject2'
    Returns the git branches of a project

#>
    [CmdletBinding(
        DefaultParameterSetName = "default"
    )]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ParameterSetName = "default",
            Position = 0,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]
        $Project
    )
    Test-OctopusConnection | Out-Null
    if (! $project.IsVersionControlled) {
        Write-verbose "$($project.name) is not version controlled"
        return
    }
    $branches = [System.Collections.ArrayList]::new()
    $branches = ($repo._repository.Projects.GetGitBranches($Project)).items

    $result = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($branch in $branches) {
        $result.add([PSCustomObject]@{
            Name = $branch.name
            CanonicalName = $branch.CanonicalName
            IsDefault = if($branch.name -eq $project.PersistenceSettings.defaultBranch){$True}else{$false}
        })
    }

    @(, $result)
}
