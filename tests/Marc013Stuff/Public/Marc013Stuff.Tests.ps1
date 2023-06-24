#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.4.1" }

BeforeDiscovery {
    $moduleName = (Get-Item -Path (Split-Path -Path $PSScriptRoot -Parent)).Name
    Remove-Module -Name $moduleName -ErrorAction SilentlyContinue
    Import-Module -Name "$PSScriptRoot/../../../modules/$moduleName" -Force -PassThru
}

Describe 'Invoke-PwshUnitTests function test.' {

    InModuleScope -ModuleName 'Marc013.PwshUtils' -ScriptBlock {

        Context 'Validate business logic' {
        }
    }
}

Describe 'Module manifest' -Tag 'ModuleManifest' {
    Context 'Module manifest' {
        BeforeEach {
            [string]$ModuleName = 'Marc013Stuff'
            [string]$ModuleManifestName = "$ModuleName.psd1"

            [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
                'PSUseDeclaredVarsMoreThanAssignments', $null,
                Justification = 'False positive on variable $ModuleManifestPath'
            )]
            [string]$ModuleManifestPath = "$PSScriptRoot/../../../modules/$moduleName/$ModuleManifestName"
        }

        It 'should be valid' {
            $sut = Test-ModuleManifest -Path $ModuleManifestPath

            $sut | Should -Be $true
        }
    }
}
