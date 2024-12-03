<#
.SYNOPSIS
Creates a new tenant in Octopus Deploy.

.DESCRIPTION
The New-Tenant function creates a new tenant in Octopus Deploy. It can either create a new tenant from scratch or clone an existing tenant, inheriting all projects and tags from the template tenant.

.PARAMETER Name
The name of the new tenant. This parameter is mandatory.

.PARAMETER TemplateTenant
The tenant to clone from. The new tenant will inherit all projects and tags from the template tenant. This parameter is optional.

.EXAMPLE
PS> New-Tenant -Name "NewTenant"

Creates a new tenant named "NewTenant".

.EXAMPLE
PS> New-Tenant -Name "NewTenant" -TemplateTenant "TemplateTenant"

Clones the tenant "TemplateTenant" to create a new tenant named "NewTenant".

.EXAMPLE
PS> Get-Tenant -Name "TemplateTenant" | New-Tenant -Name "NewTenant"

Clones the tenant "TemplateTenant" to create a new tenant named "NewTenant".

.NOTES
This function requires an active connection to the Octopus Deploy server. If the connection cannot be established, the function will throw a terminating error.
#>
function New-Tenant {

    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium')]
    [Alias()]
    Param (
        # Name of the tenant
        [Parameter(mandatory = $true,
            ValueFromPipeline = $false,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        # Tenant to clone from. New Tenant will inherit all projects and tags from the template tenant
        [Parameter(mandatory = $false,
            ValueFromPipeline = $true,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [TenantSingleTransformation()]
        [Octopus.Client.Model.TenantResource]
        $TemplateTenant
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

        #create a new tenant
        if ($pscmdlet.ShouldProcess("$name", "Creating new tenant")) {
            if ($TemplateTenant){
                # set new tenant to be a clone of the template tenant
                $tenantResource = $TemplateTenant
                $tenantResource.name = $Name
                $tenantResource.ClonedFromTenantId = $TemplateTenant.Id
                $tenantResource.Id = $null
                $tenantResource.Slug =  $null
            }else{
                # create a new tenant
                $tenantResource = [Octopus.Client.Model.TenantResource]::new()
                $tenantResource.Name = $name
            }
            try {
                #create a new tenant
                $repo._repository.Tenants.Create($tenantResource)
            }
            catch {
                $PSCmdlet.WriteError($_)
            }
        }
    }

    end {}
}
