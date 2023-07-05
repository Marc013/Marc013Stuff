function Invoke-PwshUnitTests {
    <#
    .SYNOPSIS
        Run PowerShell Pester unit tests.

    .DESCRIPTION
        Invoke-PwshUnitTests runs any PowerShell Pester unit test located in the provided path.
        Test results and code coverage will be stored as XML file in the provided output directory in the tests path.

        Expected directory structure:

        <repo>/modules
        └───myModule
            │   myModule.psd1
            │   myModule.psm1
            │
            ├───Private
            │       Get-PrivateFunction1.ps1
            │       Get-PrivateFunction2.ps1
            │
            └───Public
                    New-PublicFunction1.ps1
                    New-PublicFunction2.ps1

        <repo>/tests
        └───myModule
            ├───Private
            │       Get-PrivateFunction1.tests.ps1
            │       Get-PrivateFunction2.tests.ps1
            │
            └───Public
                    New-PublicFunction1.tests.ps1
                    New-PublicFunction2.tests.ps1

    .PARAMETER Path
        Provide the path of the Pester tests directory or files

    .PARAMETER OutputDirectory
        Provide the directory name where the Pester test results are to be placed

    .NOTES
        This function required Pester 5!
        https://www.powershellgallery.com/packages/Pester

    .EXAMPLE
        Invoke-PwshUnitTests -Path <repo>/tests/myModule -OutputDirectory results

        This command will run all Pester tests (*.tests.ps1) present in the provided path and create result files 'CoveragePester.xml' and 'ResultsPester.xml' in path <repo>/tests/myModule/results.
        When any pwsh function is does not have any unit tests the code coverage of that function will be reported as 0.

    .EXAMPLE
        Invoke-PwshUnitTests -Path <repo>/tests/myModule/Public/New-PublicFunction1.tests.ps1, <repo>/tests/myModule/Public/New-PublicFunction2.tests.ps1 -OutputDirectory results -Verbose

        This command will only run the tests and code coverage of the files provided in parameter Path.
        Result files 'CoveragePester.xml' and 'ResultsPester.xml' are saved in path <repo>/tests/myModule/results.

        The Pester configuration is presented as JSON output as parameter Verbose is provided.
    #>
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
    Write-Host "Path: '$($Path.FullName)" -ForegroundColor DarkCyan ## TEST

    if (Test-Path -Path $Path[0] -PathType Container) {
        $isContainer = $true
        $testsFiles = Get-ChildItem -Path $Path -Filter *.tests.ps1 -Recurse -Depth 4 -File
        Write-Host "isContainer: '$isContainer'" -ForegroundColor DarkCyan ## TEST
        Write-Host "testsFiles: '$($testsFiles.FullName)'" -ForegroundColor DarkCyan ## TEST
    }
    else {
        $isContainer = $false
        [System.IO.FileInfo[]]$testsFiles = $Path.FullName
        Write-Host "isContainer: '$isContainer'" -ForegroundColor DarkCyan ## TEST
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
        $count = 0

        $testsFiles | ForEach-Object -Process {
            $count++

            $isModuleManifest = Select-String -Pattern '(\.psd1|Test-ModuleManifest)' -Path $PSItem

            $fileExtension = $isModuleManifest ? '.psd1' : '.ps*'

            $scriptName = "$($PSItem.Name.Split('.')[0])$fileExtension"

            $modulePath = $PSItem.DirectoryName -ireplace 'tests', 'modules' -ireplace 'public' -ireplace 'private'

            $testsFile = (Get-ChildItem -Path $modulePath -Filter $scriptName -Recurse -Depth 3).FullName

            if ([string]::IsNullOrWhiteSpace($testsFile)) {
                Write-Warning 'Unable to locate script file, code coverage will not be provided.'
            }
            elseif ($testsFile.Count -gt 1) {
                $testsFile | ForEach-Object -Process {
                    [Void]$codeCoveragePath.Add($PSItem)
                }
            }
            else {
                [Void]$codeCoveragePath.Add($testsFile)
            }

            $debugOutput = [ordered]@{
                loop             = $count
                processed        = $PSItem.FullName
                fileExtension    = $fileExtension
                scriptName       = $scriptName
                modulePath       = $modulePath
                testsFile        = $testsFile
                codeCoveragePath = $($codeCoveragePath | Out-String)
            }
            Write-Debug "$($debugOutput | ConvertTo-Json -Depth 2 | ConvertFrom-Json -Depth 2 | Out-String)"
        }
    }

    [System.IO.DirectoryInfo]$OutputPath = "$pwshModulePath/$OutputDirectory"

    Write-Host "creating path '$($OutputPath.FullName)' ?" -ForegroundColor DarkYellow ## TEST
    Write-Host "Exists? '$(Test-Path -Path $OutputPath)'" -ForegroundColor DarkYellow ## TEST
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "Created path '$($OutputPath.FullName)'" -ForegroundColor DarkYellow ## TEST
    }
    else {
        Write-Host 'NO' -ForegroundColor DarkYellow ## TEST
    }
    Write-Host "path created?'" -ForegroundColor DarkYellow ## TEST

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

    Write-Debug "Pester config: $($Configuration | ConvertTo-Json -Depth 100)"

    Invoke-Pester -Configuration $Configuration

    [ordered]@{
        CodeCoverageReport = "$OutputPath/CoveragePester.xml"
        UnitTestsReport    = "$OutputPath/ResultsPester.xml"
    }
}
