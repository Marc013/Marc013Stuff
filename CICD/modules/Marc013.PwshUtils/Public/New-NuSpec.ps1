function New-NuSpec {
    <#
    .SYNOPSIS
        A short one-line action-based description, e.g. 'Tests if a function is valid'
    .DESCRIPTION
        A longer description of the function, its purpose, common use cases, etc.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
    [CmdletBinding()]
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
        [System.IO.FileInfo]$Path
    )

    $moduleManifest = Test-ModuleManifest -Path $Path -ErrorAction Stop

    $outputPath = "$($path.DirectoryName)/$($moduleManifest.Name).test.nuspec"
    $requireLicense = $false
    $license = 'MIT'
    $url = 'https://github.com/Marc013/Marc013Stuff'
    # $releaseNotes = 'See the project for changes'
    $tags = 'PowerShell', 'UnitTesting'

    $xmlSettings = New-Object System.Xml.XmlWriterSettings
    $xmlSettings.Indent = $true

    $xmlWriter = [System.XML.XmlWriter]::Create($outputPath, $xmlSettings)
    $xmlWriter.WriteStartElement('package')
    $xmlWriter.WriteStartElement('metadata')
    $xmlWriter.WriteElementString('id', $($moduleManifest.Name))
    $xmlWriter.WriteElementString('version', $($moduleManifest.Version))
    $xmlWriter.WriteElementString('authors', $($moduleManifest.Author))
    $xmlWriter.WriteElementString('requireLicenseAcceptance', $requireLicense.ToString().ToLower())
    $xmlWriter.WriteStartElement('license')
    $xmlWriter.WriteAttributeString('type', 'expression')
    $xmlWriter.WriteString($license)
    $xmlWriter.WriteEndElement()
    # $xmlWriter.WriteElementString('icon', 'noClue')
    $xmlWriter.WriteElementString('projectUrl', $url)
    $xmlWriter.WriteElementString('description', $($moduleManifest.Description))
    # $xmlWriter.WriteElementString('releaseNotes', $releaseNotes)
    $xmlWriter.WriteElementString('copyright', '#{year}')
    $xmlWriter.WriteElementString('tags', $($tags -join ' '))
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

