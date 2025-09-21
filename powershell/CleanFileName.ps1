param(
    [string]$Path = ".",
    [string]$SearchPattern = "[^\w\.-]",
    [string]$Replacement = "s02",
    [switch]$WhatIf = $false
)

Write-Output "Renaming files in path: $Path"
Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
    $newName = $_.Name -replace $SearchPattern, $Replacement
    if ($_.Name -ne $newName) {
        Write-Output "Renaming '$($_.FullName)' to '$newName'"
        Rename-Item -Path $_.FullName -NewName $newName -WhatIf:$WhatIf
    }
}