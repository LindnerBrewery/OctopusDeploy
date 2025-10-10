<#
.SYNOPSIS
    Get tenants in Test environment with RIS database server role and DatabaseType variable
.DESCRIPTION
    Returns a list of all tenants in the test environment that have:
    - At least one machine with the role 'risdatabaseserver'
    - A common tenant variable in "Customer Variables" called DatabaseType[test]
.EXAMPLE
    PS C:\> .\Get-TenantsWithRisDatabaseServer.ps1
    Returns all matching tenants
#>

# Ensure we're connected to Octopus
# Connect-Octopus -Server "your-server" -ApiKey "your-api-key" -Space "your-space"

# Get the Test environment
Write-Host "Getting Test environment..." -ForegroundColor Cyan
$testEnvironment = Get-Environment -Name "Test"

if (!$testEnvironment) {
    Write-Error "Test environment not found!"
    return
}

Write-Host "Environment: $($testEnvironment.Name) (ID: $($testEnvironment.Id))" -ForegroundColor Green

# Get all tenants associated with the Test environment
Write-Host "`nGetting tenants in Test environment..." -ForegroundColor Cyan
$allTenants = Get-Tenant -Environment $testEnvironment

Write-Host "Found $($allTenants.Count) tenants in Test environment" -ForegroundColor Green

# Filter tenants that have machines with 'risdatabaseserver' role
Write-Host "`nFiltering tenants with 'risdatabaseserver' role..." -ForegroundColor Cyan
$tenantsWithRisDbServer = @()

foreach ($tenant in $allTenants) {
    Write-Host "  Checking tenant: $($tenant.Name)..." -NoNewline
    
    # Get machines for this tenant with the specific role and environment
    $machines = Get-Machine -Tenant $tenant -Role "risdatabaseserver" -Environment $testEnvironment
    
    if ($machines) {
        Write-Host " Found $($machines.Count) machine(s) with risdatabaseserver role" -ForegroundColor Green
        $tenantsWithRisDbServer += $tenant
    }
    else {
        Write-Host " No machines with risdatabaseserver role" -ForegroundColor Gray
    }
}

Write-Host "`nFound $($tenantsWithRisDbServer.Count) tenants with 'risdatabaseserver' role" -ForegroundColor Green

# Now check which of these tenants have the DatabaseType[test] variable
Write-Host "`nChecking for DatabaseType[test] variable in 'Customer Variables'..." -ForegroundColor Cyan
$finalTenants = @()

foreach ($tenant in $tenantsWithRisDbServer) {
    Write-Host "  Checking tenant: $($tenant.Name)..." -NoNewline
    
    try {
        # Get common tenant variables from "Customer Variables"
        $commonVars = Get-CommonTenantVariable -Tenant $tenant -VariableSet "Customer Variables"
        
        # Check if DatabaseType[test] variable exists
        $databaseTypeVar = $commonVars | Where-Object { $_.Name -eq "DatabaseType[test]" }
        
        if ($databaseTypeVar) {
            Write-Host " Has DatabaseType[test] variable (Value: $($databaseTypeVar.Value))" -ForegroundColor Green
            $finalTenants += [PSCustomObject]@{
                TenantName        = $tenant.Name
                TenantId          = $tenant.Id
                DatabaseTypeValue = $databaseTypeVar.Value
                IsDefaultValue    = $databaseTypeVar.IsDefaultValue
            }
        }
        else {
            Write-Host " No DatabaseType[test] variable found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host " Error checking variables: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Display results
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RESULTS: Tenants matching all criteria" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($finalTenants.Count -eq 0) {
    Write-Host "No tenants found matching all criteria" -ForegroundColor Yellow
}
else {
    Write-Host "Found $($finalTenants.Count) tenant(s):`n" -ForegroundColor Green
    $finalTenants | Format-Table -AutoSize
    
    Write-Host "`nTenant Names:" -ForegroundColor Cyan
    $finalTenants | ForEach-Object { Write-Host "  - $($_.TenantName)" -ForegroundColor White }
}

# Return the results
return $finalTenants
