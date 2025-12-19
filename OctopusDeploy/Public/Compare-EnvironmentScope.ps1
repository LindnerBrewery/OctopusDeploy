function Compare-EnvironmentScope {
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$ExistingScope,

        # allow empty for new scope to represent unscoped
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$NewScope
    )
    $existing = if ($ExistingScope) { $ExistingScope | Sort-Object -Unique } else { @() }
    $new = if ($NewScope) { $NewScope | Sort-Object -Unique } else { @() }
                        
    # Exact match
    if (($existing -join ',') -eq ($new -join ',')) {
        return [pscustomobject]@{ Status = 'Equal'; ExistingScope = $existing; NewScope = $null }
    }

    $intersection = $existing | Where-Object { $new -contains $_ }
    $remaining = $existing | Where-Object { $new -notcontains $_ }

    # No overlap
    if (-not $intersection) {
        return [pscustomobject]@{ Status = 'Disjoint'; ExistingScope = $existing; NewScope = $new }
    }
                        
    # Partial overlap where existing has items not in new (Existing is superset or mixed)
    if ($remaining) {
        return [pscustomobject]@{ Status = 'Overlap'; ExistingScope = $remaining; NewScope = $new }
    }
                        
    # Intersection exists and no remaining items in existing (Existing is subset of New)
    return [pscustomobject]@{ Status = 'Contained'; ExistingScope = $null; NewScope = $new }
}
