function New-UnitTestReport {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .EXAMPLE
    New-UnitTestReport -TestsPath C:\git\FancyStuff\tests -ScriptPath C:\git\FancyStuff\modules\LazyGuy\public\*.ps1

    This command will generate a HTML unit test report and HTML code coverage report in the directory provided in parameter TestsPath.

    .EXAMPLE
    $Param = @{
        TestsPath           = 'C:\git\FancyStuff\tests'
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
        TestsPath   = 'C:\git\FancyStuff\tests'
        ScriptPath  = 'C:\git\FancyStuff\modules\LazyGuy\private\*.ps1'
        ReportType  = 'HtmlInline_AzurePipelines'
        ReportTitle = 'Nice Stuff!!'
        ShowReport  = $true
    }
    New-UnitTestReport @Param

    This command will generate an HTML NUnit unit test report and an HTML inline Azure pipelines code coverage report.
    The directory location(s) of the 'ReportUnit' executable and 'ReportGenerator' executable must be added to your system path!

    .LINK
    ReportUnit
    https://www.nuget.org/packages/ReportUnit

    ReportGenerator
    https://danielpalme.github.io/ReportGenerator
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Directories to be searched for tests, paths directly to test files, or combination of both.')]
        [string]$TestsPath,
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
    #Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.3.0' }

    Assert-HelperFunction

    Assert-Executable -Executable $ReportUnitPath
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

    # Write-Host "Configuration.TestResult.TestSuiteName = '$($Configuration.TestResult.TestSuiteName)'" -ForegroundColor Black -BackgroundColor Yellow

    try {
        Invoke-Pester -Configuration $Configuration

        # Generating unit tests report
        & $ReportUnitPath $TestResultOutputPath | Out-Null

        # TESTING extentreports-dotnet-cli which deprecates ReportUnit
        # https://github.com/extent-framework/extentreports-dotnet-cli
        Write-Host 'TESTING extentreports-dotnet-cli'
        Write-Host "TestResultOutputPath = '$TestResultOutputPath'"
        Write-Host "TestResultBasePath = '$TestResultBasePath'"
        extent -d $TestResultBasePath -o $TestResultBasePath --merge

        # Generating code coverage report
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
        # [string]$SourceDirs = $ScriptPath.TrimEnd('*.ps1') | Join-String -Separator ';'
        [string]$SourceDirs = Join-String -Separator ';' -InputObject $Dirs

        Write-Host 'Generating code coverage report'
        $CodeCoverageResult = & $ReportGeneratorPath -reports:$CodeCoverageOutputPath -targetdir:$CodeCoverageBasePath -sourcedirs:$SourceDirs -historydir:$CodeCoverageHistoryPath -reporttypes:$ReportType -title:$ReportTitle | Out-String

        if ($ShowReport.IsPresent) {
            foreach ($Entry in $CodeCoverageResult.Split(': ')) {
                if ($Entry -match 'Writing report file') {
                    [string]$Report = $Entry.Split("'")[1].Split("$DirSeparator")[-1]
                    [string]$ReportFullPath = "$CodeCoverageBasePath$DirSeparator$Report"

                    Write-Host "`nOpening Report '$ReportFullPath"

                    & $ReportFullPath
                }
            }
        }
    }
    finally {
        # Remove-Item -LiteralPath $CodeCoverageOutputPath -Force -ErrorAction SilentlyContinue
        # Remove-Item -LiteralPath $TestResultOutputPath -Force -ErrorAction SilentlyContinue
    }
}
