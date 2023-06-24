function Assert-HelperFunction {
    <#
    .SYNOPSIS
        Throw error if a helper function is not availabel.

    .DESCRIPTION
        Assert-HelperFunction asserts if the helper function is available during execution.
    #>
    [string]$ModuleName = 'Marc013Stuff'
    [string[]]$FunctionNames = 'Assert-Executable'

    $Module = if ($null -ne $ExecutionContext.SessionState.Module -and $ModuleName -eq $ExecutionContext.SessionState.Module.Name) {
        $ExecutionContext.SessionState.Module
    }
    else {
        Get-Module -Name $ModuleName -All
    }

    if ([string]::IsNullOrWhiteSpace($Module)) {
        throw "Missing module '$ModuleName'"
    }

    $ModuleFunctions = $Module.Invoke( { Get-Command -Module $ModuleName } )

    foreach ($FunctionName in $FunctionNames) {
        $Dependency = $ModuleFunctions | Where-Object -Property Name -EQ $FunctionName

        if ([string]::IsNullOrWhiteSpace($Dependency)) {
            [string[]]$MissingFunction += $FunctionName
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($MissingFunction)) {
        throw "Missing dependent private function '$($MissingFunction -join ' & ')'"
    }
}
