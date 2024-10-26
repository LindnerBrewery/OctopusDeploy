function Get-CustomError {
    <#
.SYNOPSIS
    Returns a custom error record
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
    [CmdletBinding(DefaultParameterSetName = 'default',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'low')]
    [Alias('gce')]
    #[OutputType([String])]
    Param (
        # Error message
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'default')]
 
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,
        
        # Error category
        [Parameter(ParameterSetName = 'default')]
        [Management.Automation.ErrorCategory]
        $Category = 'WriteError',
        
        # exception
        [Parameter(ParameterSetName = 'default')]
        [string]
        $Exception = 'Microsoft.PowerShell.Commands.WriteErrorException',
        
        # error id
        [Parameter(ParameterSetName = 'default')]
        [string]
        $ErrorID = "Microsoft.PowerShell.Commands.WriteErrorException",

        # target object
        [Parameter(ParameterSetName = 'default')]
        [System.Object]
        $TargetObject = ''
    )
    
    begin {}
    process {
        $exceptionObject = New-Object -TypeName $Exception -ArgumentList $message
        [System.Management.Automation.ErrorRecord]::new($exceptionObject, $errorID, $Category, $TargetObject)
    }
    end {}
}
Register-ArgumentCompleter -CommandName Get-CustomError -ParameterName Exception -ScriptBlock {
    param($commandName, $parameterName, $stringMatch)
    $stringMatch = $stringMatch.trim("'") # remove ' from search string if there was an space in the word
    ([appdomain]::CurrentDomain.GetAssemblies() | ForEach-Object {
        Try {
            $_.GetExportedTypes() | Where-Object {
                $_.Fullname -like '*Exception'
            }
        }
        Catch {}
    }) | Where-Object Fullname -Like *$stringMatch* | Sort-Object -Property fullname | Select-Object -ExpandProperty fullname
}

