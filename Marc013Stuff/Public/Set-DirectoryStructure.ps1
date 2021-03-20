function Set-DirectoryStructure {
    <#
    .SYNOPSIS
        Creat directory structure as specified in the JSON directory structure template.

    .DESCRIPTION
        Set-DirectoryStructure creates or updates the directory structure specified in the JSON directory structure template file or object.
        When an existing directory structure is updated, directories and files specified in the JSON file or object are added, no directories or files are removed.

        A JSON directory template example is availble in './Example/ExampleDirectoryStructure.json'.

    .PARAMETER TemplateFile
        JSON directory template file path (e.g. "./template/project-x.json")

    .PARAMETER TemplateObject
        JSON directory template object.

    .PARAMETER DestinationPath
        Path in where the directories and files are to be created or updated.
        This path must exist prior to running this function.

    .PARAMETER Depth
        JSON directory template depth.
        This value is only required when you provide a template file of which the depth is greater then 100.

    .EXAMPLE
        Set-DirectoryStructure -TemplateFile .\Example\ExampleDirectoryStructure.json -DestinationPath C:\Project-X -Verbose

    .EXAMPLE
        $DirectoryStructureObject = Get-Content -Path ..\Example\ExampleDirectoryStructure.json -Raw | ConvertFrom-Json -Depth 100
        Set-DirectoryStructure -TemplateObject DirectoryStructureObject -DestinationPath C:\Project-X -Verbose
    #>
    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName = 'TemplateFile'
    )]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'JSON directory template file path (e.g. "./template/project-x.json")',
            ParameterSetName = 'TemplateFile'
        )]
        [string]$TemplateFile,
        [Parameter(
            Mandatory = $true,
            HelpMessage = "JSON directory template object",
            ParameterSetName = 'TemplateObject'
        )]
        [PSCustomObject]$TemplateObject,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Path in where the directories and files are to be created or updated'
        )]
        [string]$DestinationPath,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'JSON directory template depth'
        )]
        [int]$Depth = 100
    )
    [char]$Separator = [System.IO.Path]::DirectorySeparatorChar

    if ($TemplateFile) {
        Write-Verbose -Message "Getting content of directory structure template file '$TemplateFile'"
        $Data = (Get-Content -Path $TemplateFile -Raw | ConvertFrom-Json -Depth $Depth).directories
    }
    else {
        Write-Verbose -Message 'Using directory structure template object'
        $Data = ($TemplateObject).directories

        if ([string]::IsNullOrWhiteSpace($Data)) {
            $Data = $TemplateObject
        }
    }

    foreach ($Directory in $Data.directory) {
        $DirectoryName = $Directory.name
        $Directories = $Directory.directories
        $Files = $Directory.files
        $FilePath = $DestinationPath

        if ($DirectoryName) {
            Write-Verbose -Message "Creating directory '$FilePath$Separator$DirectoryName'"
            New-Item -Path $FilePath -Name $DirectoryName -ItemType Directory -Force | Out-Null
        }

        if ($Files -or $Directories) {
            $FilePath = ("$DestinationPath$Separator$DirectoryName").TrimEnd($Separator)
            Write-Verbose -Message "Setting FilePath to '$FilePath'"
        }

        if ($Files) {
            foreach ($File in $Files) {
                if (Test-Path -Path "$FilePath$Separator$File") {
                    Write-Verbose -Message "File '$FilePath$Separator$File' already present"
                }
                else {
                    Write-Verbose -Message "Creating file '$FilePath$Separator$File'"
                    New-Item -Path $FilePath -Name $File -ItemType File | Out-Null
                }
            }
        }

        if ($Directories) {
            Write-Verbose -Message "Creating child directory(s)"
            Set-DirectoryStructure -TemplateObject $Directories -DestinationPath $FilePath -Depth $Depth -ErrorAction stop
        }
        else {
            if ($FilePath.TrimEnd($Separator) -ne $DestinationPath.TrimEnd($Separator)) {
                $ParentPath = $FilePath.Substring(0, $FilePath.lastIndexOf($Separator))
                Write-Verbose -Message "Setting FilePath to parent '$ParentPath'"
            }
        }
    }
    $FunctionCalled = $(Get-PSCallStack | Where-Object { $PSItem.Command -eq 'Set-DirectoryStructure' }).count
    if ($FunctionCalled -le 1) {
        Write-Host "Directory structure creation completed"
    }
}
