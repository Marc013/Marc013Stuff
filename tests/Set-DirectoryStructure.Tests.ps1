$ModuleName = 'Marc013Stuff'
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\$ModuleName"
Remove-Module $ModuleName -ErrorAction SilentlyContinue
Import-Module -Name $ModulePath

Describe 'Function Set-DirectoryStructure' {
    Context 'with valid parameters' {

        It "ItName" {
            # TODO
        }
    }


    Context 'with invalid parameters' {
        It "ItName" {
            # TODO
        }
    }
}