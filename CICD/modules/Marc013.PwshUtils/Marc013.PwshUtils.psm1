#requires -Modules Microsoft.PowerShell.Utility

$Public = @(Get-ChildItem -Path $PSScriptRoot/Public/*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot/Private/*.ps1 -ErrorAction SilentlyContinue)

foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error -Message "Failed to import $($import.fullname): $PSItem"
    }
}

Export-ModuleMember -Function $Public.BaseName
