function Connect-Octopus {
    <#
.SYNOPSIS
    Connects to octopus server.
.DESCRIPTION
    Connects to octopus server by using the saved credentials or by passing in server and credentials. Credentials can be APIKey or as credential object
.EXAMPLE
    PS C:\> Connect-Octopus
    Connect by using saved connection parameters
.EXAMPLE
    PS C:\> Connect-Octopus -OctopusServerURL https://octopus.instance.com -ApiKey ("API-XXXXXXXXXXXXXX" | ConvertTo-SecureString -AsPlainText -Force)
    Connect by passing server and apikey
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    [OutputType([Void])]
    param (
        # Parameter help description
        [Parameter(Mandatory = $true,
            ParameterSetName = "apiKey")]
        [String]
        $OctopusServerURL,

        # Parameter help description
        [Parameter(Mandatory = $true,
            ParameterSetName = "apiKey")]
        [ValidateScript({ if ($_.GetType().Name -eq 'SecureString' -or $_.GetType().Name -eq 'String') { $true }else { Throw "Parameter not of Type SecureString or String" } })]
        [object]
        $ApiKey,

        #parameter space
        [Parameter(Mandatory = $false,
            ParameterSetName = "apiKey")]
        [String]
        $Space


    )

    begin {

    }

    process {
        #connecting with saved configuration
        if ($PSCmdlet.ParameterSetName -eq 'default') {
            $config = Get-ConnectionConfiguration
            # check if there is a saved configuration and try to connect
            if ($config.count -ne 0) {
                #if ($config.keys -contains "ApiKey") {
                if ($config.ApiKey -ne $null) {
                    $connectOctopusSplat = @{
                        OctopusServerURL = $config.URL.toString()
                        ApiKey           = $config.APIKey
                    }
                    if ($config.space) {
                        $connectOctopusSplat.Add("Space", $config.space)
                    }
                    Connect-Octopus @connectOctopusSplat
                } else {
                    $getcustomErrorSplat = @{
                        Message   = "Unknown connection method found in configuration. Please use the Set-ConnectionConfiguration to save your configuration persistently or use Connect-Octopus with URL and API key for a one time login"
                        Category  = 'AuthenticationError'
                        Exception = 'System.Security.Authentication.AuthenticationException'
                        ErrorID   = "OctopusDeploy.AuthenticationError"
                    }
                    $err = Get-customError @getcustomErrorSplat
                    $PSCmdlet.ThrowTerminatingError($err)

                }
            } else {
                $getcustomErrorSplat = @{
                    Message   = "No saved configuration has been found. Please use the Set-ConnectionConfiguration to save your configuration persistently or use Connect-Octopus with URL and API key for a one time login"
                    Category  = 'AuthenticationError'
                    Exception = 'System.Security.Authentication.AuthenticationException'
                    ErrorID   = "OctopusDeploy.AuthenticationError"
                }
                $err = Get-customError @getcustomErrorSplat
                $PSCmdlet.ThrowTerminatingError($err)
            }
        }
        if ($PSCmdlet.ParameterSetName -eq "apiKey") {
            if ($ApiKey -is [string]) {
                Write-Warning "You are using a plaintext api key!"
            }
            # check if OctopusserverURL is a valid URL
            if (-not ($OctopusServerURL -as [uri])) {
                $getcustomErrorSplat = @{
                    Message   = "The OctopusServerURL is not a valid URL"
                    Category  = 'ConnectionError'
                    Exception = 'System.ArgumentException'
                    ErrorID   = "OctopusDeploy.ConnectionError"
                }
                $err = Get-customError @getcustomErrorSplat
                $PSCmdlet.ThrowTerminatingError($err)
            }
            # check if octopusserverurl is reachable
            try {
                Invoke-WebRequest $OctopusServerURL -UseBasicParsing | Out-Null
            } catch {
                $getcustomErrorSplat = @{
                    Message   = $_.Exception.Message
                    Category  = 'ConnectionError'
                    Exception = 'System.Net.WebException'
                    ErrorID   = "OctopusDeploy.ConnectionError"
                }
                $err = Get-customError @getcustomErrorSplat
                $PSCmdlet.ThrowTerminatingError($err)
            }
            $script:repo = [Repository]::new($OctopusServerURL, $ApiKey)
            if ($space) {
                SetSpace -Name $Space
            }
        }
    }

    end {

    }
}
