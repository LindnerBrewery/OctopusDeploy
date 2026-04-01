$allProjects = Get-Project
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Projects and Packages")
$lines.Add("")
$lines.Add("| Project | Packages |")
$lines.Add("|---------|----------|")
$i = 0
foreach ($proj in $allProjects) {
    $i++
    Write-Host "[$i/$($allProjects.Count)] $($proj.Name)"
    $pkgs = @()
    try {
        $dp = Get-DeploymentProcess -Project $proj -ErrorAction Stop
        if ($dp -and $dp.Steps) {
            $pkgs = @($dp.Steps | ForEach-Object { $_.Actions } | ForEach-Object { $_.Packages } | Where-Object { $_.PackageId } | Select-Object -ExpandProperty PackageId -Unique)
        }
    } catch {
        Write-Host "  skipped: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    $pkgList = if ($pkgs.Count -gt 0) { $pkgs -join ", " } else { "*(none)*" }
    $lines.Add("| $($proj.Name) | $pkgList |")
}
[System.IO.File]::WriteAllLines("C:\GIT\OctopusDeploy\ProjectPackages.md", $lines)
Write-Host "`nDone. $i projects processed." -ForegroundColor Green
