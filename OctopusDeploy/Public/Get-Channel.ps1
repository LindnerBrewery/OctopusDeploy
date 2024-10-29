function Get-Channel {
    <#
.SYNOPSIS
    Returns channels for all or a specific project
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> Get-Channel
    Returns an array of channels of all projects
.EXAMPLE
    PS C:\> Get-Channel -Project 'Test Project'
    Returns an array of channels of the 'Test Project'
.EXAMPLE
    PS C:\> Get-Project -Name Portal4Med | Get-Channel | Format-Table
    Returns an array of channels of the Portal4Med

#>
    [CmdletBinding(
        DefaultParameterSetName = "default"
    )]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            ParameterSetName = "default",
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ProjectTransformation()]
        [Octopus.Client.Model.ProjectResource[]]
        $Project,
        [Parameter(mandatory = $false,
            ParameterSetName = "default")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,
        [Parameter(mandatory = $false,
            ParameterSetName = "byID")]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID

    )
    Test-OctopusConnection | Out-Null
    $result = [System.Collections.ArrayList]::new()
    $result = $repo._repository.Channels.FindAll()
    if ($PSCmdlet.ParameterSetName -eq "default") {
        if ($Project) {
            $result = $result | Where-Object ProjectID -Like $Project.ID
        }
        if ($Name) {
            $result = $result | Where-Object Name -Like $name
        }
    } elseif ($PSCmdlet.ParameterSetName -eq "byID") {
        $result = $result | Where-Object ID -EQ $ID
    }

    $result
}
