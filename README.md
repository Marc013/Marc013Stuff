# Marc013Stuff

PowerShell module with all kinds of miscellaneous goodies

## Functions

* **Set-DirectoryStructure** <br>
  This function creates or updates the directory structure specified in the JSON directory structure template file or object.<br>
  A template example is available [here][1].

* **New-UnitTestReport** <br>
  Use this function to create a code coverage report using _Pester 5_ and _ReportGenerator_.<br>
    * PowerShell module [Pester][2]
    * Daniel Palme's [ReportGenerator][3]

> Running function _New-UnitTestReport_:
> 
> * Download/clone repo [FancyStuff][4].
>     * In the example below the repo is cloned in path _C:\git_.
> * Download/clone this repo.
>     * In my situation the repo is cloned in path _C:\git_
> * Import module `Marc013Stuff`
>     * `Import-Module -Name C:\git\Marc013Stuff\Marc013Stuff`
> * Run command:
> ```PowerShell
> New-UnitTestReport -Path C:\git\FancyStuff\tests -ScriptPath C:\git\FancyStuff\modules\LazyGuy\public\*.ps1 -ReportUnitPath MockReportUnit.exe -ReportGeneratorPat MockGenerator.exe -ReportType HtmlInline_AzurePipelines, HtmlInline_AzurePipelines_Dark
> ```


[1]: https://github.com/Marc013/Marc013Stuff/blob/main/Example/ExampleDirectoryStructure.json
[2]: https://www.powershellgallery.com/packages/Pester
[3]: https://danielpalme.github.io/ReportGenerator/
[4]: https://github.com/Marc013/FancyStuff
