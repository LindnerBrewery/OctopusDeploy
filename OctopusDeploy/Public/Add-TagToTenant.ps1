function Add-TagToTenant {
    <#
.SYNOPSIS
    Add a tag to one or many tenants
.DESCRIPTION
    Add a tag to one or many tenants by passing the tagset and tag or canonicaltagname
.EXAMPLE
    PS C:\> Add-TagToTenant -Tenant dd-TagToTenant -Tenant XXROMDOC -Tag 'News and Messages/de_DE'
    Adds a tag to tenant XXROMDOC
.EXAMPLE
    PS C:\> Add-TagToTenant -Tenant XXROMDOC -Tag 'News and Messages/en_Int'
    Adds tag 'News and Messages/en_Int' to tenant XXROMDOC
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory,
            ValueFromPipelineByPropertyName = $true,
            valueFromPipeline = $true,
            ParameterSetName = "CanonicalTagName")]
        [Parameter(mandatory,
            ValueFromPipelineByPropertyName = $true,
            valueFromPipeline = $true,
            ParameterSetName = "Tag")]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [TenantTransformation()]
        [Octopus.Client.Model.TenantResource[]]
        $Tenant,

        [Parameter(mandatory,
            ParameterSetName = "Tag")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Tag

    )
    begin {
        Test-OctopusConnection | Out-Null
    }
    process {

        if (Test-CanonicalName -tag $tag) {
            foreach ($_Tenant in $Tenant) {
                if ($_Tenant.TenantTags.Add($tag)) {
                    $_Tenant = $repo._repository.Tenants.Modify($_Tenant)
                    $message = "Added {0} from {1}" -f $tag, $_Tenant.name
                    Write-Verbose $message
                } else {
                    Write-Verbose "No changes to $($_Tenant.name) have been made"
                }


            }
        } else {
            Throw "$tag isn't a known tag"
        }

    }
    end {}
}
