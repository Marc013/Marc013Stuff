function Add-NTFSPermission {
    <#
    .SYNOPSIS
        Add NTFS permission to directory or file.

    .DESCRIPTION
        Add-NTFSPermission adds the specified permission to the provided directory or file.
        The permission can either be allowed or denied.

    .PARAMETER Target
        Full path to directory or file (e.g. c:\temp\test.txt)

    .PARAMETER User
        Azure AD user (e.g. AzureAD\Marc013)

    .PARAMETER Permission
        NTFS right (e.g. Modify)

    .PARAMETER Control
        Access control type (Allow or Deny)

    .EXAMPLE
        $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Add-NTFSPermission -Target C:\myFile.txt -User $User -Permission Modify -Control Allow

        This command grants the current user Modify permission on the specified file
    #>
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
        [string]$User,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'NTFS right (e.g. Modify)'
        )]
        [ValidateSet(
            'Delete',
            'FullControl',
            'Modify',
            'Read',
            'Write'
        )]
        [string]$Permission,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Access control type (Allow or Deny)'
        )]
        [ValidateSet(
            'Allow',
            'Deny'
        )]
        [string]$Control
    )

    if ($IsWindows) {
        $acl = Get-Acl -Path $Target -ErrorAction Stop

        [hashtable]$objectParameters = @{
            TypeName     = 'System.Security.AccessControl.FileSystemAccessRule'
            ArgumentList = $User, $Permission, $Control
            ErrorAction  = 'Stop'
        }
        $accessRule = New-Object @objectParameters

        $acl.SetAccessRule($accessRule)

        $acl | Set-Acl -Path $Target -Passthru -ErrorAction Stop
    }
    else {
        throw 'This function can only be run on a Windows system!'
    }
}
