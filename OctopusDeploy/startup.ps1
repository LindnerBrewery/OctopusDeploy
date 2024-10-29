# Load the Octopus.Client.dll from the Lib folder
# $octoClientDll = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.location -and $_.Fullname -like "Octopus.Client*" }
# if ($octoClientDll) {
#     $fullname = $octoClientDll.fullname.split(",").trim()
#     $msg = "{0} in Version {1} is already loaded" -f $fullname[0], $fullname[1].split("=")[1]
#     Write-Warning $msg
# } else {
#     $invocation = $MyInvocation
#     #$($invocation.PSScriptRoot)
#     #Add-Type -Path "$($invocation.PSScriptRoot)\Lib\$($PSVersionTable.psedition)\Octopus.Client.dll" -ErrorAction Continue
#     Add-Type -Path "$PSScriptRoot\Lib\$($PSVersionTable.psedition)\Octopus.Client.dll" -ErrorAction Continue
# }
Add-Type -Path "$PSScriptRoot\Lib\$($PSVersionTable.psedition)\Octopus.Client.dll" -ErrorAction Continue

