$acScriptEnvironment = {
    param($commandName, $parameterName, $stringMatch)
    # remove ' from search string if there was an space in the word
    octopusdeploy\Get-Environment | Where-Object name -Like $stringMatch* | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        # If the result contains a white pace, then enclose it with quotation marks
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}
<#
Register-ArgumentCompleter -CommandName Add-ProjectToTenant -ParameterName Environment -ScriptBlock $acScriptEnvironment
Register-ArgumentCompleter -CommandName Remove-ProjectFromTenant -ParameterName Environment -ScriptBlock $acScriptEnvironment
Register-ArgumentCompleter -CommandName Remove-ProjectEnvironmentFromTenant -ParameterName Environment -ScriptBlock $acScriptEnvironment
Register-ArgumentCompleter -CommandName Get-TenantWithoutMachine -ParameterName Environment -ScriptBlock $acScriptEnvironment
#>
$acScriptProject = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    octopusdeploy\Get-Project | Where-Object name -Like $stringMatch* | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}
<#
Register-ArgumentCompleter -CommandName Add-ProjectToTenant -ParameterName Project -ScriptBlock $acScriptProject
Register-ArgumentCompleter -CommandName Remove-ProjectFromTenant -ParameterName Project -ScriptBlock $acScriptProject
Register-ArgumentCompleter -CommandName Remove-ProjectEnvironmentFromTenant -ParameterName Project -ScriptBlock $acScriptProject
Register-ArgumentCompleter -CommandName Get-Release -ParameterName Project -ScriptBlock $acScriptProject
Register-ArgumentCompleter -CommandName Get-Channel -ParameterName Project -ScriptBlock $acScriptProject
#>

$acScriptTenant = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    octopusdeploy\Get-Tenant | Where-Object name -Like $stringMatch* | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}

$acScriptMachineRole = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-MachineRole | Where-Object {$_ -Like "$stringMatch*"} | Sort-Object | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}

$acScriptTagSet = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-TagSet | Where-Object {$_.name -Like "$stringMatch*"} | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}
$acScriptCanonicalTagName = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-TagSet -CanonicalTagName | Where-Object {$_ -Like "$stringMatch*"} | Sort-Object   | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}

$acScriptMachine = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-Machine | Where-Object {$_.name -Like "$stringMatch*"} | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}

$acScriptTaskType = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-Tasktype | Where-Object {$_.id -Like "$stringMatch*"} | Sort-Object -Property Id | Select-Object -ExpandProperty Id
}

$acScriptRunbook = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-Runbook | Where-Object {$_.name -Like "$stringMatch*"} | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}
$acScriptVariableSet = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-VariableSet | Where-Object {$_.name -Like "$stringMatch*"} | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}

$acScriptProjectGroup = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-ProjectGroup | Where-Object {$_.name -Like "$stringMatch*"} | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}

$acScriptLifecycle = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-Lifecycle | Where-Object {$_.name -Like "$stringMatch*"} | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}

$acScriptProjectTrigger = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-ProjectTrigger | Where-Object {$_.name -Like "$stringMatch*"} | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}

$acScriptSpace = {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    Get-Space | Where-Object {$_.name -Like "$stringMatch*"} | Sort-Object -Property name | Select-Object -ExpandProperty name | ForEach-Object {
        if ($_.toCharArray() -contains ' ') {
            "'$_'"
        } else {
            $_
        }
    }
}

######################################
# register completers
######################################
# Non standard registrations
Register-ArgumentCompleter -CommandName Get-Tenant -ParameterName Name -ScriptBlock $acScriptTenant
Register-ArgumentCompleter -CommandName Get-Project -ParameterName Name -ScriptBlock $acScriptProject
Register-ArgumentCompleter -CommandName Get-Environment -ParameterName Name -ScriptBlock $acScriptEnvironment
Register-ArgumentCompleter -CommandName Get-TagSet -ParameterName Name -ScriptBlock $acScriptTagSet
Register-ArgumentCompleter -CommandName Get-VariableSet -ParameterName Name -ScriptBlock $acScriptVariableSet
Register-ArgumentCompleter -CommandName Get-Runbook -ParameterName Name -ScriptBlock $acScriptRunbook
Register-ArgumentCompleter -CommandName Set-Space -ParameterName Name -ScriptBlock $acScriptSpace
Register-ArgumentCompleter -CommandName New-Tenant -ParameterName TemplateTenant -ScriptBlock $acScriptTenant

#Auto register argument completers to all eligible cmdlets
$module = $MyInvocation.MyCommand.Module
$commands = Get-Command -Module $module

foreach ($command in $commands) {
    if ($command.Parameters.keys -contains "Tenant") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName Tenant -ScriptBlock $acScriptTenant
    }
    if ($command.Parameters.keys -contains "Project") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName Project -ScriptBlock $acScriptProject
    }
    if ($command.Parameters.keys -contains "Environment") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName Environment -ScriptBlock $acScriptEnvironment
    }
    if ($command.Parameters.keys -contains "MachineRole" -Or $command.Parameters.keys -contains "Role") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName MachineRole -ScriptBlock $acScriptMachineRole
        Register-ArgumentCompleter -CommandName $command.name -ParameterName Role -ScriptBlock $acScriptMachineRole
    }
    if ($command.Parameters.keys -contains "TagSet") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName TagSet -ScriptBlock $acScriptTagSet
    }
    if ($command.Parameters.keys -contains "Machine") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName Machine -ScriptBlock $acScriptMachine
    }
    if ($command.Parameters.keys -contains "TaskType") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName TaskType -ScriptBlock $acScriptTaskType
    }
    if ($command.Parameters.keys -contains "Runbook") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName Runbook -ScriptBlock $acScriptRunbook
    }
    if ($command.Parameters.keys -contains "VariableSet") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName VariableSet -ScriptBlock $acScriptVariableSet
    }
    if ($command.Parameters.keys -contains "Tag") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName Tag -ScriptBlock $acScriptCanonicalTagName
    }
    if ($command.Parameters.keys -contains "ProjectGroup") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName ProjectGroup -ScriptBlock $acScriptProjectGroup
    }
    if ($command.Parameters.keys -contains "Lifecycle") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName Lifecycle -ScriptBlock $acScriptLifecycle
    }
    if ($command.Parameters.keys -contains "ProjectTrigger") {
        Register-ArgumentCompleter -CommandName $command.name -ParameterName ProjectTrigger -ScriptBlock $acScriptProjectTrigger
    }

}



