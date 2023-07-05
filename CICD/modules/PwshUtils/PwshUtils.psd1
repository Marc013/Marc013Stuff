@{
    # Script module or binary module file associated with this manifest.
    RootModule           = 'PwshUtils.psm1'

    # Version number of this module.
    ModuleVersion        = '0.1.0'

    # Supported PSEditions
    CompatiblePSEditions = 'Core'

    # ID used to uniquely identify this module
    GUID                 = 'bc0ab5fc-f4b4-4cd8-9bc1-9b9ac60fbb5e'

    # Author of this module
    Author               = 'Marc van Gorp'

    # Company or vendor of this module
    CompanyName          = 'Marc013'

    # Copyright statement for this module
    Copyright            = '(c) 2023 Marc013. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Generic PowerShell tools'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '7.3'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags                     = @(
                'Pester',
                'UnitTest'
            )

            # A URL to the license for this module.
            LicenseUri               = 'https://raw.githubusercontent.com/Marc013/Marc013Stuff/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri               = 'https://github.com/Marc013/Marc013Stuff'

            # A URL to an icon representing this module.
            # IconUri                  = ''

            # ReleaseNotes of this module
            ReleaseNotes             = 'Building something nice'

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
