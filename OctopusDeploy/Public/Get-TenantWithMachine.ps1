function Get-TenantWithMachine {
<#
.SYNOPSIS
    Deprecated will be removed in future versions

#>
    param ()
    Write-Warning "Function is deprecated and will be removed in future versions"
    $m = get-machine
    $id = [System.Collections.ArrayList]::new()
    foreach ($_m in $m) {
        $_m.tenantIds.split(",").Trimstart().trimend() | ForEach-Object { $id.add($_) | out-null }

    }
    $group = $id | Group-Object -NoElement


    #Slow
    <#
    foreach ($_group in $group) {
        [PSCustomObject]@{
            Name = (Get-Tenant -ID $_group.Name).Name
            ID = $_group.Name
            NumberOfMachines =  $_group.Count
        }
    }
    #>
    $tenants = get-tenant
    foreach ($_group in $group) {
        [PSCustomObject]@{
            Name         = ($tenants | Where-Object ID -eq $_group.Name).Name
            ID           = $_group.Name
            MachineCount = $_group.Count

        }
    }
    Write-Warning "Function is deprecated and will be removed in future versions"
}
