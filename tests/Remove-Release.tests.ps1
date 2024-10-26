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
    Connect-Octopus -OctopusServerURL https://octo.medavis.com -ApiKeyPlain $env:PesterOctoApiKey
    Set-Space -SpaceName Pester
}
Describe Remove-Release {
    Context 'Basic tests' {
        BeforeAll{

        }
        It "Delete release" {
            $lastRelease = Get-Release -Project TestProjectTenanted -Latest
            $newRelease = New-Release TestProjectTenanted
            $lastRelease.version  | Should -Not -Be $newRelease.version
            remove-Release TestProjectTenanted
            $currentRelease = (Get-Release -Project TestProjectTenanted -Latest)
            $lastRelease.version  | Should -Be $currentRelease.version

        }
        It "Delete specific release with project and version" {
            $newRelease = New-Release TestProjectTenanted -Version "9.9.9.9-Test"
            remove-Release TestProjectTenanted -Version "9.9.9.9-Test"
            $currentRelease = (Get-Release -Project TestProjectTenanted -Latest)
            $currentRelease.version  | Should -not -Be "9.9.9.9-Test"
        }

        It "Delete specific release by piping release" {
            $newRelease = New-Release TestProjectTenanted -Version "10.9.9.9-Test"
            $newRelease.version | Should -be (Get-Release -Project TestProjectTenanted -Latest).version
            $newRelease | Remove-Release
            $currentRelease = (Get-Release -Project TestProjectTenanted -Latest)
            $currentRelease.version  | Should -not -Be "10.9.9.9-Test"
        }
    }
}
