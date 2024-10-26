function Remove-Project {
    <#
.SYNOPSIS
    Removes an release of a project
.DESCRIPTION
    Removes an release of a project. If no version is provided the latest release will be removed

.EXAMPLE
    PS C:\> Remove-Project -Project "Install Project"
    Removes the project "Install Project"
.EXAMPLE
    PS C:\> Get-Project "Install Project" | Remove-Project -confirm:$false
    Deletes the project "Install Project"


#>
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ProjectSingleTransformation()]
        [Octopus.Client.Model.ProjectResource]
        $Project,
        [switch]$Force

    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {
        if ($Force.IsPresent -or $PSCmdlet.ShouldProcess("$($Project.name)", "Delete project")) {
            try {
                $repo._repository.Projects.Delete($Project)
                Write-Host ("Removed project {0}" -f $Project.name)
            } catch {
                Throw $_
            }
        }
    }

    end {}
}
