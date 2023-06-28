function New-NuSpec {
    <#
    .SYNOPSIS
        Create NuGet package metadata file for PowerShell module.

    .DESCRIPTION
        New-NuSpec creates a NuGet package metadata file (.nuspec) of a PowerShell module.
        For this the module manifest file (.psd1) is to contain at least the following information.

        - RootModule
        - ModuleVersion
        - Author
        - Description

        Optional module manifest information will be added to the NuGet metadata file when present:

        - PrivateData.PSData.IconUri
        - PrivateData.PSData.ProjectUri
        - PrivateData.PSData.ReleaseNotes
        - PrivateData.PSData.Tags

    .PARAMETER Path
        Path to the module manifest (.psd1)

    .PARAMETER License
        License keyword

    .NOTES
        The blow URL might be helpful in choosing the appropriate license keyword,

        https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository

    .EXAMPLE
        New-NuSpec -Path C./myModule.psd1 -License 'MIT'

        This command will generate a NuGet metadata file based on PowerShell module manifest file myModule.ps1. License will be set to MIT.

        <?xml version="1.0" encoding="utf-8"?>
        <package>
        <metadata>
            <id>myModule</id>
            <version>1.0.0</version>
            <authors>The Author</authors>
            <requireLicenseAcceptance>false</requireLicenseAcceptance>
            <license type="expression">MIT</license>
            <projectUrl>https://github.com/myModules/myModule</projectUrl>
            <description>Great module</description>
            <releaseNotes>Greatness</releaseNotes>
            <copyright>#{year}</copyright>
            <tags>Tag1 Tag2</tags>
            <dependencies>
            <group targetFramework=".NETStandard2.1">
                <dependency id="SampleDependency" version="1.0.0" />
            </group>
            </dependencies>
        </metadata>
        </package>

    .EXAMPLE
        New-NuSpec -Path C./myModule.psd1

        This command will generate a NuGet metadata file based on PowerShell module manifest file myModule.ps1. No license will be set.

        <?xml version="1.0" encoding="utf-8"?>
        <package>
        <metadata>
            <id>myModule</id>
            <version>1.0.0</version>
            <authors>The Author</authors>
            <requireLicenseAcceptance>false</requireLicenseAcceptance>
            <projectUrl>https://github.com/myModules/myModule</projectUrl>
            <description>Great module</description>
            <releaseNotes>Greatness</releaseNotes>
            <copyright>#{year}</copyright>
            <tags>Tag1 Tag2</tags>
            <dependencies>
            <group targetFramework=".NETStandard2.1">
                <dependency id="SampleDependency" version="1.0.0" />
            </group>
            </dependencies>
        </metadata>
        </package>
    #>
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Path to the module manifest (.psd1)'
        )]
        [ValidateScript(
            {
                if (Test-Path -Path $PSItem) {
                    $true
                }
                else {
                    throw "Provided path '$PSItem' is not valid!"
                }
            }
        )]
        [System.IO.FileInfo]$Path,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'License keyword'
        )]
        [string]$License
    )

    $moduleManifest = Test-ModuleManifest -Path $Path -ErrorAction Stop
    $requireLicenseAcceptance = $moduleManifest.PrivateData.PSData.RequireLicenseAcceptance.ToString().ToLower()

    $outputPath = "$($Path.DirectoryName)/$($moduleManifest.Name).nuspec"

    $xmlSettings = New-Object System.Xml.XmlWriterSettings
    $xmlSettings.Indent = $true

    $xmlWriter = [System.XML.XmlWriter]::Create($outputPath, $xmlSettings)
    $xmlWriter.WriteStartElement('package')
    $xmlWriter.WriteStartElement('metadata')
    $xmlWriter.WriteElementString('id', $moduleManifest.Name)
    $xmlWriter.WriteElementString('version', $moduleManifest.Version)
    $xmlWriter.WriteElementString('authors', $moduleManifest.Author)

    if ($requireLicenseAcceptance) {
        $xmlWriter.WriteElementString('requireLicenseAcceptance', $requireLicenseAcceptance)
    }

    if ($license) {
        $xmlWriter.WriteStartElement('license')
        $xmlWriter.WriteAttributeString('type', 'expression')
        $xmlWriter.WriteString($License)
        $xmlWriter.WriteEndElement()
    }

    if ($moduleManifest.PrivateData.PSData.IconUri) {
        $xmlWriter.WriteElementString('icon', $moduleManifest.PrivateData.PSData.IconUri)
    }

    if ($moduleManifest.ProjectUri.AbsoluteUri) {
        $xmlWriter.WriteElementString('projectUrl', $moduleManifest.ProjectUri.AbsoluteUri)
    }

    $xmlWriter.WriteElementString('description', $moduleManifest.Description)

    if ($moduleManifest.ReleaseNotes) {
        $xmlWriter.WriteElementString('releaseNotes', $moduleManifest.ReleaseNotes)
    }

    $xmlWriter.WriteElementString('copyright', '#{year}')

    if ($moduleManifest.Tags) {
        $xmlWriter.WriteElementString('tags', $($moduleManifest.PrivateData.PSData.Tags -join ' '))
    }

    $xmlWriter.WriteStartElement('dependencies')
    $xmlWriter.WriteStartElement('group')
    $xmlWriter.WriteAttributeString('targetFramework', '.NETStandard2.1')
    $xmlWriter.WriteStartElement('dependency')
    $xmlWriter.WriteAttributeString('id', 'SampleDependency')
    $xmlWriter.WriteAttributeString('version', '1.0.0')
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndElement()

    $xmlWriter.Flush()
    $xmlWriter.Close()
}

