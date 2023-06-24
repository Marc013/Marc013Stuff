function Set-DirectoryStructure {
    <#
    .SYNOPSIS
        Create directory structure as specified in the JSON directory structure template.

    .DESCRIPTION
        Set-DirectoryStructure creates or updates a directory structure specified in the JSON directory structure template file or object.
        When an existing directory structure is updated, directories and files specified in the JSON file or object are added, no directories or files are removed.
        Existing files are not recreated, only new files defined in the JSON are created.

        When specifying a source path that contains files mentioned in the JSON directory structure template file or object, these files are copied to their specified location.
        The destination and source relative path must be the same!

        When specifying "all" in the "files" section the content of the source directory will be recursively copied to the destination directory.

        A JSON directory template example is available in './Example/ExampleDirectoryStructure.json'.

    .PARAMETER TemplateFile
        JSON directory template file path

    .PARAMETER TemplateObject
        JSON directory template object

    .PARAMETER DestinationPath
        Path in where the directories and files are to be created or updated
        This path must exist prior to running this function

    .PARAMETER SourcePath
        Path in where source files are located that you want to copy into the directory structure
        The file name within the source path and JSON directory template file must be a 100% match

    .EXAMPLE
        Set-DirectoryStructure -TemplateFile .\Example\ExampleDirectoryStructure.json -DestinationPath C:\Project-X

        This command will create a directory structure in folder C:\Project-X as specified in JSON file ExampleDirectoryStructure.json.

    .EXAMPLE
        $DirectoryStructureObject = Get-Content -Path ..\Example\ExampleDirectoryStructure.json -Raw | ConvertFrom-Json
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
            HelpMessage = 'JSON directory template file path',
            ParameterSetName = 'TemplateFile'
        )]
        [string]$TemplateFile,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'JSON directory template object',
            ParameterSetName = 'TemplateObject'
        )]
        [object]$TemplateObject,
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
        [string]$SourcePath = $null
    )
    [string]$DestinationPath = $DestinationPath.Replace('\', '/').TrimEnd('/')
    [string]$SourcePath = $SourcePath.Replace('\', '/')

    if ($TemplateFile) {
        Write-Verbose -Message "Getting content of directory structure template file '$TemplateFile'"
        [object]$Data = (Get-Content -Path $TemplateFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop).directories
    }
    else {
        # Write-Verbose -Message 'Using directory structure template object'
        [object]$Data = ($TemplateObject).directories

        if ((-not $Data.directory)) { #-or ([string]::IsNullOrWhiteSpace($Data)) -or ([string]::IsNullOrEmpty($Data))) {
            [object]$Data = $TemplateObject
        }
    }

    foreach ($Directory in $Data.directory) {
        [string]$DirectoryName = $Directory.name
        [object]$Directories = $Directory.directories
        [object]$Files = $Directory.files
        [string]$FilePath = $DestinationPath

        if ($DirectoryName) {
            Write-Verbose -Message "Creating directory '$FilePath/$DirectoryName'"
            New-Item -Path $FilePath -Name $DirectoryName -ItemType Directory -Force | Out-Null
        }

        if ($Files -or $Directories) {
            [string]$FilePath = ("$DestinationPath/$DirectoryName").TrimEnd('/')
            Write-Verbose -Message "Setting FilePath to '$FilePath'"

            [string]$SourceDirPath = "$SourcePath/$DirectoryName"
        }

        if ($Files) {
            foreach ($File in $Files) {
                [string]$DestinationFilePath = "$FilePath/$File"
                [string]$SourceFilePath = "$SourceDirPath/$File"

                if ($File -eq 'all') {
                    Write-Verbose "Copy all from '$SourceDirPath' to '$FilePath'"
                    Copy-Item -Path "$SourceDirPath/*" -Destination $FilePath -Recurse -Force -ErrorAction Stop
                }
                elseif (Test-Path -Path "$DestinationFilePath") {
                    Write-Verbose -Message "File '$DestinationFilePath' already present"
                }
                elseif (Test-Path -Path $SourceFilePath) {
                    Write-Verbose "Copying file '$SourceFilePath' to '$FilePath'"
                    Copy-Item -Path $SourceFilePath -Destination $FilePath -Force -ErrorAction Stop
                }
                else {
                    Write-Verbose -Message "Creating file '$DestinationFilePath'"
                    New-Item -Path $FilePath -Name $File -ItemType File | Out-Null
                }
            }
        }

        if ($Directories) {
            Write-Verbose -Message 'Creating child directory(s)'
            Set-DirectoryStructure -TemplateObject $Directories -DestinationPath $FilePath -SourcePath $SourceDirPath -ErrorAction stop
        }
    }

    [int]$FunctionCalled = $(Get-PSCallStack | Where-Object -FilterScript { $PSItem.Command -eq 'Set-DirectoryStructure' }).count
    if ($FunctionCalled -le 1) {
        Write-Host 'Directory structure creation completed'
    }
}
