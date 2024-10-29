function Get-TagSet {
    <#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.EXAMPLE
    PS C:\> Get-TagSet -CanonicalTagName
    Returns a tags as a list of canonical tag names
.EXAMPLE
    PS C:\> Get-TagSet -Name Region  -CanonicalTagName
    Returns a list of canonical tag name for the tag set called "region"
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
        $ID,

        # Returns the result als list of CanonicalTagNames
        [Parameter(mandatory = $false)]
        [switch]
        $CanonicalTagName

    )
    Test-OctopusConnection | Out-Null
    $result = [System.Collections.ArrayList]::new()
    if ($PSCmdlet.ParameterSetName -eq 'Name' -and ([String]::IsNullOrEmpty($Name))) {
        $result = $repo._repository.TagSets.getall()
    } elseif ($PSCmdlet.ParameterSetName -eq 'Name') {
        $result = $repo._repository.TagSets.findbyname("$name")

    }
    if ($PSCmdlet.ParameterSetName -eq 'ID') {
        try {
            $result = $repo._repository.TagSets.get("$id")
        } catch {}

    }

    if (!($result)) {
        $message = "There is no TagSet with the {0} `"{1}{2}`"" -f $PSCmdlet.ParameterSetName, $name, $ID
        Throw $message
    }

    if ($CanonicalTagName.IsPresent) {
        return  $result.Tags.CanonicalTagName
    }
    return $result
}
