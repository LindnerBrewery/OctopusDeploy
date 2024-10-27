@{
    PSDependOptions       = @{
        Target    = '$DependencyFolder\dependencies' # I want all my dependencies installed here
        AddToPath = $True            # I want to prepend project to $ENV:Path and $ENV:PSModulePath
    }
    'Pester'              = @{
        Version    = 'latest'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }

    'psake'               = @{
        Version = '4.9.0'
    }
    'Configuration'       = @{
        Version = 'latest'
    }
    'BuildHelpers'        = @{
        Version = '2.0.16'
    }
    'PowerShellBuild'     = @{
        Version = '0.6.1'
    }
    'PSScriptAnalyzer' = @{
        Version = '1.19.1'
    }
    'Octopus.Client'      = @{
        DependencyType = 'Package'
        Source         = 'nuget.org'
        Parameters     = @{
            SkipDependencies = $true
        }
    }
    'Octopus.Client.Copy' = @{
        DependencyType = 'Command'
        Source         = '$octoClient = (Get-Childitem $DependencyFolder\dependencies\Octopus.Client.* | Sort-Object -Property @{e={[version]$_.name.replace("Octopus.Client.","")}} -Descending | Select -first 1).fullname;
        Write-host $octoClient
        Copy-item $octoClient\lib\net462\Octopus.Client.dll $DependencyFolder\OctopusDeploy\Lib\Desktop\Octopus.Client.dll -force -verbose;
        Copy-item $octoClient\lib\netstandard2.0\Octopus.Client.dll $DependencyFolder\OctopusDeploy\Lib\Core\Octopus.Client.dll -force -verbose'
        DependsOn      = 'Octopus.Client'
    }
    'gitversion' = @{
        DependencyType = 'Command'
        Source         = 'if ($isWindows){choco install GitVersion.Portable --version 5.12.0 -yf}'
    }
    'nuget' = @{
        DependencyType = 'Command'
        Source         = 'if ($isWindows){choco upgrade NuGet.CommandLine -yf}'
    }

}

