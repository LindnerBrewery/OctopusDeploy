using namespace System.IO
using module '.\Classes\Classes.psm1'
using module '.\Classes\TransformerClasses.psm1'

# Dot source public/private functions
$public = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public/*.ps1')  -Recurse -ErrorAction Stop)
$private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private/*.ps1') -Recurse -ErrorAction Stop)
#$classes = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Classes/*.ps1') -Recurse -ErrorAction Stop)
foreach ($import in @($public + $private)) {
    try {
        . $import.FullName
    } catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

Export-ModuleMember -Function $public.Basename

# connect to octopus if connection data are present
try{
    Connect-Octopus
} catch {
    Write-Warning $_.Exception.Message
    Write-Warning "Unable to connect to Octopus Deploy server. Please use the Connect-Octopus cmdlet to connect to the server"
}


