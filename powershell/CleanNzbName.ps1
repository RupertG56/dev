param(
    [string]$Path = ".",
    [string]$SearchPattern = "[^\w\.-]",
    [string]$Replacement = "s02",
    [switch]$WhatIf = $false,
    [switch]$Directory = $false,
    [bool]$Complex = $false
)

# sample usage: .\CleanFileName.ps1 -Path "C:\path\to\files" -SearchPattern "[^\w\.-]" -Replacement "_" -WhatIf

Write-Output "Renaming files in path: $Path"

if (-not $Directory) {
    $items = Get-ChildItem -Path $Path -Recurse -File
} else {
    $items = Get-ChildItem -Path $Path -Recurse -Directory
}

$items | ForEach-Object {
    # are we renaming a season/episode file/directory?
    $showRegex = [regex]'[sS](\d+)[eE](\d+)'
    if ($showRegex.IsMatch($_.Name)) {
        # Complex renaming: only replace dots before/after season/episode, not within
        $text = $_.Name
        $pattern = '(?i)^(.*?)(\.)(s\d{1,2}e\d{1,2})(\.)(.*)$'   # (?i) = case-insensitive

        if ($text -match $pattern) {
            $prefix = $matches[1]
            $dotBefore = $matches[2]
            $se = $matches[3]
            $dotAfter = $matches[4]
            $suffix = $matches[5]

            # preserve extension (keep last dot + extension intact)
            $lastDot = $suffix.LastIndexOf('.')
            if ($lastDot -ge 0) {
                $body = $suffix.Substring(0, $lastDot)
                $ext = $suffix.Substring($lastDot)   # includes dot
            }
            else {
                $body = $suffix
                $ext = ''
            }

            $newName = ($prefix -replace '\.', '-') + $dotBefore + $se + $dotAfter + ($body -replace '\.', '-') + $ext
        }
        else {
            Write-Host "Pattern did not match. Check case / SxxExx format."
            $newName = $text -replace $SearchPattern, $Replacement
        }
    } else {
        # Simple renaming: replace all occurrences of SearchPattern with Replacement
        $newName = $_.Name -replace $SearchPattern, $Replacement
    }

    if ($_.Name -ne $newName) {
        if (-not ($WhatIf)) { Write-Output "Renaming '$($_.FullName)' to '$newName'"}
        
        Rename-Item -Path $_.FullName -NewName $newName -WhatIf:$WhatIf
    }
}