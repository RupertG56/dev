param(
    [string]$Path = ".",
    [switch]$WhatIf = $false,
    [switch]$Recurse = $false
)

Write-Output "Renaming files in path: $Path"
$files = Get-ChildItem -Path $Path -Recurse:$Recurse -File
$files | ForEach-Object {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $folderPath = Join-Path -Path $_.DirectoryName -ChildPath $baseName

    # Sanity checks
    if (-not (Test-Path $folderPath)) {
        Write-Output "Creating folder: $folderPath"
        New-Item -Path $folderPath -ItemType Directory -WhatIf:$WhatIf | Out-Null
    }
    $destination = Join-Path -Path $folderPath -ChildPath $_.Name
    if (-not (Test-Path $destination)) {
        Write-Output "Moving '$($_.FullName)' to '$destination'"
        Move-Item -Path $_.FullName -Destination $destination -WhatIf:$WhatIf
    } else {
        Write-Output "Destination file '$destination' already exists. Skipping."
    }
}