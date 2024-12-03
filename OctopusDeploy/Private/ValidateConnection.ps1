function ValidateConnection  {
    param ()
    if (!(Test-OctopusConnection)) {
        $err = [System.Management.Automation.ErrorRecord]::new(
            [System.Net.WebException]::new('Unable to connect to Octopus Deploy server. Please use the Connect-Octopus cmdlet to connect to the server'),
            'Octopusdeploy.NotConnectedToServer',
            'ConnectionError',
            $null
        )
        $errorDetails = [System.Management.Automation.ErrorDetails]::new('Unable to connect to Octopus Deploy server. Please use the Connect-Octopus cmdlet to connect to the server')
        $errorDetails.RecommendedAction = 'Use Connect-Octopus or try saving you credentials persistantly by using Set-ConnectionConfiguration'
        $err.ErrorDetails = $errorDetails
        $PSCmdlet.ThrowTerminatingError($err)
    }
}
