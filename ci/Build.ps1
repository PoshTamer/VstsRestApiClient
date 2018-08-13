
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

Write-Verbose "Running Tests..."
. (Join-Path (Split-Path $PSScriptRoot -Parent) "Tests\run.ps1")

if ($TestResults.FailedCount -gt 0) {
    Throw "Not all tests passed. Failing build..."
}

Write-Verbose "Running PSScriptAnalyzer..."
(Get-ChildItem (Split-Path $PSScriptRoot -Parent) -Recurse -Include 'VstsRestApiClient.psm1', 'VstsRestApiClient.psd1').FullName | ForEach-Object {
    $AnalyzeResults = Invoke-ScriptAnalyzer -Path $_
    if ($AnalyzeResults -ne $Null) {
        Throw "$(Split-Path $_ -Leaf) did not pass PSScriptAnalyzer. Failing build..."
    }
}

if ($Ci) {
    Write-Verbose "Running CI..."
    Write-Verbose "Setting patch for all manifests..."
    (Get-ChildItem (Split-Path $PSScriptRoot -Parent) -Recurse -Include "*.psd1").FullName | ForEach-Object {
        $Manifest      = Get-Content $_ -Raw
        $OldVersion    = ([Regex]"\d*\.\d*\.\d*").Match(([Regex] "\s*ModuleVersion\s*=\s*'\d*\.\d*\.\d*';").Match($Manifest).Value).Value
        $NewVersion    = [Decimal[]] $OldVersion.Split('.')

        if ($Publish) {
            Write-Verbose "Stepping Minor..."
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

    Write-Verbose "Uploading test results to AppVeyor..."
    (New-Object System.Net.WebClient).UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Join-Path (Split-Path $PSScriptRoot -Parent) "Tests\TestResults.xml"))

    if ($Publish) {
        Write-Verbose "Publishing VstsRestApiClient to the PSGallery..."
        Publish-Module -Path (Join-Path (Split-Path $PSScriptRoot -Parent) "VstsRestApiClient") -NuGetApiKey $Env:PSGALLERY_TOKEN
    }
}