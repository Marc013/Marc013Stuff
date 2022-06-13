function Remove-NTFSPermission {
    <#
    .SYNOPSIS
        Remove NTFS permission of directory or file.

    .DESCRIPTION
        Remove-NTFSPermission removes the specified user from the defined directory or file.
        Only a user account that has a permission configured is removed.

    .PARAMETER Target
        Full path to directory or file (e.g. c:\temp\test.txt)

    .PARAMETER User
        Azure AD user (e.g. AzureAD\Marc013)

    .EXAMPLE
        $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Remove-NTFSPermission -Target C:\Temp\Test\test.md -User $User

        This command will remove the current logged in user from the the specified file

    .EXAMPLE
        Remove-NTFSPermission -Target C:\Temp\Test\test.md -User DoesNotExist

        This command will produce a warning message as the specified user does not have any permission defined on the specified file
    #>
    #Requires -Version 7
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Full path to directory or file (e.g. c:\temp\test.txt)'
        )]
        [string]$Target,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Azure AD user (e.g. AzureAD\Marc013)'
        )]
        [string]$User
    )

    if ($IsWindows) {
        $acl = Get-Acl -Path $Target -ErrorAction Stop

        $userId = New-Object System.Security.Principal.Ntaccount ($User) -ErrorAction Stop

        if ($acl.Access.IdentityReference.Value -contains $userId.Value) {
            $acl.PurgeAccessRules($userId)

            $acl | Set-Acl -Path $target -Passthru -ErrorAction Stop
        }
        else {
            Write-Warning "No permissions found for user '$User'"
        }
    }
    else {
        throw 'This function can only be run on a Windows system!'
    }
}
