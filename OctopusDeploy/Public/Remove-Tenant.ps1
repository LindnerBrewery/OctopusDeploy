function Remove-Tenant {

    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    param (
        # Parameter help description
        [Parameter(mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]
        $Tenant,
        [switch]$Force

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
        if ($Force.IsPresent -or $PSCmdlet.ShouldProcess("$($Tenant.name)", "Delete Tenant")) {
            try {
                $repo._repository.Tenants.Delete($Tenant)
                Write-Host ("Removed Tenant {0}" -f $Tenant.name)
            } catch {
                $PSCmdlet.WriteError($_)
                return
            }
        }
    }

    end {}
}
