function Remove-TagFromTenant {
    <#
.SYNOPSIS
    Removes a Tag to one or many tenants
.DESCRIPTION
    Removes a Tag to one or many tenants
.EXAMPLE
    Remove-TagToTenant -Tag "Rolloutgroups/DB-2" -Tenant DEBON06R -Verbose
.EXAMPLE
    PS C:\>
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Tag,
        [Parameter(mandatory,
            ValueFromPipelineByPropertyName = $true,
            valueFromPipeline = $true)]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [TenantTransformation()]
        [Octopus.Client.Model.TenantResource[]]
        $Tenant

    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {


        if (Test-CanonicalName -tag $tag) {
            foreach ($_Tenant in $Tenant) {
                if ($_Tenant.TenantTags.Remove($tag)) {
                    $_Tenant = $repo._repository.Tenants.Modify($_Tenant)
                    $message = "Removed {0} from {1}" -f $tag, $_Tenant.name
                    Write-Verbose $message
                }else {
                    Write-Verbose "No changes to $($_Tenant.name) have been made"
                }
            }

        } else {
            Throw "$tag isn't a known tag"
        }
    }


    end {}
}
