[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function')]
Param()

BeforeAll {
    $commandPath = ([System.IO.FileInfo]::new($PSCommandPath))
    $testDir = $CommandPath.Directory
    $rootDir = $testDir.Parent.FullName
    Push-Location $rootDir
    Set-BuildEnvironment -Force
    Pop-Location

    # test release if available otherwise test dev folders
    $buildDir = Join-Path -Path $rootDir -ChildPath 'release'
    if (! [System.IO.Directory]::exists($BuildDir)) {
        # using dev folders
        $buildDir = $rootDir
        Write-Verbose "Will be using dev folder $buildDir"
    }
    else {
        Write-Verbose "Will be using release folder $buildDir"
    }
    $moduleName = $env:BHProjectName
    $modDir = Join-Path -Path $BuildDir -ChildPath $moduleName
    $manifestPath = Join-Path -Path $modDir -Child "$($moduleName).psd1"
    Import-Module $modDir -Force
    Get-Module $moduleName
    Connect-Octopus -OctopusServerURL https://octo.medavis.com -ApiKeyPlain $env:PesterOctoApiKey
    Set-Space -SpaceName Pester
}
Describe New-Release{
    Context 'Basic tests' {
        BeforeAll{

        }
        It "Project without source control" {
            Get-GitBranch -Project TestProjectTenanted | Should -Be $null
        }
        It "Project with source control" {
            (Get-GitBranch -Project TestProjectTenanted_SouceControlled).count | Should -BeGreaterThan 1
        }
    }
}
