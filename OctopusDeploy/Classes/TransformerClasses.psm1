class ProjectTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $result = @()
        foreach ($item in $InputData) {
            if ($item -is [string] -and $item -like "Projects-*") {
                $item = Get-Project -ID $item
            } elseif ($item -is [string]) {
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
        } elseif ($InputData -is [string]) {
            $item = Get-Project -Name "$InputData"
        } elseif ($InputData -is [Octopus.Client.Model.ProjectResource]) {
            $item = $InputData
        } else {
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
                $item = get-tenant -id "$item"
            } elseif ($item -is [string]) {
                $item = get-tenant -name "$item"
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
            $item = get-tenant -id "$item"
        } elseif ($item -is [string]) {
            $item = get-tenant -name "$item"
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
            } elseif ($item -is [string]) {
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
        } elseif ($item -is [string]) {
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
        } elseif ($item -is [string]) {
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
                $item = Get-Machine -id "$item"
            } elseif ($item -is [string]) {
                $item = Get-Machine -name "$item"
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
            $item = Get-Machine -id "$item"
        } elseif ($item -is [string]) {
            $item = Get-Machine -name "$item"
        }
        return ($item)
    }

}

class RunbookTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $result = @()
        foreach ($item in $InputData) {
            if ($item -is [string] -and $item -like "Runbooks-*") {
                $item = Get-Runbook -id "$item"
            } elseif ($item -is [string]) {
                $item = Get-Runbook -name "$item"
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
            $item = Get-Runbook -id "$item"
        } elseif ($item -is [string]) {
            $item = Get-Runbook -name "$item"
        }
        return ($item)
    }

}

class RunbookSnapshotSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "RunbookSnapshots-*") {
            $item = Get-RunbookSnapshot -id "$item"
        } elseif ($item -is [string]) {
            $item = $null
        }
        return ($item)
    }

}

class ArtifactSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "Artifacts-*") {
            $item = Get-Artifact -id "$item"
        } elseif ($item -is [string]) {
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
        } elseif ($item -is [string]) {
            $item = Get-VariableSet -name "$item"
        }
        return ($item)
    }
}
class ProjectGroupSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "ProjectGroups-*") {
            $item = Get-ProjectGroup -id "$item"
        } elseif ($item -is [string]) {
            $item = Get-ProjectGroup -name "$item"
        }
        return ($item)
    }

}
class LifecycleSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "Lifecycles-*") {
            $item = Get-Lifecycle -id "$item"
        } elseif ($item -is [string]) {
            $item = Get-Lifecycle -name "$item"
        }
        return ($item)
    }

}
class ProjectTriggerSingleTransformation : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        $item = $InputData
        if ($item -is [string] -and $item -like "ProjectTriggers-*") {
            $item = Get-ProjectTrigger -id "$item"
        } elseif ($item -is [string]) {
            $item = Get-ProjectTrigger -name "$item"
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
            } elseif ($item -is [string]) {
                $item = Get-ProjectTrigger -Name "$item"
            }
            $result += ($item)
        }
        return ($result)
    }
}