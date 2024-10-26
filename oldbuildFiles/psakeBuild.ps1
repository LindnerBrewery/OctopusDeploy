# Build with psake\PowershellBuild
Properties {
    # These settings overwrite values supplied from the PowerShellBuild
    # module and govern how those tasks are executed
    $PSBPreference.Test.Enabled = $false
    $PSBPreference.Test.RootDir = "$($PSBPreference.General.ProjectRoot)\$($PSBPreference.General.ModuleName)\tests"
    $PSBPreference.Test.ScriptAnalysisEnabled = $true
    $PSBPreference.Test.CodeCoverage.Enabled = $false
    #$PSBPreference.Test.Outputfile            = "$($PSBPreference.General.ProjectRoot)\bla.xml"
    $PSBPreference.Build.Exclude = @("output", "*build.ps1", "release")
    $PSBPreference.Build.ModuleOutDir = "$($PSBPreference.General.ProjectRoot)\release\$($PSBPreference.General.ModuleName)" #\$($PSBPreference.General.ModuleVersion)"

    $PSBPreference.Publish.PSRepository = "psgallery-group"

    $PSBPreference.Publish.PSRepositoryApiKey = $env:nugetapikey
    $PSBPreference.Build.Dependencies = 'StageFiles'
    $PSBPreference.Help.DefaultLocale = 'en-US'
    $PSBPreference.Build.CompileModule = $false
    $PSBPreference.Test.RootDir = "tests"
    $PSBPreference.Test.OutputFile = "TestResult.xml"
}
Task Default -depends Release -description 'define the Default task'
Task Build -FromModule PowerShellBuild -Version '0.4.0'
#Task GenerateMarkdown -FromModule PowerShellBuild -Version '0.4.0'
Task BuildUpdateVersion -depends Build, UpdateVersion -description 'Build and UpdateVersion'
Task Release -depends Build, UpdateVersion, Publish -description 'Release the module'

Task UpdateVersion -depends Build {
    $file = "$env:BHBuildOutput\$env:BHProjectName.psd1"
    $newVersion = gitversion /showvariable MajorMinorPatch
    $prereleaseVersion = (gitversion /showvariable NuGetPreReleaseTag) -replace "-",""
    Update-Metadata -Path $file -PropertyName ModuleVersion -Value $newVersion
    Update-Metadata -Path $file -PropertyName PrivateData.PSData.Prerelease -Value $prereleaseVersion

    # Save Build Info to custom PSData
    Update-Metadata -Path $file -PropertyName PrivateData.PSData.BuildInformation.BuildNumber -Value $env:BHBuildNumber
    Update-Metadata -Path $file -PropertyName PrivateData.PSData.BuildInformation.BranchName -Value $env:BHBranchName
    Update-Metadata -Path $file -PropertyName PrivateData.PSData.BuildInformation.BuildSystem -Value $env:BHBuildSystem
    Update-Metadata -Path $file -PropertyName PrivateData.PSData.BuildInformation.CommitHash -Value $(if ($env:BHCommitHash) { "$env:BHCommitHash" }else { "" })
    # add a quote
   # Update-Metadata -Path $file -PropertyName PrivateData.PSData.Quote -Value $((Invoke-RestMethod https://api.icndb.com/jokes/random).value.joke)
} -description 'updates the psd1 version in releases'

Task UpdateDevHelp {
    # this only updates the external help for the development folder
    New-ExternalHelp -Path .\docs\en-US\ -OutputPath .\$($PSBPreference.General.ModuleName)\en-US\ -Verbose
} -description 'Creates new external help'

Task Sign -depends Build {
    # we prefer the codesigning cert available on jenkins
    if ($($env:codesigningcertificate_keystore) -and $($env:codesigningcertificate_password)) {
        Write-Output "Certificate from environment found"
        $Path = $env:codesigningcertificate_keystore
        $Password = $env:codesigningcertificate_password
        # Import certificate into varibale - you dont have to save it into the windows cert store
        # $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        # $certificate.Import($path, $password, 'DefaultKeySet')
        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($Path, $Password, 'DefaultKeySet')
    } else {
        Write-Output "Certificate try from local certstore "
        $certificate = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object -Property Subject -Match "medavis"
    }
    if (Test-Certificate $certificate -ErrorAction SilentlyContinue) {
        Write-Verbose "Certificate $certificate is valid"
    } else {
        throw "invalid certificate $certificate"
    }
    $files = Get-ChildItem -Path $PSBPreference.Build.ModuleOutDir -Recurse -Include @("*.ps1", "*.psm1", "*.psd1")
    foreach ($file in $files) {
        $setAuthSigParams = @{
            FilePath    = $file.FullName
            Certificate = $certificate
            Verbose     = $VerbosePreference
        }

        $result = Microsoft.PowerShell.Security\Set-AuthenticodeSignature @setAuthSigParams
        if ($result.Status -ne 'Valid') {
            throw "Failed to sign script: $($file.FullName)."
        }

        Write-Verbose "Successfully signed script: $($file.Name)"
    }
    ##################
    ##################
    ##################
    #Remove-Module octoDeploy -Force -ErrorAction SilentlyContinue
    #Remove-Item "$env:BHBuildOutput\lib\octopus.client.dll" -Force
    ##################
    ##################
    ##################
} -description "Sign all ps1 psm1 psd1 files"

Task GenerateGraph -depends Build {
    $Graphs = Get-ChildItem -Path ".\graphs\*"

    foreach ($graph in $Graphs) {
        $graphLocation = [IO.Path]::Combine("$env:BHBuildOutput", "en-US", "$($graph.BaseName).png")
        . $graph.FullName -DestinationPath $graphLocation -Hide
    }
} -description "creating a pretty graph"
