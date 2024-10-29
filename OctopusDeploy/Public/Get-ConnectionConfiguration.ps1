<#
.SYNOPSIS
    Returns saved configuration
.DESCRIPTION
    Returns saved octopus connection configuration.
.EXAMPLE
    PS C:\>  Get-ConnectionConfiguration
    Returns saved configuration
#>
function Get-ConnectionConfiguration {
    [CmdletBinding()]
    Param (

    )

    begin {
    }

    process {
        # $module = $MyInvocation.MyCommand.Module
        # $moduleData = Import-PowerShellDataFile "$($module.modulebase)\$($module.name).psd1"

        # $config = Import-Configuration -Name $module.name -CompanyName $moduleData.Companyname
        $config = Read-ConfigFile
        $config
    }

    end {
    }
}
