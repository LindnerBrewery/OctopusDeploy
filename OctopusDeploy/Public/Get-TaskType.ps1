function Get-TaskType {
<#
.SYNOPSIS
    Returns all Task Types
.DESCRIPTION
    Returns all task types as Octopus.Client.Model.TaskTypeResource
.EXAMPLE
    PS C:\> Get-TaskType
    Returns all task types
.OUTPUTS
    Octopus.Client.Model.TaskTypeResource

#>
    [CmdletBinding(PositionalBinding=$false,
                   HelpUri = 'http://www.octopus.com/',
                   ConfirmImpact='low')]
    [OutputType([Octopus.Client.Model.TaskTypeResource])]
    Param ()

    process {
        $repo._repository.Tasks.GetTaskTypes()
    }

}
