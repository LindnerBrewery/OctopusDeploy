function Get-Tenant {
    <#
.SYNOPSIS
    Returns a list of tenants
.DESCRIPTION
    Returns a list of tenants
.EXAMPLE
    PS C:\> Get-Tenant
    Returns all tenants
.EXAMPLE
    PS C:\> Get-Tenant -Name XXROMDOC
    Returns tenant object of the tenant called XXROMDOC
    .EXAMPLE
    PS C:\> Get-Tenant -name XXROMDOC
    Returns tenant object of the tenant called XXROMDOC
#>
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        # Parameter help description
        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'Name' )]
        [AllowNull()]
        [AllowEmptyString()]
        [String]
        $Name,

        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ID' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ID,

        # Environment the tenant is associated with
        [Parameter(mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [EnvironmentSingleTransformation()]
        [Octopus.Client.Model.EnvironmentResource]
        $Environment,

        # TenantTag must be in form of CanonicalTagName
        [Parameter(mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Tag


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
        $result = [System.Collections.ArrayList]::new()
        if ($PSCmdlet.ParameterSetName -eq 'default') {
            $result = $repo._repository.Tenants.getall()
        }
        if ($PSCmdlet.ParameterSetName -eq 'Name') {
            $result = $repo._repository.Tenants.findbyname("$name")
            if ($null -eq $result) {
                $err = [System.Management.Automation.ErrorRecord]::new(
                    [System.Management.Automation.ItemNotFoundException]::new("Could not find a Tenant by the name of $name in space $($repo.space)"),
                    'NotSpecified',
                    'InvalidData',
                    $name
                )
                $errorDetails = [System.Management.Automation.ErrorDetails]::new("Could not find a Tenant by the name of $name in space $($repo.space)")
                $errorDetails.RecommendedAction = "Check you are in the right space. Use tab completion to find the tenant"
                $err.ErrorDetails = $errorDetails
                $PSCmdlet.WriteError($err)
            }
        }
        if ($PSCmdlet.ParameterSetName -eq 'ID') {
            try {
                $result = $repo._repository.Tenants.get("$id")
                if ($null -eq $result) {
                    $err = [System.Management.Automation.ErrorRecord]::new(
                        [System.Management.Automation.ItemNotFoundException]::new("Could not find a Tenant w the ID of $id in space $($repo.space)"),
                        'NotSpecified',
                        'InvalidData',
                        $id
                    )
                    $errorDetails = [System.Management.Automation.ErrorDetails]::new("Could not find a Tenant with the ID of $id in space $($repo.space)")
                    $errorDetails.RecommendedAction = "Try useing name instead. Check you are in the right space."
                    $err.ErrorDetails = $errorDetails
                    $PSCmdlet.WriteError($err)
                }
            }
            catch {}

        }

        # filter tenanttags
        filter Tagfilter {
            # default operator is and. it will only change to or if the or switch is used
            if ($or) {
                $operator = '-OR'
            }
            else {
                $operator = '-AND'
            }
            [String]$filter = "`$_.Tenanttags -contains `"{0}`"" -f $Tag[0]
            if ($Tag.Length -gt 1) {
                for ($i = 1; $i -lt $Tag.Length; $i++) {
                    [String]$filter += " $operator `$_.Tenanttags -contains `"{0}`"" -f $Tag[$i]
                }
            }
            if (Invoke-Command -ScriptBlock ([scriptblock]::Create($filter))) {
                $_
            }
        }
        if ($Tag) {
            $result = $result | Tagfilter
        }
        if ($Environment) {
            $result = foreach ($tenant in $result) {
                foreach ($value in $tenant.ProjectEnvironments.Values) {
                    if ($value -contains $Environment.Id) {
                        $tenant
                        break
                    }
                }
            }
        }
        return $result
    }
}
