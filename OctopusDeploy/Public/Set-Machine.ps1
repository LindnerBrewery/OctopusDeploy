#function is beeing worked on
# TODO: Implement a function to change machine name and if tenanted or untenanted deployment
function _Set-Machine {
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true )]
        [ValidateNotNullOrEmpty()]
        [Octopus.Client.Model.MachineResource]
        $Machine,
        [Parameter(mandatory = $false)]
        [String]$NewName,
        [Parameter(mandatory = $false)]
        [Octopus.Client.Model.TenantedDeploymentMode]$TenantedDeploymentParticipation


    )
    process {
        Test-OctopusConnection | out-null
        #$repo._repository.Machines.getall()
        if ($PSBoundParameters['TenantedDeploymentParticipation']) {
            $Machine.TenantedDeploymentParticipation = $TenantedDeploymentParticipation
        }
        $bp = $PSBoundParameters
        switch ($PSBoundParameters.Keys) {
            TenantedDeploymentParticipation {
                $Machine.TenantedDeploymentParticipation = $TenantedDeploymentParticipation
            }
            NewName {
                $Machine.name = $NewName
            }
        }

        try {
            $repo._repository.Machines.Modify($Machine)
        } catch {
            throw "couldn't modify machine"
        }
    }
}
