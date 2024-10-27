properties {
    # Set this to $true to create a module with a monolithic PSM1
    $PSBPreference.Build.CompileModule = $false
    $PSBPreference.Help.DefaultLocale = 'en-US'
    $PSBPreference.Test.OutputFile = 'out/testResults.xml'
    $PSBPreference.General.ModuleVersion = dotnet-gitversion /showvariable MajorMinorPatch
    $PSBPreference.Test.ScriptAnalysis.FailBuildOnSeverityLevel = 'Error'
    $PSBPreference.Test.ImportModule = $true
}

task Default -depends buildmodule

# task Test -FromModule PowerShellBuild -minimumVersion '0.6.1' -depends UpdateVersion, build, pester
# task build -FromModule PowerShellBuild -minimumVersion '0.6.1' #-depends UpdateVersion
task init -FromModule PowerShellBuild -minimumVersion '0.6.1'
task buildmodule -depends init, clean, stagefiles, UpdateVersion, GENERATEMARKDOWN, GENERATEMAML, BUILDHELP, Test

Task UpdateVersion  {
    $file = "$env:BHBuildOutput\$env:BHProjectName.psd1"
    Write-Host ("Updating version in {0}" -f $file)
    $newVersion = dotnet-gitversion /showvariable MajorMinorPatch
    $prereleaseVersion = (dotnet-gitversion /showvariable NuGetPreReleaseTag) -replace "-",""
    if (! $prereleaseVersion) {
        $prereleaseVersion = ' '
    }
    #update version in psd1
    # Read all lines from the file
    $content = Get-Content -Path $file
    # Find and replace the ModuleVersion line
    $versionPattern = '^\s*ModuleVersion\s*=\s*[''"]([0-9]+\.?)+[''"]'
    $newVersionLine = "ModuleVersion = '$NewVersion'"
    $updated = $false
    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $versionPattern) {
            $content[$i] = $content[$i] -replace $versionPattern, $newVersionLine
            $updated = $true
            break
        }
    }
    if (-not $updated) {
        throw "ModuleVersion line not found in the PSD1 file"
    }
    # Save the updated content
    $content | Set-Content -Path $file  -Encoding UTF8
    Write-Host "Successfully updated ModuleVersion to $NewVersion in $Path"
    if ($prereleaseVersion) {
        $moduleversion = ("{0}-{1}" -f $moduleversion, $prereleaseVersion)
        update-ModuleManifest -Path $file  -ModuleVersion $newVersion -Prerelease $prereleaseVersion
    }
    $moduledata = Import-PowerShellDataFile -Path $file
    $moduleversion = $moduledata.ModuleVersion
    $prereleaseVersion = $moduledata.PrivateData.psdata.prerelease
    if ($prereleaseVersion) {
        $moduleversion = ("{0}-{1}" -f $moduleversion, $prereleaseVersion)
    }
    Write-Host ("Version is: {0}" -f $moduleversion)
} -description 'updates the psd1 version in releases'


