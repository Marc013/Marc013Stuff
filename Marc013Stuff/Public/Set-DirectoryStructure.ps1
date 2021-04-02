function Set-DirectoryStructure {
    <#
    .SYNOPSIS
        Create directory structure as specified in the JSON directory structure template.

    .DESCRIPTION
        Set-DirectoryStructure creates or updates a directory structure specified in the JSON directory structure template file or object.
        When an existing directory structure is updated, directories and files specified in the JSON file or object are added, no directories or files are removed.
        Existing files are not recreated, only new files defined in the JSON are created.

        When specifying a source path that contains files mentioned in the JSON directory structure template file or object, these files are copied to their specified location.

        A JSON directory template example is availble in './Example/ExampleDirectoryStructure.json'.
        In this same directory dummy file 'file1.txt' is available for demo purposes of parameter -SourcePath.

    .PARAMETER TemplateFile
        JSON directory template file path (e.g. "./template/project-x.json")

    .PARAMETER TemplateObject
        JSON directory template object.

    .PARAMETER DestinationPath
        Path in where the directories and files are to be created or updated.
        This path must exist prior to running this function.

    .PARAMETER SourcePath
        Path in where source files are located that you want to copy into the directory structure.
        The file name within the source path and JSON directory template file must be a 100% match.

    .PARAMETER Depth
        JSON directory template depth.
        This value is only required when you provide a template file of which the depth is greater then 100.

    .EXAMPLE
        Set-DirectoryStructure -TemplateFile .\Example\ExampleDirectoryStructure.json -DestinationPath C:\Project-X

        This command will create a directory structure in folder C:\Project-X as specified in JSON file ExampleDirectoryStructure.json.

    .EXAMPLE
        $DirectoryStructureObject = Get-Content -Path ..\Example\ExampleDirectoryStructure.json -Raw | ConvertFrom-Json -Depth 100
        Set-DirectoryStructure -TemplateObject DirectoryStructureObject -DestinationPath C:\Project-X

        This command will create a directory structure in folder C:\Project-X as specified in JSON object $DirectoryStructureObject

    .EXAMPLE
        Set-DirectoryStructure -TemplateFile .\Example\ExampleDirectoryStructure.json -DestinationPath C:\Project-X -SourcePath C:\Templates

        This command will create a directory structure in folder C:\Project-X as specified in JSON file ExampleDirectoryStructure.json and copy each file specified in the JSON to its designated location when available in the source path.
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
            HelpMessage = 'Path in where source files are located that you want to copy into the directory structure'
        )]
        [AllowEmptyString()]
        [string]$SourcePath = $null,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'JSON directory template depth'
        )]
        [int]$Depth = 100
    )
    [char]$Separator = [System.IO.Path]::DirectorySeparatorChar
    [string]$DestinationPath = $DestinationPath.TrimEnd($Separator)

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
                [string]$DestinatonFilePath = "$FilePath$Separator$File"
                [string]$SourceFilePath = "$SourcePath$Separator$File"

                if (Test-Path -Path "$DestinatonFilePath") {
                    Write-Verbose -Message "File '$DestinatonFilePath' already present"
                }
                elseif (Test-Path -Path $SourceFilePath) {
                    Write-Verbose "Copying file '$SourceFilePath' to '$FilePath'"
                    Copy-Item -Path $SourceFilePath -Destination $DestinationPath -Force -ErrorAction Stop
                }
                else {
                    Write-Verbose -Message "Creating file '$DestinatonFilePath'"
                    New-Item -Path $FilePath -Name $File -ItemType File | Out-Null
                }
            }
        }

        if ($Directories) {
            Write-Verbose -Message "Creating child directory(s)"
            Set-DirectoryStructure -TemplateObject $Directories -DestinationPath $FilePath -Depth $Depth -SourcePath $SourcePath -ErrorAction stop
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
