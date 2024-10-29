<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\>  Set-ConnectionConfiguration -OctopusServerURL https://octopus.instance.com -Credential (Get-Credential)
    Saves connection setting with credentials as authentication method
.EXAMPLE
    PS C:\>  Set-ConnectionConfiguration -OctopusServerURL https://octopus.instance.com -ApiKey ("API-XXXXXXXXXXXXXX" | ConvertTo-SecureString -AsPlainText -Force)
    Saves connection setting with ApiKey as authentication method
#>
function Set-ConnectionConfiguration {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param (
        # Param1 help description
        [Parameter(Mandatory = $false,
            Position = 0,
            ParameterSetName = 'ApiKey')]
        [Parameter(Mandatory = $false,
            Position = 0,
            ParameterSetName = 'default')]
        [ValidateNotNullOrEmpty()]
        [Alias("Url")]
        $OctopusServerURL,


        # Param3 help description
        [Parameter(Mandatory = $true,
            Position = 1,
            ParameterSetName = 'ApiKey')]
        [ValidateScript({ if ($_.GetType().Name -eq 'SecureString' -or $_.GetType().Name -eq 'String') { $true }else { Throw "Parameter not of Type SecureString or String" } })]
        [object]
        $ApiKey,

        # Insecure!!! beware and only use if you know what you are doing!!!!!
        [Parameter(Mandatory = $false,
            Position = 2,
            ParameterSetName = 'ApiKey')]
        [switch]
        $AsPlainText,

        # Parameter Space. optional parameter that works with all other parametersets
        [Parameter(Mandatory = $false,
            Position = 3,
            ParameterSetName = 'ApiKey')]
        [Parameter(Mandatory = $false,
            Position = 2,
            ParameterSetName = 'default')]
        [string]
        $Space
    )

    begin {
    }

    process {
        $currentConfiguration = Get-ConnectionConfiguration
        $version = [version]'2.0'
        $configurationHash = @{
            URL                        = $currentConfiguration.URL
            ApiKey                     = $currentConfiguration.ApiKey
            Space                      = $currentConfiguration.Space
        }

        # convert securestring to plain text if requested
        if ($PSCmdlet.ParameterSetName -eq "ApiKey") {
            if ($AsPlainText -and $ApiKey.GetType().Name -eq 'SecureString') {
                $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiKey))
            }

            # convert ApiKey to SecureString if not already
            if (!$AsPlainText -and $ApiKey -and $ApiKey.GetType().Name -eq 'String') {
                $ApiKey = $ApiKey | ConvertTo-SecureString -AsPlainText -Force
            }
            $configurationHash.ApiKey = $ApiKey
        }

        if ($PSBoundParameters.keys -contains 'Space') {
            $configurationHash.Space = $Space
        }
        if ($OctopusServerURL) {
            $configurationHash.URL = $OctopusServerURL
        }

        # Check there are values for URL and APIKey in configuration hash
        if ([System.String]::IsNullOrEmpty($configurationHash.URL) -or [System.String]::IsNullOrEmpty($configurationHash.ApiKey)) {
            Throw "URL and APIKey are required parameters"
        }


        Write-ConfigFile @configurationHash

    }

    end {
    }
}
