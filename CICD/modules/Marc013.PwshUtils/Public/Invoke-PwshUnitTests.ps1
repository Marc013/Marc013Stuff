function Invoke-PwshUnitTests {
    <#
    .SYNOPSIS
        Run PowerShell Pester unit tests.

    .DESCRIPTION
        Invoke-PwshUnitTests runs any PowerShell Pester unit test located in the provided path.
        The test results and code coverage will be stored in the provided output directory in the tests path.

    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
    #Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.4.1' }
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([Hashtable])]
    param (
        [Parameter(
            HelpMessage = 'Provide the path of the Pester tests directory or files',
            Mandatory = $true
        )]
        [ValidateScript(
            {
                if (Test-Path -LiteralPath $PSItem) {
                    $true
                }
                else {
                    throw "'$PSItem' is not a valid path!"
                }
            }
        )]
        [System.IO.DirectoryInfo[]]$Path,
        [Parameter(
            HelpMessage = 'Provide the directory name where the Pester test results are to be placed',
            Mandatory = $true
        )]
        [String]$OutputDirectory
    )
    Set-Variable -Name ErrorActionPreference -Value Stop

    if (Test-Path -Path $Path[0] -PathType Container) {
        $isContainer = $true
        $testsFiles = Get-ChildItem -Path $Path -Filter *.tests.ps1 -Recurse -Depth 4 -File
    }
    else {
        $isContainer = $false
        [System.IO.FileInfo[]]$testsFiles = $Path.FullName
    }

    if ($testsFiles.Count -le 0) {
        throw "No PowerShell tests files found at '$Path'"
    }

    $pwshModulePath = $testsFiles[0].DirectoryName.Replace('tests', 'modules').Replace('Private', '').Replace('Public', '')

    $codeCoveragePath = [System.Collections.ArrayList]::new()

    if ($isContainer) {
        [Void]$codeCoveragePath.Add("$pwshModulePath/*.ps*1")
        [Void]$codeCoveragePath.Add("$pwshModulePath/**/*.ps*1")
    }
    else {
        $testsFiles | ForEach-Object -Process {
            $testsFile = $PSItem.FullName.Replace('.tests.ps1', '.ps1').Replace('tests', 'modules')
            [Void]$codeCoveragePath.Add($testsFile)
        }
    }

    [System.IO.DirectoryInfo]$OutputPath = "$pwshModulePath/$OutputDirectory"

    if (-not ($OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    $Configuration = New-PesterConfiguration
    $Configuration.Run.Path = $Path.FullName
    $Configuration.CodeCoverage.Enabled = $true
    $Configuration.CodeCoverage.OutputPath = "$OutputPath/CoveragePester.xml"
    $Configuration.CodeCoverage.Path = $codeCoveragePath
    $Configuration.TestResult.Enabled = $true
    $Configuration.TestResult.OutputFormat = 'NUnitXml'
    $Configuration.TestResult.OutputPath = "$OutputPath/ResultsPester.xml"
    $Configuration.TestResult.TestSuiteName = 'GOAT unit testing results'
    $Configuration.Should.ErrorAction = 'Continue'
    $Configuration.Output.Verbosity = 'Detailed'

    Write-Verbose "Pester config: $($Configuration | ConvertTo-Json -Depth 100)"

    Invoke-Pester -Configuration $Configuration

    [ordered]@{
        CodeCoverageReport = "$OutputPath/CoveragePester.xml"
        UnitTestsReport    = "$OutputPath/ResultsPester.xml"
    }
}
