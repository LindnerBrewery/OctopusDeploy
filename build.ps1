[CmdletBinding(DefaultParameterSetName = 'Task')]
Param (
    [Parameter(ParameterSetName = 'Task',
        Position = 0)]
    [String[]]$Task = 'default',
    [switch]$Bootstrap,
    # List available build tasks
    [parameter(ParameterSetName = 'Help')]
    [switch]$Help,
    # Optional properties to pass to psake
    [hashtable]$Properties

)
#$VerbosePreference = "Continue"
$ErrorActionPreference = 'Stop'
$psdependVersion = [version]'0.3.8'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($Bootstrap.IsPresent) {
    Write-Verbose "Bootstrapping"
    Write-Host 'Adding Octopus Certificate'
    . $PSScriptRoot\install_certificate.ps1
    $certs = Get-CertificatesFromUrl 'octo.medavis.com'
    Import-X509Certificate -X509Certificate $certs -WindowsOrDotNet
    if (-not (Get-PackageProvider -Name "NuGet" -Force -ErrorAction SilentlyContinue)) {
        Write-Output "Install PackageProvider NuGet"
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
    } else {
        Write-Output "PackageProvider NuGet already installed."
    }

    if (!(Get-PackageSource -Location "https://www.nuget.org/api/v2" -ErrorAction SilentlyContinue).name -ne "nuget.org" ) {
        $name = (Get-PackageSource -Location "https://www.nuget.org/api/v2" -ErrorAction SilentlyContinue).providername
        Write-Host "Found a Package Provider that points to nuget.org but is called `"$name`""
    }
    #register nuget.org as package source
    if (!(Get-PackageSource -Name "nuget.org" -ErrorAction SilentlyContinue)) {
        Register-PackageSource -Name nuget.org -Location 'https://www.nuget.org/api/v2' -Trusted -ProviderName "NuGet"
    }

    foreach ($PSRepository in (Get-PSRepository -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).Name) {
        Write-Output "Unregistering PSRepository $PSRepository"
        Unregister-PSRepository -Name $PSRepository
    }
    if (-not (Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue)) {
        Write-Output "Registering PSGallery"
        Register-PSRepository -Default -InstallationPolicy Trusted
    } else {
        Write-Output "PSRepository PSGallery already registered."
    }
    if (-not (Get-Module -Name PsDepend -ListAvailable | Where-Object Version -GE $psdependVersion)) {
        Install-Module -Name PsDepend -MinimumVersion $psdependVersion -Scope CurrentUser
    } elseif ((Get-Module -Name PSDepend -ListAvailable) -and !(Get-Module -Name PSDepend -ListAvailable | Where-Object Version -EQ $psdependVersion)) {
        ​​
        Remove-Module -Name PsDepend
    }
    Import-Module -Name PsDepend
    New-Item -Path .\dependencies -ItemType Directory -Force
    Invoke-PSDepend -Path .\requirements.psd1 -Force
    Install-Module -Name PowerShellGet -Force
    Remove-Module -Name powershellget -Force
}
"#############################################"
"#############################################"
if (! $islinux) {
    #gitversion /showvariable NuGetVersionV2
    gitversion
}
"#############################################"
"#############################################"

if (-not (Get-PSRepository -Name "PSGallery-group" -ErrorAction SilentlyContinue)) {
    Write-Output "Registering PSGallery-group"
    Register-PSRepository -Name "PSGallery-group" -SourceLocation "https://repo.medavis.local/repository/psgallery-group/" -PublishLocation "https://repo.medavis.local/repository/psgallery-private/" -PackageManagementProvider Nuget -InstallationPolicy Trusted
} else {
    Write-Output "PSRepository PSGallery-group is already registered."
}

Import-Module PowerShellBuild
#Invoke-psake -buildFile '.\psakeBuild.ps1' -taskList $Task -ErrorAction Stop
#exit ( [int]( -not $psake.build_success ) )

# Execute psake task(s)
$psakeFile = './psakeBuild.ps1'
if ($PSCmdlet.ParameterSetName -eq 'Help') {
    Get-PSakeScriptTasks -buildFile $psakeFile |
    Format-Table -Property Name, Description, Alias, DependsOn
} else {
    Set-BuildEnvironment -Force
    Invoke-psake -buildFile $psakeFile -taskList $Task -nologo -properties $Properties
    exit ([int](-not $psake.build_success))
}
