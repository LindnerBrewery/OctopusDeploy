function Confirm-Intervention {
    <#
    .SYNOPSIS
    Confirms a manual intervention in Octopus Deploy.

    .DESCRIPTION
    This function takes responsibility for a manual intervention and submits either a "Proceed" or "Abort" decision to Octopus Deploy.

    .PARAMETER Intervention
    The manual intervention object (InterruptionResource) to confirm. This parameter is mandatory.

    .PARAMETER Notes
    Optional notes to include with the confirmation. These notes will be visible in the Octopus Deploy audit log.

    .PARAMETER Action
    Specifies the action to take for the manual intervention. Valid values are "Proceed" or "Abort". This parameter is mandatory.

    .EXAMPLE
    PS C:\> Confirm-Intervention -Intervention $intervention -Action Proceed -Notes "Approved by team lead"
    Takes responsibility for the manual intervention and proceeds with it, including the provided notes.

    .EXAMPLE
    PS C:\> Confirm-Intervention -Intervention $intervention -Action Abort -Notes "Rejected due to security concerns"
    Takes responsibility for the manual intervention and aborts it, including the provided notes.

    .NOTES
    This function requires a valid connection to the Octopus Deploy server. Ensure that a connection is established before calling this function using Connect-Octopus.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [Octopus.Client.Model.InterruptionResource]
        $Intervention,

        [Parameter(Mandatory = $false)]
        [String]
        $Notes,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Proceed", "Abort")]
        [String]$Action
    )

    begin {
        try {
            ValidateConnection
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess("Manual Intervention", "Confirm intervention with action: $Action")) {
            try {
                $repo._repository.Interruptions.TakeResponsibility($Intervention)

                $Intervention.Form.Values['Notes'] = $Notes
                $Intervention.Form.Values['Result'] = $Action

                $repo._repository.Interruptions.Submit($Intervention)

                Write-Verbose "Manual intervention confirmed with action: $action"
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }

    end {}
}
