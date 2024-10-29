

function Import-OctopusclientDll {
    [CmdletBinding()]
    param (

    )
    $modPath = $MyInvocation.MyCommand.ScriptBlock.Module.ModuleBase
    $octoClientDll = join-path $modPath "lib\Octopus.Client.dll"
    #[File]::Exists($octoClientDll)
    if ([File]::Exists($octoClientDll)) {
        add-type -path $octoclientDll
        Write-Verbose "Octopus.Client.dll imported"
    } else {
        Throw "Cannot find Octopus.Client"
    }

}

