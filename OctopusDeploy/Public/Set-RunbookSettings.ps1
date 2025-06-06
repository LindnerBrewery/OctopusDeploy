function Set-RunbookSettings {
    <#
    .SYNOPSIS
        Sets the settings of a runbook. But not 'Deployment Target Status' and 'Default Failure Mode'
    .DESCRIPTION
        Sets the following settings of a runbook:
        Name
        Description
        RunRetentionPolicy
        EnvironmentScope
        MultiTenancyMode
        ForcePackageDownload
    .PARAMETER Runbook
        Specifies the runbook object to set the settings for.
    .PARAMETER Name
        Specifies the name of the runbook to set.
    .PARAMETER Description
        Specifies the description of the runbook.
    .PARAMETER RunRetentionPolicy
        Specifies the run retention policy of the runbook. Valid values are 0 (keep forever) and 1-10000 (number of runs to keep).
    .PARAMETER EnvironmentScope
        Specifies the environment scope of the runbook. Valid values are 'All', 'FromProjectLifecycles', and 'Specified'.
        The parameter EnvironmentScope 'Specified' requires to manage the Environments in Octopus Deploy UI.
    .PARAMETER MultiTenancyMode
        Specifies the multi-tenancy mode of the runbook. Valid values are 'Tenanted', 'TenantedOrUntenanted', and 'Untenanted'.
    .PARAMETER ForcePackageDownload
        Specifies whether to force the package download for the runbook.
    .EXAMPLE
        Set-RunbookSettings -Runbook 'RunbookName' -Description 'New Description' -RunRetentionPolicy 1000 -MultiTenancyMode 'Tenanted'
        Set-RunbookSettings -Runbook $runbookObj -EnvironmentScope 'Specified'
        Set-RunbookSettings -Runbook $runbookObj -EnvironmentScope 'All'
        Set-RunbookSettings -Runbook $runbookObj -RetentionPolicy 1000
        Set-RunbookSettings -Runbook $runbookObj -Name 'DBMS Mig - DNA-000 - Draftbook' -Description 'This is just a draft' -MultiTenancyMode 'Tenanted'
        Set-RunbookSettings -Runbook $runbookObj -ForcePackageDownload $true
    #>
    [CmdletBinding()]
    param (
        # Parameter help description

        [Parameter(mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [RunbookSingleTransformation()]
        [Octopus.Client.Model.RunbookResource]
        $Runbook,

        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(0, 10000)]
        [int]
        $RetentionPolicy,

        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('All', 'FromProjectLifecycles', 'Specified')]
        [string]
        $EnvironmentScope,

        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Tenanted', 'TenantedOrUntenanted', 'Untenanted')]
        [string]
        $MultiTenancyMode,

        [Parameter(mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [bool]
        $ForcePackageDownload
    )
    begin {
        try {
            ValidateConnection
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        if ($Name) {
            $Runbook.Name = $Name
        }

        if ($Description) {
            $Runbook.Description = $Description
        }

        if ($PSBoundParameters.ContainsKey("RetentionPolicy")) {
            if ($RetentionPolicy -eq 0) {
                Write-Warning "Setting RetentionPolicy to 0 will keep runbooks forever. This is not recommended."
                $Runbook.RunRetentionPolicy.ShouldKeepForever = $true
            } else {
                $Runbook.RunRetentionPolicy.ShouldKeepForever = $false
            }
            $Runbook.RunRetentionPolicy.QuantityToKeep = $RetentionPolicy
            $Runbook.RunRetentionPolicy
        }

        if ($EnvironmentScope) {
            if ($EnvironmentScope -eq 'Specified') {
                Write-Warning "The parameter EnvironmentScope 'Specified' requires to manage the Environments in Octopus Deploy UI."
            } else {
                $Runbook.Environments.Clear()
            }
            $Runbook.EnvironmentScope = $EnvironmentScope
        }

        if ($MultiTenancyMode) {
            $Runbook.MultiTenancyMode = $MultiTenancyMode
        }
        
        if ($ForcePackageDownload) {
            $Runbook.ForcePackageDownload = $ForcePackageDownload
        }

        $repo._repository.Runbooks.Modify($Runbook)

    }
    end {}
}

