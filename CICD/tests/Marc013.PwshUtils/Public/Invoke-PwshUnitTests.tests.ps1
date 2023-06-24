#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.4.1" }

BeforeDiscovery {
    $moduleName = (Get-Item -Path (Split-Path -Path $PSScriptRoot -Parent)).Name
    Remove-Module -Name $moduleName -ErrorAction SilentlyContinue

    [System.IO.FileInfo]$path = "$PSScriptRoot/../../../modules/$moduleName"
    Write-Host "PATH '$("$($path.fullname)")'" -ForegroundColor DarkYellow ## TEST: testing
    Import-Module -Name "$PSScriptRoot/../../../modules/$moduleName" -Force -PassThru
}

Describe 'Invoke-PwshUnitTests function test.' {

    InModuleScope -ModuleName 'Marc013.PwshUtils' -ScriptBlock {

        Context 'Validate business logic' {
        }
    }
}
