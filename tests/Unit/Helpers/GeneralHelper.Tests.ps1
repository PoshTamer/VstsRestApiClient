
Describe "GeneralHelper Unit Tests" {
   
    BeforeAll {
        $ModulePath = "$($PSScriptRoot)\..\..\..\VstsRestApiClient\Helpers\GeneralHelper.psm1"
        Get-Module GeneralHelper | Remove-Module
        Import-Module $ModulePath
    }

    InModuleScope "GeneralHelper" {

        Describe "Get-ReplacedString" {

            It "Should not modify string if not values found" {
                $test = "1"
                Get-ReplacedString -String $test -Placeholders @( @{ Name = "test"; Value = "test1" } ) | Should -Be "1" 
            }

            It "Should replace values if found" {
                $test = "{test}"
                Get-ReplacedString -String $test -Placeholders @( @{ Name = "test"; Value = "test1" } ) | Should -Be "test1"
            }
        }

        Describe "Test-ValidJson" {

            It "Should return true if json is valid" {
                $test = '{ "test": 1 }'
                Test-ValidJson -String $test | Should -Be $True 
            }

            It "Should return false if json is invalid" {
                $test = '{ "test"= 1 }'
                Test-ValidJson -String $test | Should -Be $False
            }
        }

        Describe "ConvertFrom-JsonFile" {

            It "Should return json file contents as an object" {
                New-Item -Path "$PSScriptRoot\test.json" -ItemType "File"
                '{ "test": 1 }' | Set-Content "$PSScriptRoot\test.json"
                (ConvertFrom-JsonFile -Path "$PSScriptRoot\test.json").test | Should -Be 1
                Remove-Item -Path "$PSScriptRoot\test.json" -Force 
            }

            It "Should throw if json file contents is invalid json" {
                New-Item -Path "$PSScriptRoot\test.json" -ItemType "File"
                '{ "test"= 1 }' | Set-Content "$PSScriptRoot\test.json"
                { (ConvertFrom-JsonFile -Path "$PSScriptRoot\test.json") } | Should -Throw "Invalid JSON Found at $($PSScriptRoot)\test.json."
                Remove-Item -Path "$PSScriptRoot\test.json" -Force
            }
        }
    }
}