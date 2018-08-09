
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

$ManifestPath = (Join-Path (Split-Path $PSScriptRoot -Parent) ".\src\VstsRestApiClient.psd1")
$TokensPath   = (Join-Path (Split-Path $PSScriptRoot -Parent) ".\src\v$($Version)\tokens.json")

$Tokens   = Get-Content $TokensPath -Raw | ConvertFrom-Json
$Manifest = Get-Content $ManifestPath

$Tokens.CommitHash = $CommitHash

Write-Verbose "Replacing tokens in manifest..."
$Tokens.Versions | ForEach-Object { 
    $Manifest | ForEach-Object { $_ -Replace "\[\[$($_.Name))\]\]","$($_.Value++)" } | Set-Content $ManifestPath
}

Write-Verbose "Updating tokens.json..."
$Tokens | ConvertTo-Json | Set-Content $TokensPath