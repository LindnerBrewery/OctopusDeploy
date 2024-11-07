# playing around with the idea of using the Octopus.Client or rest api to get a list of variables from a project

[string]$path = '/api/Spaces-1/variables/names'
$repo = Get-OctopusRepositoryObject
# Make Generic List method
$genericMethod = $repo._repository.Client.GetType().GetMethod("List").MakeGenericMethod([System.Array])

# Set path parameters for call
$pathParameters = [System.Collections.Generic.Dictionary[String, Object]]::new()
$pathParameters.Add("project", 'Projects-282')
$pathParameters.Add("gitRef", 'refs/heads/main')
# Set generic method parameters
$parameters = [System.Collections.Generic.List[Object]]::new()
$parameters = $path, $pathParameters

# Invoke the List method
$results = $genericMethod.Invoke($repo._client, $parameters)

function Get-OctopusResource {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$BaseUri,
        [Parameter()]
        [string]$uri,
        [Parameter()]
        [string]$ApiKey
    )
    $headers = @{"X-Octopus-ApiKey" = $apiKey }
    #Write-Host "[GET]: $uri"
    $uri = $uri.TrimStart("/")
    $result = Invoke-RestMethod -Method Get -Uri "$baseUri/$uri" -Headers $headers
    Write-Verbose ($result | ConvertTo-Json -Depth 10)
    return $result
}
$c = Get-ConnectionConfiguration
$p = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($c.Apikey))
$s = Get-CurrentSpace
Get-OctopusResource -BaseUri $c.Url -uri "/api/$($s.id)/variables/names?project=Projects-282&gitRef=refs%2Fheads%2Fmain" -ApiKey $p
