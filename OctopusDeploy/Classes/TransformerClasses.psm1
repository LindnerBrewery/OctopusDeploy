class ProjectTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $result = @()
        foreach ($item in $InputData) {
            if ($item -is [string] -and $item -like "Projects-*") {
                $item = Get-Project -ID $item
            }
            elseif ($item -is [string]) {
                $item = Get-Project -Name $item
            }
            $result += ($item)
        }
        return ($result)
    }
}

class ProjectSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        if ($InputData -is [string] -and $InputData -like "Projects-*") {
            $item = Get-Project -ID "$InputData"
        }
        elseif ($InputData -is [string]) {
            $item = Get-Project -Name "$InputData"
        }
        elseif ($InputData -is [Octopus.Client.Model.ProjectResource]) {
            $item = $InputData
        }
        else {
            $item = $null
        }
        return ($item)
    }
}

class TenantTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $result = @()
        foreach ($item in $InputData) {
            if ($item -is [string] -and $item -like "Tenants-*") {
                $item = Get-Tenant -ID "$item"
            }
            elseif ($item -is [string]) {
                $item = Get-Tenant -Name "$item"
            }
            $result += ($item)
        }
        return ($result)
    }
}
class TenantSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "Tenants-*") {
            $item = Get-Tenant -ID "$item"
        }
        elseif ($item -is [string]) {
            $item = Get-Tenant -Name "$item"
        }
        return ($item)
    }

}
class EnvironmentTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $result = @()
        foreach ($item in $InputData) {
            if ($item -is [string] -and $item -like "Environments-*") {
                $item = Get-Environment -ID $item
            }
            elseif ($item -is [string]) {
                $item = Get-Environment -Name $item
            }
            $result += ($item)
        }
        return ($result)
    }
}
class EnvironmentSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "Environments-*") {
            $item = Get-Environment -ID $item
        }
        elseif ($item -is [string]) {
            $item = Get-Environment -Name $item
        }
        return $item
    }
}
class ChannelTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "Channels-*") {
            $item = Get-Channel -ID $item
        }
        elseif ($item -is [string]) {
            $item = Get-Channel -Name $item
        }
        return $item
    }
}

class MachineTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $result = @()
        foreach ($item in $InputData) {
            if ($item -is [string] -and $item -like "Machines-*") {
                $item = Get-Machine -ID "$item"
            }
            elseif ($item -is [string]) {
                $item = Get-Machine -Name "$item"
            }
            $result += ($item)
        }
        return ($result)
    }
}

class MachineSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "Machines-*") {
            $item = Get-Machine -ID "$item"
        }
        elseif ($item -is [string]) {
            $item = Get-Machine -Name "$item"
        }
        return ($item)
    }

}

class RunbookTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $result = @()
        foreach ($item in $InputData) {
            if ($item -is [string] -and $item -like "Runbooks-*") {
                $item = Get-Runbook -ID "$item"
            }
            elseif ($item -is [string]) {
                $item = Get-Runbook -Name "$item"
            }
            $result += ($item)
        }
        return ($result)
    }
}

class RunbookSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "Runbooks-*") {
            $item = Get-Runbook -ID "$item"
        }
        elseif ($item -is [string]) {
            $item = Get-Runbook -Name "$item"
        }
        return ($item)
    }

}

class RunbookSnapshotSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "RunbookSnapshots-*") {
            $item = Get-RunbookSnapshot -ID "$item"
        }
        elseif ($item -is [string]) {
            $item = $null
        }
        return ($item)
    }

}

class ArtifactSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "Artifacts-*") {
            $item = Get-Artifact -ID "$item"
        }
        elseif ($item -is [string]) {
            $item = $null
        }
        return ($item)
    }

}

class LibraryVariableSetSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like " LibraryVariableSets-*") {
            $item = Get-VariableSet -id "$item"
        }
        elseif ($item -is [string]) {
            $item = Get-VariableSet -Name "$item"
        }
        return ($item)
    }
}
class ProjectGroupSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "ProjectGroups-*") {
            $item = Get-ProjectGroup -ID "$item"
        }
        elseif ($item -is [string]) {
            $item = Get-ProjectGroup -Name "$item"
        }
        return ($item)
    }

}
class LifecycleSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "Lifecycles-*") {
            $item = Get-Lifecycle -ID "$item"
        }
        elseif ($item -is [string]) {
            $item = Get-Lifecycle -Name "$item"
        }
        return ($item)
    }

}
class ProjectTriggerSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "ProjectTriggers-*") {
            $item = Get-ProjectTrigger -ID "$item"
        }
        elseif ($item -is [string]) {
            $item = Get-ProjectTrigger -Name "$item"
        }
        return ($item)
    }

}
class ProjectTriggerTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $result = @()
        foreach ($item in $InputData) {
            if ($item -is [string] -and $item -like "ProjectTriggers-*") {
                $item = Get-ProjectTrigger -ID "$item"
            }
            elseif ($item -is [string]) {
                $item = Get-ProjectTrigger -Name "$item"
            }
            $result += ($item)
        }
        return ($result)
    }
}
class TaskSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "ServerTasks-*") {
            $item = Get-Task -TaskID "$item"
        }
        elseif ($item -is [string]) {
            $item = $null
        }
        return ($item)
    }
}

class InterventionRegardingStringTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        if ($InputData -is [Octopus.Client.Model.Resource]) {
            return $InputData.id
        }
        if ($InputData -is [string]) {
            # Already an ID string in expected format
            switch ($InputData) {
                { $_ -like "Deployments-*" } {
                    return $InputData
                }
                { $_ -like "Tasks-*" } {
                    return $InputData
                }
                { $_ -like "Projects-*" } {
                    return $InputData
                }
                { $_ -like "Environments-*" } {
                    return $InputData
                }
                { $_ -like "Tenants-*" } {
                    return $InputData
                }
                default { return $null }
            }
        }
        return $null
    }
}