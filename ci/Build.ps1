
[CmdletBinding(DefaultParameterSetName='NoCi')]
param(
    [Parameter(
        Mandatory=$False,
        Position=0,
        ParameterSetName='Ci'
    )]
    [Switch]$Ci,

    [Parameter(
        Mandatory=$True,
        Position=1,
        ParameterSetName='Ci'
    )]
    [Int32]$BuildId
)

Install-Module Pester -Force -Scope CurrentUser -SkipPublisherCheck

. (Join-Path (Split-Path $PSScriptRoot -Parent) "Tests\run.ps1")

if ($Ci) {

    if ($TestResults.FailedCount -le 0) {
        $Manifests = (Get-ChildItem -Recurse -Include "*.psd1").FullName
        $Manifests | ForEach-Object {
            $Manifest   = Get-Content $_ -Raw
            $OldVersion = ([Regex]"\d*.\d*.\d*").Match(([Regex] "\s*ModuleVersion\s*=\s*'\d*\.\d*\.\d*';").Match($Manifest).Value).Value
            
            $NewVersion = [Decimal[]] $OldVersion.Split('.')
            $NewVersion[2] = $BuildId
            
            $Manifest.Replace($OldVersion, $NewVersion -Join '.') | Set-Content $_ -Force
        }
    }

    $NewCoverage = "$(($TestResults.CodeCoverage.NumberOfCommandsExecuted/$TestResults.CodeCoverage.NumberOfCommandsAnalyzed * 100).ToString().SubString(0, 5))%"
    $ReadMe      = Get-Content "$PSScriptRoot\..\README.md" -Raw

    if ($NewCoverage -ge 90) {
        $Color = "brightgreen"
    }
    elseif ($NewCoverage -ge 75) {
        $Color = "yelow"
    }
    elseif ($NewCoverage -ge 65) {
        $Color = "orange"
    }
    else {
        $Color = "red"
    }

    $ReadMe = $ReadMe.Replace(([Regex] "!\[Coverage\]\(.*\)").Match($ReadMe).Value, "![CodeCoverage](https://img.shields.io/badge/Coverage-$($NewCoverage)25-$($Color).svg)")
    $ReadMe | Set-Content "$PSScriptRoot\..\README.md" -Force

    Write-Verbose "Updating ReadMe and Manifests..."
    Add-Content "$HOME\.git-credentials" "https://$($env:ACCESS_TOKEN):x-oauth-basic@github.com`n"
    [void](Invoke-Expression -Command "git config --global credential.helper store")
    [void](Invoke-Expression -Command "git config --global user.email galicea96@outlook.com -q")
    [void](Invoke-Expression -Command "git config --global user.name PoshTamer -q")
    [void](Invoke-Expression -Command "git config core.autocrlf false -q")
    [void](Invoke-Expression -Command "git checkout $($Env:APPVEYOR_REPO_BRANCH) -q")
    [void](Invoke-Expression -Command "git pull origin $($Env:APPVEYOR_REPO_BRANCH) -q")
    [void](Invoke-Expression -Command "git add *.psd1")
    [void](Invoke-Expression -Command "git add *.md")
    [void](Invoke-Expression -Command "git commit -m '[skip ci]Updating manifests and readme' -q")
    [void](Invoke-Expression -Command "git push -q")
}