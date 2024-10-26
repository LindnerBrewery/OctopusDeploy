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
Describe New-Release{
    Context 'Basic tests' {
        BeforeAll{

        }
        It "New Release" {
            $latest = Get-Release -Project TestProjectTenanted -Latest
            $result = New-Release TestProjectTenanted
            $result | Should -BeOfType [Octopus.Client.Model.ReleaseResource]
            # has project got expected version
            ([version]$result.Version).Build | Should -Be (([version]$latest.version).Build + 1)
            # clean up
            $result | Remove-Release
        }
        It "New Release version controlled project" {
            $latest = Get-Release -Project TestProjectTenanted_SouceControlled -Latest
            $result = New-Release TestProjectTenanted_SouceControlled
            $result | Should -BeOfType [Octopus.Client.Model.ReleaseResource]
            # has project got expected version
            ([version]$result.Version).Build | Should -Be (([version]$latest.version).Build + 1)
            # clean up
            $result | Remove-Release
        }
        It "New Release with specific version" {
            $latest = (Get-Release -Project TestProjectTenanted -Latest).version
            $version = '1.2.3-RC'
            $result = New-Release TestProjectTenanted -Version $version
            $result | Should -BeOfType [Octopus.Client.Model.ReleaseResource]
            # has project got expected version
            $result.Version | Should -Be $version
            # clean up
            $result | Remove-Release
        }
        It "New Release version controlled project non default branch " {
            $latest = Get-Release -Project TestProjectTenanted_SouceControlled -Latest
            $result = New-Release TestProjectTenanted_SouceControlled -GitBranch newBranch
            $result | Should -BeOfType [Octopus.Client.Model.ReleaseResource]
            # has project got expected version
            ([version]$result.Version).Build | Should -Be (([version]$latest.version).Build + 1)

            # as realease got expected git ref
            $result.GitReference.GitRef | should -Match 'newBranch'
            # clean up
            $result | Remove-Release
        }
        It "New Release in non default channel" {
            $latest = Get-Release -Project TestProjectTenanted -Latest
            $result = New-Release TestProjectTenanted -Channel 'testchannel'

            # has ne release go expected channel id
            $result.ChannelId | Should -Be 'Channels-725'
            $result | Should -BeOfType [Octopus.Client.Model.ReleaseResource]
            # has project got expected version
            ([version]$result.Version).Build | Should -Be (([version]$latest.version).Build + 1)
            # clean up
            $result | Remove-Release
        }
        It "New Release with package version full" {
            $packages = @{"medavis.solution.withDependencies" = '2.2.863'
                'medavis-ris-dbschemaupdate.portable' = '2022.11.24.3184'}
            $result = new-Release TestProjectTenanted -Package $packages
            # chack package versions
            ($result.SelectedPackages | Where-Object PackageReferenceName -eq "medavis.solution.withDependencies" )[0].version | Should -Be '2.2.863'
            ( $result.SelectedPackages | Where-Object PackageReferenceName -eq "medavis-ris-dbschemaupdate.portable" )[0].version | Should -Be '2022.11.24.3184'
            # has project got expected version
            # clean up
            $result | Remove-Release
        }
        It "New Release with package version partial" {
            $latest = Get-Release -Project TestProjectTenanted -Latest
            $packages = @{"medavis.solution.withDependencies" = '2.2.863'}
            $result = new-Release TestProjectTenanted -Package $packages
            # check package versions
            ($result.SelectedPackages | Where-Object PackageReferenceName -eq "medavis.solution.withDependencies" )[0].version | Should -Be '2.2.863'
            ($latest.SelectedPackages | Where-Object PackageReferenceName -eq "medavis-ris-dbschemaupdate.portable" )[0].version | Should -not -Be '2022.9.29.3164'
            # has project got expected version
            # clean up
            $result | Remove-Release
        }
    }
}
