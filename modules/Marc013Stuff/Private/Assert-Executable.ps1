function Assert-Executable {
    <#
    .SYNOPSIS
        Throw error if the provided executable is not availabel.

    .DESCRIPTION
        Assert-Executable asserts if the provide executable is available.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Full path of the executable that is to be asserted'
        )]
        [string]$Executable
    )

    $ErrorPrefernce = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $AssertExecutable = & $Executable /?
    $ErrorActionPreference = $ErrorPrefernce

    if ([string]::IsNullOrWhiteSpace($AssertExecutable)) {
        throw "`nUnable to find executable '$Executable'. `nPlease make sure the executable is installed."
    }
}