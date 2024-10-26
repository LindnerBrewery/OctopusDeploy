class Repository {
    # class properties
    hidden [Octopus.Client.OctopusRepository]$_repository
    hidden [Octopus.Client.OctopusServerEndpoint]$_endpoint
    hidden [Octopus.Client.Model.LoginCommand]$_loginObj
    hidden [Octopus.Client.OctopusClient]$_client
    hidden [securestring]$_apiKey
    [String]$OctopusServerURL
    [String]$User
    [String]$Space

    # class contructors
    Repository([String]$OctopusServerURL, [SecureString]$ApiKey) {
        # under Linux converting secure string is different than under Windows. This will work under both OS
        # https://github.com/dotnet/runtime/issues/35632
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
        $UnsecureapiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
        $this._endpoint = [Octopus.Client.OctopusServerEndpoint]::new($OctopusServerURL, $UnsecureapiKey)
        $this._repository = [Octopus.Client.OctopusRepository]::new($this._endpoint)
        $this._client = [Octopus.Client.OctopusClient]::new($this._endpoint)
        $this._apiKey = $apiKey
        $this.SetVariables()
    }
    Repository([String]$OctopusServerURL, [String]$ApiKeyPlain) {
        $this._endpoint = [Octopus.Client.OctopusServerEndpoint]::new($OctopusServerURL, $ApiKeyPlain)
        $this._repository = [Octopus.Client.OctopusRepository]::new($this._endpoint)
        $this._client = [Octopus.Client.OctopusClient]::new($this._endpoint)
        $this._apiKey = $ApiKeyPlain | ConvertTo-SecureString -AsPlainText -Force
        $this.SetVariables()

    }
    # class methods
    [void]SetSpace([String]$SpaceID) {
        $spaceobj = $this._repository.Spaces.get($SpaceID)
        $this.space = $spaceobj.name
        $this._repository = $this._repository.client.ForSpace($spaceobj)
    }
    # internal methods
    hidden [void]SetVariables() {
        $this.OctopusServerURL = $this._endpoint.OctopusServer
        $this.User = $this._repository.Users.GetCurrent().username
        $spaceLink = $this._repository.LoadSpaceRootDocument().links.self
        if ($spaceLink) {
            $spaceID = Split-Path $spaceLink -Leaf
            $this.space = $this._repository.Spaces.Get($spaceID).name
        }
    }
}

class TaskResult {
    [String]$Step
    [String]$Name
    [String]$Status
    [System.object[]]$Message
    [String]$_hiddenMessage
    # class contructors
    TaskResult([String]$Step, [String]$Name, [String]$Status, [System.object[]]$Message) {
        $this.Step = $Step
        $this.Name = $Name
        $this.Status = $Status
        $this.Message = $Message
        $this._hiddenMessage = $Message -join "`n"
    }
}

class ProjectDeploymentObject {
    [String]$Project
    [String]$Tenant
    [String]$Environment
    [String]$Version
    [String]$State
    [Octopus.Client.Model.DashboardItemResource]$Deployment
    # class constructors
    ProjectDeploymentObject([String]$Project, [String]$Tenant, [String]$Environment, [String]$Version, [String]$State , [Octopus.Client.Model.DashboardItemResource]$Deployment) {
        $this.Project = $Project
        $this.Tenant = $Tenant
        $this.Environment = $Environment
        $this.Version = $Version
        $this.State = $State
        $this.Deployment = $Deployment
    }
}


class VariableSetVar {
    [String]$Name
    [String]$Value
    [String]$Scope
    [String]$Prompt
    [String]$ID

    # class contructors
    VariableSetVar( [Octopus.Client.Model.VariableResource]$Variable) {
        $this.Name = $Variable.name
        $this.Value = if ($Variable.IsSensitive) { "*****" } else { $Variable.value };
        $this.Scope = if ($Variable.scope.count -ne 0) { $Variable.scope };
        $this.Prompt = if ($Variable.prompt) { $true };
        $this.ID = $Variable.Id;
    }
}

