# Recursively read all files from a root directory in PowerShell

param(
    [string]$RootDir = ".",
    [string]$TargetDir = "$RootDir-mp3",
    [bool] $convertToMp3 = $true
)

$SourceDir = $RootDir

if ($convertToMp3) {
    Get-ChildItem -Path $RootDir -Recurse -File | ForEach-Object {
        $file = $_
        $destFile = [System.IO.Path]::ChangeExtension($file.FullName, ".mp3")
        Write-Output $file.FullName
        Write-Output $destFile
        if (-Not (Test-Path $destFile)) {
            ffmpeg -i $file.FullName -codec:a libmp3lame -qscale:a 2 $destFile
        } else {
            Write-Output "File $destFile already exists, skipping conversion."
        }
    }
} else {
    # Clone directory structure and copy out .mp3 files

    Get-ChildItem -Path $SourceDir -Recurse -File -Filter *.mp3 | ForEach-Object {
        $sourceFile = $_.FullName
        $relativePath = Resolve-Path $_.DirectoryName | ForEach-Object { $_.Path.Substring($SourceDir.Length).TrimStart('\','/') }
        $destDir = Join-Path $TargetDir $relativePath
        if (-Not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir | Out-Null
        }
        
        $destFile = Join-Path $destDir $_.Name
        if (-Not (Test-Path $destFile)) {
            Write-Output "Copying $sourceFile to $destFile"
            Copy-Item -Path $sourceFile -Destination $destFile -Force
        } else {
            Write-Output "File $destFile already exists, skipping copy."
        }
    }
}
