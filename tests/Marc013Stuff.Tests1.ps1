$ModuleName = 'Marc013Stuff'
$ModuleManifestName = "$ModuleName.psd1"
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\$ModuleName"
Remove-Module $ModuleName -ErrorAction SilentlyContinue
Import-Module -Name $ModulePath

Describe "Module manifest" -Tag 'ModuleManifest' {
    Context 'Module manifest' {
        BeforeEach {
            [string]$ModuleName = 'Marc013Stuff'
            [string]$ModuleManifestName = "$ModuleName.psd1"
            [string]$ModuleManifestPath = "$PSScriptRoot\..\$ModuleName\$ModuleManifestName"
        }

        It 'should be valid' {
            $sut = Test-ModuleManifest -Path $ModuleManifestPath

            $sut | Should -Be $true
        }
    }
}