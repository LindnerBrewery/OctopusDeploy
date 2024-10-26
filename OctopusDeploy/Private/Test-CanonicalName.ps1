function Test-CanonicalName {
    param (
        $tag
    )
    if (Get-TagSet -CanonicalTagName | Where {$_ -eq $tag}){return $true}else{return $false}
}
