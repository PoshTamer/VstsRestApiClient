
Describe "DefinitionsHelper Unit Tests" {
   
    BeforeAll {
        $ModulePath = "$($PSScriptRoot)\..\..\..\VstsRestApiClient\Helpers\DefinitionsHelper.psm1"
        Get-Module DefinitionsHelper | Remove-Module
        Import-Module $ModulePath
    }

    InModuleScope "DefinitionsHelper" {

        Describe "Test-ObjectDefintion" {

            It "Primitive: Should return <Result> (<Type>)" -TestCases @(
                @{ 
                    Type     = "Int32"
                    Result   = "TRUE"
                    Object   = 1
                    Expected = $True 
                },
                @{ 
                    Type     = "Int32"
                    Result   = "FALSE"
                    Object   = "NotInt32"
                    Expected = $False 
                },
                @{ 
                    Type     = "String"
                    Result   = "TRUE"
                    Object   = "String"
                    Expected = $True 
                },
                @{ 
                    Type     = "String"
                    Result   = "FALSE"
                    Object   = 1
                    Expected = $False 
                }
            ){
                param (
                    $Type,
                    $Object,
                    $Expected
                )

                (Test-ObjectDefinition -Obj $Object -Type $Type) | Should -Be $Expected 
            }

            It "Custom: Should return <Result> (<Type>)" -TestCases @(
                @{ 
                    Type     = "ReferenceLinks"
                    Result   = "TRUE"
                    Object   = @{ links = @{} }
                    Expected = $True 
                },
                @{ 
                    Type     = "Hashtable"
                    Result   = "TRUE"
                    Object   = @{ ReferenceLinks = @{ links = @{} } }
                    Expected = $True 
                },
                @{ 
                    Type   = "ArtifactResource"
                    Result = "TRUE"
                    Object = @{ 
                        _links         = @{ links = @{} }
                        data           = ""
                        downloadTicket = ""
                        downloadUrl    = ""
                        properties     = @{}
                        type           = ""
                        url            = ""
                    }
                    Expected = $True 
                },
                @{ 
                    Type   = "ArtifactResource"
                    Result = "FALSE"
                    Object = @{ 
                        _links         = ""
                        data           = ""
                        downloadTicket = ""
                        downloadUrl    = ""
                        properties     = @{}
                        type           = ""
                        url            = ""
                    }
                    Expected = $False
                },
                @{ 
                    Type     = "ReferenceLinks"
                    Result   = "FALSE"
                    Object   = "NotHashTable"
                    Expected = $False 
                }
            ){
                param (
                    $Type,
                    $Object,
                    $Expected
                )

                (Test-ObjectDefinition -Obj $Object -Type $Type) | Should -Be $Expected 
            }
        }
    }
}