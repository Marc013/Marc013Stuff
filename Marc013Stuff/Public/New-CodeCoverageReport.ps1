function New-CodeCoverageReport {
    <#
    .SYNOPSIS
    Create PowerShell Pester code coverage report.

    .DESCRIPTION
    New-CodeCoverageReport creates a code coverage report using PowerShell Pester and ReportGenerator.

    .PARAMETER TestsPath
    Directories to be searched for tests, paths directly to test files, or combination of both.

    .PARAMETER ScriptPath
    Directory where the scripts are located for code coverage.

    .PARAMETER ReportGeneratorPath
    Full path of executable ReportGenerator.exe. (e.g. "C:\ReportGenerator\ReportGenerator.exe")

    .PARAMETER ReportType
    Code coverage output format and scope.

    .PARAMETER ReportTitle
    Title of the code coverage report.

    .PARAMETER ShowReport
    Define this switch to show the report.

    .EXAMPLE
    New-CodeCoverageReport -TestsPath C:\git\FancyStuff\tests -ScriptPath C:\git\FancyStuff\modules\LazyGuy\public\*.ps1

    This command will generate a HTML code coverage report in the directory provided in parameter TestsPath.

    The directory path of the 'ReportGenerator' executable must be present in the system path!

    .EXAMPLE
    $Param = @{
        TestsPath           = 'C:\git\FancyStuff\tests'
        ScriptPath          = 'C:\git\FancyStuff\modules\LazyGuy\private\*.ps1', 'C:\git\FancyStuff\modules\LazyGuy\public\*.ps1'
        ReportGeneratorPath = 'C:\ReportGenerator\ReportGenerator.exe'
        ReportType          = 'HtmlInline_AzurePipelines', 'HtmlInline_AzurePipelines_Dark'
        ReportTitle         = 'Nice Stuff!!'
        ShowReport          = $true
    }
    New-CodeCoverageReport @Param

    This command will generate a HTML inline Azure pipelines code coverage report and show it.
    Providing both inline Azure report types is not functional. A warning will be displayed and the dark report removed.

    Using parameter ReportGeneratorPath you have specified the directory location of the respective executables.

    .EXAMPLE
    $Param = @{
        TestsPath   = 'C:\git\FancyStuff\tests'
        ScriptPath  = 'C:\git\FancyStuff\modules\LazyGuy\private\*.ps1'
        ReportType  = 'HtmlInline_AzurePipelines'
        ReportTitle = 'Nice Stuff!!'
        ShowReport  = $true
    }
    New-CodeCoverageReport @Param

    This command will generate a HTML inline Azure pipelines code coverage report and show it.

    The directory path of the 'ReportGenerator' executable must be present in the system path!

    .LINK
    ReportGenerator
    https://danielpalme.github.io/ReportGenerator
    https://www.palmmedia.de/OpenSource/ReportGenerator
    #>
    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Directories to be searched for tests, paths directly to test files, or combination of both.')]
        [string]$TestsPath,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Directory where the scripts are located for code coverage.')]
        [array]$ScriptPath,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Full path of executable ReportGenerator.exe. (e.g. "C:\ReportGenerator\ReportGenerator.exe")')]
        [string]$ReportGeneratorPath = 'ReportGenerator',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Code coverage output format and scope.')]
        [ValidateSet('Badges', 'Clover', 'Cobertura', 'CsvSummary', 'Html', 'HtmlChart',
            'HtmlInline', 'HtmlInline_AzurePipelines', 'HtmlInline_AzurePipelines_Dark',
            'HtmlSummary', 'JsonSummary', 'Latex', 'LatexSummary', 'lcov', 'MHtml',
            'PngChart', 'SonarQube', 'TeamCitySummary', 'TextSummary', 'Xml', 'XmlSummary')]
        [string[]]$ReportType = 'Html',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Title of the code coverage report.')]
        [string]$ReportTitle = 'Code Coverage',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Define this switch to show the report.')]
        [switch]$ShowReport
    )
    #Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.3.0' }

    Assert-HelperFunction

    Assert-Executable -Executable $ReportGeneratorPath

    [char]$DirSeparator = [IO.Path]::DirectorySeparatorChar
    [string]$Ticks = $(Get-Date).Ticks

    if ($TestsPath -match '.ps1') {
        $TestFilePath = [System.IO.DirectoryInfo]$TestsPath
        $BaseTestPath = $TestsPath.Replace($("$DirSeparator$($TestFilePath.BaseName)"), '')
        [string]$ReportPath = "$BaseTestPath$($DirSeparator)report"
    }
    else {
        [string]$ReportPath = "$TestsPath$($DirSeparator)report"
    }

    [string]$CodeCoverageBasePath = "$ReportPath$($DirSeparator)codeCoverage$DirSeparator"
    [string]$CodeCoverageOutputPath = "$($CodeCoverageBasePath)coverage$Ticks.xml"
    [string]$CodeCoverageHistoryPath = "$ReportPath$($DirSeparator)codeCoverageHistory"
    [string]$TestResultBasePath = "$ReportPath$($DirSeparator)unitTest$DirSeparator"
    [string]$TestResultOutputPath = "$($TestResultBasePath)testResults$Ticks.xml"

    New-Item -Path $TestsPath -Name report -ItemType Directory -Force | Out-Null
    New-Item -Path $CodeCoverageBasePath -ItemType Directory -Force | Out-Null
    New-Item -Path $TestResultBasePath -ItemType Directory -Force | Out-Null

    $Configuration = New-PesterConfiguration
    $Configuration.Run.Path = $TestsPath
    $Configuration.CodeCoverage.Enabled = $true
    $Configuration.CodeCoverage.OutputPath = $CodeCoverageOutputPath
    $Configuration.CodeCoverage.Path = $ScriptPath
    $Configuration.TestResult.Enabled = $true
    $Configuration.TestResult.OutputFormat = 'NUnitXml'
    $Configuration.TestResult.OutputPath = $TestResultOutputPath
    $Configuration.TestResult.TestSuiteName = $ReportTitle
    $Configuration.Should.ErrorAction = 'Continue'
    $Configuration.Output.Verbosity = 'Detailed'

    Invoke-Pester -Configuration $Configuration

    if ($ReportType.ToLower() -match '^htmlinline_azurepipelines$' -and $ReportType.ToLower() -match '^htmlinline_azurepipelines_dark$') {
        [System.Collections.ArrayList]$ReportType = $ReportType
        Write-Warning "You specified report type 'HtmlInline_AzurePipelines' and 'HtmlInline_AzurePipelines_Dark'. `nOnly one of these report types can be created at one time. `nRemoving report type 'HtmlInline_AzurePipelines_Dark'`n"
        $ReportType.Remove('HtmlInline_AzurePipelines_Dark')
    }

    [string]$ReportType = Join-String -InputObject $ReportType -Separator ';'

    foreach ($Path in $ScriptPath) {
        if ($Path -match '.ps1') {
            [array]$Dirs += $Path.Replace((([System.IO.DirectoryInfo]$Path).BaseName), '')
        }
        else {
            [array]$Dirs += $Path
        }
    }
    [string]$SourceDirs = Join-String -Separator ';' -InputObject $Dirs

    Write-Host 'Generating code coverage report'
    $CodeCoverageResult = & $ReportGeneratorPath -reports:$CodeCoverageOutputPath -targetdir:$CodeCoverageBasePath -sourcedirs:$SourceDirs -historydir:$CodeCoverageHistoryPath -reporttypes:$ReportType -title:$ReportTitle | Out-String

    if ($ShowReport.IsPresent) {
        foreach ($Entry in $CodeCoverageResult.Split(': ')) {
            if ($Entry -match 'Writing report file') {
                [string]$Report = $Entry.Split("'")[1].Split("$DirSeparator")[-1]
                [string]$ReportFullPath = "$CodeCoverageBasePath$Report"

                Write-Host "`nOpening Report '$ReportFullPath"

                & $ReportFullPath
            }
        }
    }
}
