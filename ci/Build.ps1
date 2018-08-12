
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

@( "Pester" ) | ForEach-Object {
    Install-Module $_ -Force -Scope CurrentUser -SkipPublisherCheck
    Import-Module $_ -Force
}

. "$PSScriptRoot\..\Tests\run.ps1"

if ($Ci) {
    if ($TestResults.FailedCount -le 0) {
        $Manifests = (Get-ChildItem -Recurse -Include "*.psd1").FullName
        $Manifests | ForEach-Object {
            $Manifest   = Get-Content $_ -Raw
            $OldVersion = ([Regex]"\d.\d.\d").Match(([Regex] "\s*ModuleVersion\s*=\s*'\d\.\d\.\d';").Match($Manifest).Value)
            
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

    $ReadMe = $ReadMe.Replace(([Regex] "!\[Coverage\]\(.*\)").Match().Value, "https://img.shields.io/badge/Coverage-$($NewCoverage)-$($Color).svg")
    $ReadMe | Set-Content "$PSScriptRoot\..\README.md" -Force

    Invoke-Expression -Command "git add *.psd1"
    Invoke-Expression -Command "git add *.md"
    Invoke-Expression -Command "git commit -m '[SKIP CI]Updating manifests and readme'"
    Invoke-Expression -Command "git push"
}