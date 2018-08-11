
function Test-ObjectDefinition
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0
        )]
        [Alias('Obj')]
        [PSObject]$Object,

        [Parameter(
            Mandatory=$true,
            Position=1
        )]
        [String]$Type,

        [Parameter(
            Mandatory=$false,
            Position=2
        )]
        [Alias('AllDefs')]
        [PSObject]$AllDefinitions
    )

    Import-Module "$PSScriptRoot\GeneralHelper.psm1" -Force
    
    $Result = $True

    if ($AllDefinitions -eq $Null) {
        $AllDefinitions = ConvertFrom-JsonFile (Join-Path (Split-Path $PSScriptRoot -Parent) "definitions.json")
    }

    $Definition = $AllDefinitions.Where({ $_.Name -eq $Type })
    if ($Definition) {
        $Definition.Properties | ForEach-Object {
            $PropertyType = $_.Type
            $ThisObject   = $Object.$($_.Name)
            $Property     = $AllDefinitions.Where({ $_.Name -eq $PropertyType })
            if ($Property) {
                $Property.Properties | ForEach-Object {
                    $Params = @{
                        Obj     = $ThisObject
                        Type    = $_.Type
                        AllDefs = $AllDefinitions
                    }
                    if ($Result -And !(Test-ObjectDefinition @Params)) {
                        $Result = $False
                    }
                }
            }
            elseif ($Null -eq $ThisObject -Or $ThisObject.GetType().Name -ne $PropertyType ) {
                $Result = $False
            }
        }
    }
    elseif ($Object.GetType().Name -ne $Type) {
        $Result = $False
    }

    return $Result
}