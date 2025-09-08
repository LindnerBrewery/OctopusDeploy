[cmdletbinding(DefaultParameterSetName = 'Task')]
param(
    # Build task(s) to execute
    [parameter(ParameterSetName = 'task', position = 0)]
    [string[]]$Task = 'default',

    # Bootstrap dependencies
    [switch]$Bootstrap,

    # List available build tasks
    [parameter(ParameterSetName = 'Help')]
    [switch]$Help,

    # Optional properties to pass to psake
    [hashtable]$Properties,

    # Optional parameters to pass to psake
    [hashtable]$Parameters
)

$ErrorActionPreference = 'Stop'

# Bootstrap dependencies
if ($Bootstrap.IsPresent) {
    Get-PackageProvider -Name Nuget -ForceBootstrap
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    nuget locals all -clear
    if ((Test-Path -Path ./requirements.psd1)) {
        if (-not ((Get-Module -Name PowerShellBuild -ListAvailable).version -eq [version]'0.6.2')) {
            Install-Module -Name PowerShellBuild -Repository PSGallery -Scope CurrentUser -Force -RequiredVersion 0.6.2
        }
        Import-Module -Name PowerShellBuild -Verbose:$false -RequiredVersion 0.6.2

        if (-not (Get-Module -Name PSDepend -ListAvailable)) {
            Install-Module -Name PSDepend -Repository PSGallery -Scope CurrentUser -Force
        }
        Import-Module -Name PSDepend -Verbose:$false
        Invoke-PSDepend -Path './requirements.psd1' -Install -Import -Force -WarningAction SilentlyContinue -Verbose

        $octoClient = (Get-ChildItem $PSScriptRoot\dependencies\Octopus.Client.* | Sort-Object -Property @{e = { [version]$_.name.replace("Octopus.Client.", "") } } -Descending | Select-Object -First 1).fullname;
        Write-Host $octoClient
        Copy-Item $octoClient\lib\net462\Octopus.Client.dll $PSScriptRoot\OctopusDeploy\Lib\Desktop\Octopus.Client.dll -Force -Verbose;
        Copy-Item $octoClient\lib\netstandard2.0\Octopus.Client.dll $PSScriptRoot\OctopusDeploy\Lib\Core\Octopus.Client.dll -Force -Verbose

    }

} else {
    Write-Warning 'No [requirements.psd1] found. Skipping build dependency installation.'
}


# Execute psake task(s)
$psakeFile = './psakeFile.ps1'
if ($PSCmdlet.ParameterSetName -eq 'Help') {
    Get-PSakeScriptTasks -buildFile $psakeFile |
    Format-Table -Property Name, Description, Alias, DependsOn
} else {
    Set-BuildEnvironment -Force
    Invoke-psake -buildFile $psakeFile -taskList $Task -nologo -properties $Properties -parameters $Parameters
    exit ([int](-not $psake.build_success))
}
