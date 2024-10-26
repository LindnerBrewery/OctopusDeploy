# create a new function that excepts ApiKey (securestring or string), ApiUrl (uri), Space (string). save the parameters as an textfile in userprofile/powerhsell/octopusdeploy
#
function Write-ConfigFile {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [object]$ApiKey,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Uri]$Url,

        [Parameter(Mandatory = $false)]
        [string]$Space
    )
    process {

        # validate url. Replace with validationScript with error message when ps5.1 support is dropped
        if ($Url.AbsoluteURI -eq $null -or $url.Scheme -notmatch '^(http|https)$') {
            $err = [System.Management.Automation.ErrorRecord]::new(
                [System.UriFormatException]::new('URL is not a valid'),
                'PSOctopusdeploy.InvalidArgument',
                'InvalidArgument',
                $uri
            )
            $errorDetails = [System.Management.Automation.ErrorDetails]::new('URL is not a valid')
            $errorDetails.RecommendedAction = 'Double check your octopus url'
            $err.ErrorDetails = $errorDetails
            $PSCmdlet.ThrowTerminatingError($err)
        }
        # change path depending on the OS
        if ($isWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
            $dataFolder = [System.Environment]::GetFolderPath('LocalApplicationData')
        } else {
            $dataFolder = [System.Environment]::GetFolderPath('ApplicationData')
        }

        $configPath = [System.IO.FileInfo]::new("$dataFolder\powershell\octopusdeploy\config.json")
        if (-not (Test-Path -Path $configPath.DirectoryName)) {
            Write-Verbose "Creating directory $($configPath.DirectoryName)"
            New-Item -Path $configPath.DirectoryName -ItemType Directory -Force | Out-Null
        }
        if ($ApiKey) {
            if ($ApiKey -is [securestring]) {
                $ApiKey = "SecureString;" + (ConvertFrom-SecureString -SecureString $ApiKey)
            } elseif ($ApiKey -is [string]) {
                $ApiKey = "String;" + $ApiKey
            } else {
                $err = [System.Management.Automation.ErrorRecord]::new(
                    [System.TypeAccessException]::new('ApiKey is of unknown Typ'),
                    'PSOctopusDeploy.WrongType',
                    'InvalidType',
                    $null
                )
                $PSCmdlet.ThrowTerminatingError($err)
            }
        }

        $config = [PSCustomObject]@{
            Apikey = $ApiKey
            Url    = $Url
            Space  = $Space
        }

        $config | ConvertTo-Json | Set-Content -Path $configPath -Force
    }

}

