# Recursively read all files from a root directory in PowerShell

param(
    [string]$RootDir = ".",
    [string]$searchExtension = "*.mb4",
    [string]$newExtension = ".m4b"
)

# $SourceDir = $RootDir
Get-ChildItem -Path $RootDir -Recurse -File -Filter $searchExtension | ForEach-Object {
    $file = $_
    $destFile = [System.IO.Path]::ChangeExtension($file.FullName, $newExtension)
    Write-Output $file.FullName
    Write-Output $destFile
    if (-Not (Test-Path $destFile)) {
        Rename-Item -Path $file.FullName -NewName $destFile
    } else {
        Write-Output "File $destFile already exists, skipping rename."
    }
}