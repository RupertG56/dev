# Recursively read all files from a root directory in PowerShell

param(
    [string]$RootDir = ".",
    [string]$TargetDir = "$RootDir-mp3",
    [string] $activationBytes
)

# $SourceDir = $RootDir
Get-ChildItem -Path $RootDir -Recurse -File | ForEach-Object {
    $file = $_
    $destFile = [System.IO.Path]::ChangeExtension($file.FullName, ".m4b")
    Write-Output $file.FullName
    Write-Output $destFile
    if (-Not (Test-Path $destFile)) {
        aaxclean-cli --activation_bytes $activationBytes -f $file.FullName -o $destFile
    } else {
        Write-Output "File $destFile already exists, skipping conversion."
    }
}