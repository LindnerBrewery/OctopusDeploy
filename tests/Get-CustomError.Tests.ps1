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
    

    # only source single private function
    $functionFilename = [System.IO.FileInfo]::new("$PSCommandPath").name.Replace('.Tests','')
    . "$modDir\private\$functionFilename"
    $err = Get-CustomError -Message 'test' -Category InvalidData -Exception System.IO.FileLoadException -TargetObject 1
}

Describe Get-CustomError {
    Context 'Basic tests' {
        It "Test output type: System.Management.Automation.ErrorRecord" {
                $err | Should -BeOfType [System.Management.Automation.ErrorRecord]
        }
        It "Test Exception.Message" {
                $err.Exception.Message | Should -Be "test"
        }
        It "Test Exception type: System.IO.FileLoadException" {
                $err.Exception | Should -BeOfType [System.IO.FileLoadException]
        }
        It "Test TargetObject value" {
                $err.TargetObject | Should -Be 1
        }
        It "Test TargetObject type: System.Int32" {
                $err.TargetObject | Should -BeOfType [System.Int32]
        }

    }
}
# Describe Get-CustomError {
#     Context 'Basic tests' {
#         It "Test output type" {
#             InModuleScope $moduleName {
#                 $err = Get-CustomError -Message 'test' 
#                 $err | Should -BeOfType [System.Management.Automation.ErrorRecord]
#             }
#         }
#         It "Test error message" {
#             InModuleScope $moduleName {
#                 $err = Get-CustomError -Message 'test' 
#                 $err | Should -BeOfType [System.Management.Automation.ErrorRecord]
#             }
#         }
#         It "Test exception" {
#             InModuleScope $moduleName {
#                 $err = Get-CustomError -Message 'test' 
#                 $err | Should -BeOfType [System.Management.Automation.ErrorRecord]
#             }
#         }
#     }
# }
