function Get-Environment {
    <#
.SYNOPSIS
    Returns environment object
.DESCRIPTION
    Returns a list of environment object available in the current space
.EXAMPLE
    PS C:\> Get-Environment
    Returns all environments
.EXAMPLE
    PS C:\> Get-Environment -Name QA
    Returns the environment object of the environment with the name 'QA'
.EXAMPLE
    PS C:\>  Get-Environment -Id Environments-43
    Returns the environment object of the environment with the ID 'Environments-43'

#>
    [CmdletBinding(DefaultParameterSetName = "Name")]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'Name',
            Position = 0 )]
        [AllowNull()]
        [AllowEmptyString()]
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
        $result = [System.Collections.ArrayList]::new()
        if ($PSCmdlet.ParameterSetName -eq 'Name' -and ([String]::IsNullOrEmpty($Name))) {
            $result = $repo._repository.Environments.getall()
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Name') {
            $result = $repo._repository.Environments.findbyname("$name")

        }
        if ($PSCmdlet.ParameterSetName -eq 'ID') {
            try {
                $result = $repo._repository.Environments.get("$id")
            }
            catch {}

        }

        if (!($result)) {
            $message = "There is no environment with the {0} `"{1}{2}`"" -f $PSCmdlet.ParameterSetName, $name, $ID
            Throw $message
        }
        $result
    }
}
