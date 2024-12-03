function Get-Project {
    <#
.SYNOPSIS
    Returns a list of available projects
.DESCRIPTION
    Returns a list of project object for the given criteria
.EXAMPLE
    PS C:\> Get-Project
    Returns a list of all project
.EXAMPLE
    PS C:\> Get-Project -name 'Test Project'
    Returns the project object of 'Test Project'
#>
    [CmdletBinding(DefaultParameterSetName = "Name")]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'Name' ,
            Position = 0 )]
        [String]
        $Name,
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ID')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID

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

        if ($PSCmdlet.ParameterSetName -eq 'Name' -and ([String]::IsNullOrEmpty($Name))) {
            $result = $repo._repository.Projects.getall()
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Name') {
            #$result =$name | ForEach-Object {$repo._repository.Projects.findbyname("$_")}
            $result = $repo._repository.Projects.findbyname("$name")
        }
        if ($PSCmdlet.ParameterSetName -eq 'ID') {
            try {
                $result = $repo._repository.Projects.get("$id")
            }
            catch {}
            
        }
        
        if (!($result)) {
            $message = "There is no project with the {0} `"{1}{2}`"" -f $PSCmdlet.ParameterSetName, $name, $ID
            Throw $message
        }
        $result
    }
}
