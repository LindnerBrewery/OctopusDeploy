# create a new function that excepts ApiKey (securestring or string), ApiUrl (uri), Space (string). save the parameters as an textfile in userprofile/powerhsell/octopusdeploy
#
function Read-ConfigFile {
    [cmdletBinding()]
    param (
    )

    # change path depending on the OS
    if ($isWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
        $dataFolder = [System.Environment]::GetFolderPath('LocalApplicationData')
    } else {
        $dataFolder = [System.Environment]::GetFolderPath('ApplicationData')
    }

    $configPath =  [System.IO.FileInfo]::new("$dataFolder\powershell\octopusdeploy\config.json")

    if (-not (Test-Path -Path $configPath)) {
        Write-Verbose "No configuration file found"
        return
    }
    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    $apiKeyRaw = $config.Apikey -Split';'
    if($apiKeyRaw[0] -eq "SecureString"){
        $config.Apikey = ConvertTo-SecureString -String $apiKeyRaw[1]
    }else{
        $config.Apikey = $apiKeyRaw[1]
    }

    $config
}

