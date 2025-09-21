# RenameMedia.ps1
# Renames files that start with a padded number and space (e.g., "001 File.txt" -> "File.txt")

param(
    [string]$Path = ".",
    [bool]$TwoPerFile = $false,
    [switch]$Complex = $false,
    [switch]$WhatIf = $false
)

$fileCount = 0
Write-Output "Renaming files in path: $Path"
$files = Get-ChildItem -File -Path $Path -Recurse
# There is no guarantee that Get-ChildItem will return files in any specific order.
# If you want to ensure files are processed in order (e.g., 01, 02, 03...), sort them:
$files = $files | Sort-Object Name
$files | ForEach-Object {
    if ($Complex) {
        $seasonMatch = [regex]::Match($_.Name, 'Season\s(\d+)', 'IgnoreCase')
        $episodeMatch = [regex]::Match($_.Name, 'Episode\s(\d+)', 'IgnoreCase')
        $seasonNumber = if ($seasonMatch.Success) { $seasonMatch.Groups[1].Value } else { $null }
        $episodeNumber = if ($episodeMatch.Success) { $episodeMatch.Groups[1].Value } else { $null }
        
        if ($seasonNumber -and $episodeNumber) {
            $seasonNumber = $seasonNumber.PadLeft(2, '0')
            $episodeNumber = $episodeNumber.PadLeft(2, '0')
            $parentDir = Split-Path $_.Directory.FullName -Leaf
            $underscoreIndex = $fileBaseName.IndexOf('_')
            if ($underscoreIndex -ge 0 -and $underscoreIndex + 1 -lt $fileBaseName.Length) {
                $afterUnderscore = $fileBaseName.Substring($underscoreIndex + 1).Trim()
            }
            else {
                $afterUnderscore = ""
            }
            $newName = "$parentDir.s$seasonNumber" + "e$episodeNumber.$afterUnderscore" + [System.IO.Path]::GetExtension($_.Name)
            $fileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            
            Write-Host "Renaming '$($_.Name)' to '$newName'"
            Rename-Item -Path $_.FullName -NewName $newName -WhatIf:$WhatIf
        }
        return
    }
    else {
        $episodeMatch = [regex]::Match($_.Name, '^\d+\s', 'IgnoreCase')
        $episodeNumber = if ($episodeMatch.Success) { $episodeMatch.Value.Trim() } else { $null }
        if ($episodeNumber) {
            $episodeNumber = [int]$episodeNumber
        }
        else {
            Write-Host "Skipping file '$($_.Name)' as it does not start with a number and space."
            return
        }

        if ($TwoPerFile) {
            $episodeNumber = $episodeNumber + $fileCount
            $episodeNumber2 = $episodeNumber + 1
            $episodeNumber2 = $episodeNumber2.ToString("D2")
        }
        $episodeNumber = $episodeNumber.ToString("D2")

        $seasonMatch = [regex]::Match($_.Directory.Name, '(\d+)', 'IgnoreCase')
        $seasonNumber = if ($seasonMatch.Success) { $seasonMatch.Groups[1].Value } else { $null }
        $seasonNumber = $seasonNumber.PadLeft(2, '0')
        $parentDir = Split-Path $_.Directory.Parent.FullName -Leaf
        $newName = $_.Name -replace '^\d+\s', ''
        if ($TwoPerFile) {
            $newName = "$parentDir.s$seasonNumber" + "e$episodeNumber-e$episodeNumber2.$($newName)"
        } else {
            $newName = "$parentDir.s$seasonNumber" + "e$episodeNumber.$($newName)"
        }
        $newName = Join-Path -Path $_.Directory.FullName -ChildPath $newName

        Write-Host "Renaming '$($_.Name)' to '$newName'"
        Rename-Item -WhatIf:$WhatIf -Path $_.FullName -NewName $newName
    }
    $fileCount++
}