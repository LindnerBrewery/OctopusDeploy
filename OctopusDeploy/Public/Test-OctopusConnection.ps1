function Test-OctopusConnection {
    [CmdletBinding()]
    param (

    )
    try {
        (Get-OctopusRepositoryObject)._repository.Users.GetCurrent() | Out-Null
        return $true

    } catch {
        return $false
        # try {
        #     Write-Verbose "trying to reconnect"
        #     Connect-Octopus
        # } catch {
        #     Throw "No connection to octopus server"
        # }
    }
    # if (Get-OctopusRepositoryObject) {
    #     <# Action to perform if the condition is true #>
    #     return $true
    # }else{
    #     return $false
    # }


}

