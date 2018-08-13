
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

@( "Pester", "PSScriptAnalyzer" ) | ForEach-Object {
    Install-Module $_ -Force -Scope CurrentUser -SkipPublisherCheck
    Import-Module $_ -Force
}

$Publish = ($Env:APPVEYOR_REPO_BRANCH -eq "master")

. (Join-Path (Split-Path $PSScriptRoot -Parent) "Tests\run.ps1")

if ($TestResults.FailedCount -le 0) {
    Throw "Not all tests passed. Failing build..."
}

(Get-ChildItem (Join-Path (Split-Path $PSScriptRoot -Parent)) -Recurse -Include '*.psm1', '*.psd1').FullName | ForEach-Object {
    $AnalyzeResults = Invoke-ScriptAnalyzer -Path $_
    if ($AnalyzeResults -ne [String]::Empty) {
        Throw "$(Split-Path $_ -Child) did not pass PSScriptAnalyzer. Failing build..."
    }
}

if ($Ci) {

    (Get-ChildItem -Recurse -Include "*.psd1").FullName | ForEach-Object {
        $Manifest      = Get-Content $_ -Raw
        $OldVersion    = ([Regex]"\d*\.\d*\.\d*").Match(([Regex] "\s*ModuleVersion\s*=\s*'\d*\.\d*\.\d*';").Match($Manifest).Value).Value
        $NewVersion    = [Decimal[]] $OldVersion.Split('.')

        if ($Publish) {
            $NewVersion[1]++    
        }

        $NewVersion[2] = $BuildId
        $Manifest.Replace($OldVersion, $NewVersion -Join '.') | Set-Content $_ -Force
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

    $ReadMe = $ReadMe.Replace(([Regex] "!\[Coverage\]\(.*\)").Match($ReadMe).Value, "![Coverage](https://img.shields.io/badge/Coverage-$($NewCoverage)25-$($Color).svg)")
    $ReadMe | Set-Content "$PSScriptRoot\..\README.md" -Force

    Write-Verbose "Updating ReadMe and Manifests..."
    Add-Content "$HOME\.git-credentials" "https://$($env:GITHUB_TOKEN):x-oauth-basic@github.com`n"
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

    (New-Object System.Net.WebClient).UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Join-Path (Split-Path $PSScriptRoot -Parent) "Tests\TestResults.xml"))

    if ($Publish) {
        Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "src\VstsRestApiClient.psd1")
        Publish-Module -Name VstsRestApiClient -NuGetApiKey $Env:PSGALLERY_TOKEN
    }
}