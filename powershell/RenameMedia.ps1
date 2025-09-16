# RenameMedia.ps1
# Renames files that start with a padded number and space (e.g., "001 File.txt" -> "File.txt")
# VS Code launch.json example for debugging this script:
# Place this in a .vscode/launch.json file in your project directory.

# {
#     "version": "0.2.0",
#     "configurations": [
#         {
#             "type": "PowerShell",
#             "request": "launch",
#             "name": "Debug RenameMedia.ps1",
#             "script": "${workspaceFolder}/RenameMedia.ps1",
#             "args": [
#                 "-Path", ".",
#                 "-Complex", "false",
#                 "-BeginWithTemplate", "",
#                 "-DryRun", "true"
#             ]
#         }
#     ]
# }
param(
    [string]$Path = ".",
    [string]$BeginWithTemplate = "",
    [switch]$Complex = $false,
    [switch]$DryRun = $false
)


Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
    if ($Complex) {
        $seasonMatch = [regex]::Match($_.Name, 'Season\s(\d+)', 'IgnoreCase')
        $episodeMatch = [regex]::Match($_.Name, 'Episode\s(\d+)', 'IgnoreCase')
        $seasonNumber = if ($seasonMatch.Success) { $seasonMatch.Groups[1].Value } else { $null }
        $episodeNumber = if ($episodeMatch.Success) { $episodeMatch.Groups[1].Value } else { $null }
        
        if ($seasonNumber -and $episodeNumber) {
            $seasonNumber = $seasonNumber.PadLeft(2, '0')
            $episodeNumber = $episodeNumber.PadLeft(2, '0')
            $newName = "$BeginWithTemplate.s$seasonNumber" + "e$episodeNumber" + [System.IO.Path]::GetExtension($_.Name)
            if ($DryRun) {
                Rename-Item -Path $_.FullName -NewName $newName -WhatIf
            }
            else {
                Write-Host "Renaming '$($_.Name)' to '$newName'"
                Rename-Item -Path $_.FullName -NewName $newName
            }
        }
        return
    } else {
        $episodeMatch = [regex]::Match($_.Name, '^\d+\s', 'IgnoreCase')
        $episodeNumber = if ($episodeMatch.Success) { $episodeMatch.Value.Trim() } else { $null }
        $episodeNumber = $episodeNumber.PadLeft(2, '0')
        $seasonMatch = [regex]::Match($_.Directory.Name, '(\d+)', 'IgnoreCase')
        $seasonNumber = if ($seasonMatch.Success) { $seasonMatch.Groups[1].Value } else { $null }
        $seasonNumber = $seasonNumber.PadLeft(2, '0')
        $parentDir = Split-Path $_.Directory.Parent.FullName -Leaf
        $newName = $_.Name -replace '^\d+\s', ''
        $newName = Join-Path -Path $_.Directory.FullName -ChildPath ("$parentDir.s$seasonNumber" + "e$episodeNumber.$($newName)")

        if ($DryRun) {
            Rename-Item -Path $_.FullName -NewName $newName -WhatIf
        }
        else {
            Write-Host "Renaming '$($_.Name)' to '$newName'"
            Rename-Item -Path $_.FullName -NewName $newName
        }
    }
}