
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

. "$PSScriptRoot\..\Tests\run.ps1"

if ($Ci) {
    if ($TestResults.FailedCount -le 0) {
        $Manifests = (Get-ChildItem -Recurse -Include "*.psd1").FullName
        $Manifests | ForEach-Object {
            $Manifest   = Get-Content $_ -Raw
            $OldVersion = ([Regex]"\d.\d.\d").Match(([Regex] "\s*ModuleVersion\s*=\s*'\d\.\d\.\d';").Match($Manifest).Value).Value
            
            $NewVersion = [Decimal[]] $OldVersion.Split('.')
            $NewVersion[0]++
            $NewVersion[1]++
            $NewVersion[2] = $BuildId
            
            $Manifest.Replace($OldVersion, $NewVersion) | Set-Content $_ -Force
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

    $ReadMe = $ReadMe.Replace(([Regex] "!\[Coverage\]\(.*\)").Match($ReadMe).Value, "https://img.shields.io/badge/Coverage-$($NewCoverage)-$($Color).svg")
    $ReadMe | Set-Content "$PSScriptRoot\..\README.md" -Force

    Write-Verbose "Updating ReadMe and Manifests..."
    [void](Invoke-Expression -Command "git config --global user.email build@appveyor.com")
    [void](Invoke-Expression -Command "git pull origin $($Env:APPVEYOR_REPO_BRANCH)")
    [void](Invoke-Expression -Command "git add *.psd1")
    [void](Invoke-Expression -Command "git add *.md")
    [void](Invoke-Expression -Command "git commit -m '[SKIP CI]Updating manifests and readme'")
    [void](Invoke-Expression -Command "git push origin HEAD:$($Env:APPVEYOR_REPO_BRANCH)")
}