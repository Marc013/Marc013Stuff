#
# Module manifest for module 'Marc013Stuff'
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'Marc013Stuff.psm1'

    # Version number of this module.
    ModuleVersion     = '0.5.1'

    # ID used to uniquely identify this module
    GUID              = 'ca188666-a48a-4cd7-81e4-5a126044f086'

    # Author of this module
    Author            = 'Marc van Gorp'

    # Company or vendor of this module
    CompanyName       = 'Marc van Gorp'

    # Copyright statement for this module
    Copyright         = '(c) 2022 Marc013. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'All kinds of miscellaneous goodies'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Add-NTFSPermission',
        'New-CodeCoverageReport',
        'Remove-NTFSPermission',
        'Set-DirectoryStructure'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()
}
