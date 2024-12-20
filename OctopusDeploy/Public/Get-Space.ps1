﻿function Get-Space {
<#
.SYNOPSIS
    Returns a list of spaces within the octopus instance according to you rights

.EXAMPLE
    PS C:\> Get-Space
    Returns a list of space
#>
    [CmdletBinding()]
    [Alias()]
    [OutputType([String])]
    Param (
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
        $repo._repository.Spaces.GetAll()
    }

    end {}
}
