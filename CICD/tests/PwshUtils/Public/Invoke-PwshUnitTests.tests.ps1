#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.4.1" }

BeforeDiscovery {
    $moduleName = (Get-Item -Path (Split-Path -Path $PSScriptRoot -Parent)).Name
    Remove-Module -Name $moduleName -ErrorAction SilentlyContinue
    Import-Module -Name "$PSScriptRoot/../../../modules/$moduleName" -Force -PassThru
}

Describe 'Invoke-PwshUnitTests function test.' {

    InModuleScope -ModuleName 'PwshUtils' -ScriptBlock {

        Context 'Validate business logic' {
            BeforeAll -Scriptblock {
                Mock -CommandName Test-Path -MockWith { return $true }
                Mock -CommandName Get-ChildItem -MockWith { return $null }
                Mock -CommandName Select-String -MockWith { return $null }
                Mock -CommandName New-Item -MockWith { return $null }
                Mock -CommandName Invoke-Pester -MockWith { return $null }
            }

            It 'Should should specify variable $isContainer to True' {
                $outputDirectory = 'mockDirectory'
                [System.IO.DirectoryInfo[]]$containerPathMock = './tests/myModule'
                [System.IO.FileInfo]$fileMock = "$($containerPathMock.FullName)/mock.ps1"
                [System.IO.DirectoryInfo[]]$pathMock = "./modules/myModule/$outputDirectory"
                Write-Host "pathMock.FullName: '$($pathMock.FullName)'" -ForegroundColor DarkCyan ## TEST

                Mock -CommandName Test-Path -MockWith { return $true } -ParameterFilter { $Path -eq $containerPathMock -and $PathType -eq 'Container' }
                Mock -CommandName Test-Path -MockWith { return $false } -ParameterFilter { $Path -eq $pathMock }
                Mock -CommandName Get-ChildItem -MockWith { return $fileMock } -ParameterFilter { $Filter -eq '*.tests.ps1' }
                Mock -CommandName New-Item -MockWith {
                    $script:assertVariable = Get-Variable -Name isContainer -ValueOnly
                    Get-Variable | Out-File -FilePath C:\Temp\_variables.txt -Force
                }

                Invoke-PwshUnitTests -Path $containerPathMock.FullName -OutputDirectory $outputDirectory
                Write-Host "script:assertVariable = '$($script:assertVariable)'" -ForegroundColor DarkCyan ## TEST

                $script:assertVariable | Should -BeFalse
            }
        }
    }
}
