# RenameMedia.ps1
# Renames files that start with a padded number and space (e.g., "001 File.txt" -> "File.txt")
param(
    [string]$Path = "."
)

Set-Location -Path $Path
Get-ChildItem -Recurse -File | Where-Object {
    $_.Name -match '^\d+\s'
} | ForEach-Object {
    $newName = $_.Name -replace '^\d+\s', ''
    Rename-Item -Path $_.FullName -NewName $newName
}