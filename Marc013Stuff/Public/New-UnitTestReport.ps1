function New-UnitTestReport {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .EXAMPLE
    $Param = @{
        Path                = 'C:\git\FancyStuff\tests'
        ScriptPath          = 'C:\git\FancyStuff\modules\LazyGuy\private\*.ps1', 'C:\git\FancyStuff\modules\LazyGuy\public\*.ps1'
        ReportUnitPath      = 'C:\ReportUnit\ReportUnit.exe'
        ReportGeneratorPath = 'C:\ReportGenerator\ReportGenerator.exe'
        ReportType          = 'HtmlInline_AzurePipelines', 'HtmlInline_AzurePipelines_Dark'
        ReportTitle         = 'Nice Stuff!!'
        ShowReport          = $true
    }
    New-UnitTestReport @Param

    This command will generate an HTML NUnit unit test report and an HTML inline Azure pipelines code coverage report.
    Using paramter ReportUnitPath and ReportGeneratorPath you have specified the directory location of the respective executables.

    .EXAMPLE
    $Param = @{
        Path        = 'C:\git\FancyStuff\tests'
        ScriptPath  = 'C:\git\FancyStuff\modules\LazyGuy\private\*.ps1'
        ReportType  = 'HtmlInline_AzurePipelines'
        ReportTitle = 'Nice Stuff!!'
        ShowReport  = $true
    }
    New-UnitTestReport @Param

    This command will generate an HTML NUnit unit test report and an HTML inline Azure pipelines code coverage report.
    The directory location(s) of the 'ReportUnit' executable and 'ReportGenerator' executable must be added to your system path!
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
            Mandatory = $false,
            HelpMessage = 'Full path of ReportUnit.exe. (e.g. "C:\ReportUnit\ReportUnit.exe")')]
        [string]$ReportUnitPath = 'ReportUnit',
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Full path of ReportGenerator.exe. (e.g. "C:\ReportGenerator\ReportGenerator.exe")')]
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

    # Run Pester test

    ### ToDo: Specify report output directory path. Create path if not exist including dir for test results and code coverage
    ### E.g. c:\testResults\unitTest\ & c:\testResults\codeCoverage\

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

        # Generating unit tests report
        & $ReportUnitPath $TestResultOutputPath | Out-String | Out-Null ### ToDo: Add report destinatino path

        # Generating code coverage report
        if ($ReportType.ToLower().Contains('htmlinline_azurepipelines') -and $ReportType.ToLower().Contains('htmlinline_azurepipelines_dark')) {
            [System.Collections.ArrayList]$ReportType = $ReportType
            Write-Warning "You specified report type 'HtmlInline_AzurePipelines' and 'HtmlInline_AzurePipelines_Dark'. `nOnly one of these report types can be created at one time. `nRemoving report type 'HtmlInline_AzurePipelines_Dark'`n"
            $ReportType.Remove('HtmlInline_AzurePipelines_Dark')
        }

        [string]$CoverageReportDir = 'coveragereport'
        [string]$ReportType = Join-String -InputObject $ReportType -Separator ';'
        [string]$SourceDirs = $ScriptPath.TrimEnd('*.ps1') | Join-String -Separator ';'

        $CodeCoverageResult = & $ReportGeneratorPath -reports:$CodeCoverageOutputPath -targetdir:$CoverageReportDir -sourcedirs:$SourceDirs -reporttypes:$ReportType -title:$ReportTitle | Out-String
        # $Result

        if ($ShowReport.IsPresent) {
            $DirSeparator = [IO.Path]::DirectorySeparatorChar

            #&

            foreach ($Entry in $CodeCoverageResult.Split(':')) {
                if ($Entry -match 'Writing report file') {
                    [string]$Report = $Entry.Split("'")[1].Split("$DirSeparator")[-1]
                    Write-Host "Opening Report '$CoverageReportDir$DirSeparator$Report'" -ForegroundColor Magenta

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
