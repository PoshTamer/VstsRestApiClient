
function Get-ReplacedString
{
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0
        )]
        [String]$String,

        [Parameter(
            Mandatory=$true,
            Position=1
        )]
        [HashTable[]]$Placeholders
    )

    $Placeholders | ForEach-Object {
        $String = $String.Replace("{$($_.Name)}", "$($_.Value)")
    }
    return $String
}

function Test-ValidJson
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0
        )]
        [String]$String
    )

    try { $Null = $String | ConvertFrom-Json } catch { return $False }
    return $True
}

function ConvertFrom-JsonFile
{
    [CmdletBinding()]
    [OutputType([PSObject])]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0
        )]
        [ValidateScript({Test-Path $_})]
        [String]$Path
    )

    $JsonAsString = Get-Content $Path -Raw
    
    if (Test-ValidJson $JsonAsString) {
        return $JsonAsString | ConvertFrom-Json
    }
    else {
        Throw "Invalid JSON Found at $($Path)."
    }
}