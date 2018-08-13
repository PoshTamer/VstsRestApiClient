
Import-Module Pester -Force

$rootFolderPath = (Join-Path (Split-Path $PSScriptRoot -Parent) "VstsRestApiClient")
$Params = @{
    OutputFile = "$($PSScriptRoot)\TestResults.xml"
    CodeCoverageOutputFileFormat = "JaCoCo"
    CodeCoverage = (Get-ChildItem $rootFolderPath -File -Recurse -Include "*.psm1").FullName
    CodeCoverageOutputFile = "$($PSScriptRoot)\CodeCoverage.xml"
}
$TestResults = Invoke-Pester @Params -PassThru
$Null = $TestResults