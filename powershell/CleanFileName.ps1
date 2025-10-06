param(
    [string]$Path = ".",
    [string]$SearchPattern = "[^\w\.-]",
    [string]$Replacement = "s02",
    [switch]$WhatIf = $false,
    [switch]$Directory = $false
)

# sample usage: .\CleanFileName.ps1 -Path "C:\path\to\files" -SearchPattern "[^\w\.-]" -Replacement "_" -WhatIf

Write-Output "Renaming files in path: $Path"

if (-not $Directory) {
    $items = Get-ChildItem -Path $Path -Recurse -File
} else {
    $items = Get-ChildItem -Path $Path -Recurse -Directory
}

$items | ForEach-Object {
    $newName = $_.Name -replace $SearchPattern, $Replacement
    if ($_.Name -ne $newName) {
        Write-Output "Renaming '$($_.FullName)' to '$newName'"
        Rename-Item -Path $_.FullName -NewName $newName -WhatIf:$WhatIf
    }
}