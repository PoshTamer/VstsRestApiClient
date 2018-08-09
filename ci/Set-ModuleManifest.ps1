
param (
    [Parameter(
        Mandatory=$true,
        Position=0
    )]
    [ValidateSet("1")]
    [String]$Version,

    [Parameter(
        Mandatory=$true,
        Position=1
    )]
    [ValidateScript({$_.Length -eq 40})]
    [String]$CommitHash
)

$ManifestPath  = (Join-Path (Split-Path $PSScriptRoot -Parent) ".\src\VstsRestApiClient.psd1")
$LatestVersion = ((Find-Module VstsRestApiClient -AllVersions).Version | Select-Object -First 1).Split('.')
$Manifest      = Get-Content $ManifestPath

$Tokens.Major      = $LatestVersion[0]
$Tokens.Minor      = $LatestVersion[1]
$Tokens.Patch      = $LatestVersion[2] + 1
$Tokens.CommitHash = $CommitHash

Write-Verbose "Replacing tokens in manifest..."
$Tokens | ForEach-Object { 
    $Manifest | ForEach-Object { $_ -Replace "\[\[$($_.Name))\]\]","$($_.Value)" } | Set-Content $ManifestPath
}