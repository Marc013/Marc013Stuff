function New-UnitTestReport {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .EXAMPLE

    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Directories to be searched for tests, paths directly to test files, or combination of both.')]
        [string]$Path,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Directorie where the scripts are located for code coverage.')]
        [array]$ScriptPath,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Full path of ReportGenerator.exe. (e.g. "C:\ReportGenerator\ReportGenerator.exe")')]
        [array]$ReportGeneratorPath,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Code coverage output format and scope.')]
        [ValidateSet('Badges', 'Clover', 'Cobertura', 'CsvSummary', 'Html', 'HtmlChart',
            'HtmlInline', 'HtmlInline_AzurePipelines', 'HtmlInline_AzurePipelines_Dark',
            'HtmlSummary', 'JsonSummary', 'Latex', 'LatexSummary', 'lcov', 'MHtml',
            'PngChart', 'SonarQube', 'TeamCitySummary', 'TextSummary', 'Xml', 'XmlSummary')]
        [System.Collections.ArrayList]$ReportType = 'Html',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Title of the code coverage report.')]
        [string]$ReportTitle = 'Code Coverage',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Open HTML report.')]
        [switch]$ShowReport
    )
    #Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.2.2' }

    $ErrorPrefernce = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $AssertReportGenerator = & $ReportGeneratorPath /?
    $ErrorActionPreference = $ErrorPrefernce

    if ([string]::IsNullOrWhiteSpace($AssertReportGenerator)) {
        throw "`nUnable to find ReportGenerator.exe. `nPlease make sure ReportGenerator.exe is installed. `nhttps://danielpalme.github.io/ReportGenerator/"
    }

    # Create code coverage JaCoCo XML report
    # Import-Module -Name Pester

    $CodeCoverageOutputPath = "$Path/coverage.xml"
    $TestResultOutputPath = "$Path/testResults.xml"

    $configuration = New-PesterConfiguration
    $configuration.Run.Path = $Path
    $configuration.Run.Exit = $true
    $configuration.Should.ErrorAction = 'Continue'
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.OutputFormat = 'JaCoCo'
    $configuration.CodeCoverage.OutputPath = $CodeCoverageOutputPath
    $configuration.CodeCoverage.Path = $ScriptPath
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputFormat = 'NUnitXml'
    $configuration.TestResult.OutputPath = $TestResultOutputPath
    $configuration.Output.Verbosity = 'Detailed'

    try {
        Invoke-Pester -Configuration $configuration

        # Generating code coverage report
        if ($ReportType.Contains('HtmlInline_AzurePipelines') -and $ReportType.Contains('HtmlInline_AzurePipelines_Dark')) {
            Write-Warning "You specified report type 'HtmlInline_AzurePipelines' and 'HtmlInline_AzurePipelines_Dark'. `nOnly one of these report types can be created at one time. `nRemoving report type 'HtmlInline_AzurePipelines_Dark'`n"
            $ReportType.Remove('HtmlInline_AzurePipelines_Dark')
        }

        [string]$CoverageReportDir = 'coveragereport'
        [string]$ReportType = Join-String -InputObject $ReportType -Separator ';'
        [string]$SourceDirs = $ScriptPath.TrimEnd('*.ps1') | Join-String -Separator ';'

        $Result = & $ReportGeneratorPath -reports:$CodeCoverageOutputPath -targetdir:$CoverageReportDir -sourcedirs:$SourceDirs -reporttypes:$ReportType -title:$ReportTitle | Out-String
        # $Result

        if ($ShowReport.IsPresent) {
            $DirSeparator = [IO.Path]::DirectorySeparatorChar
            foreach ($Entry in $Result.Split(':')) {
                if ($Entry -match 'Writing report file') {
                    [string]$Report = $Entry.Split("'")[1].Split("$DirSeparator")[-1]
                    Write-Host "Operning Report '$CoverageReportDir$DirSeparator$Report'" -ForegroundColor Magenta

                    & $CoverageReportDir$DirSeparator$Report
                }
            }
        }
    }
    finally {
        Remove-Item -LiteralPath $CodeCoverageOutputPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $TestResultOutputPath -Force -ErrorAction SilentlyContinue
    }
}
