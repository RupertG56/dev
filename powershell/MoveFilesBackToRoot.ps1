param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

# Get all files recursively
Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
    $destination = Join-Path -Path $Path -ChildPath $_.Name
    if (-not (Test-Path $destination)) {
        Move-Item -Path $_.FullName -Destination $destination
    } else {
        # If file exists, generate a unique name
        $uniqueName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name) + "_$([guid]::NewGuid().ToString().Substring(0,8))" + $_.Extension
        $destination = Join-Path -Path $Path -ChildPath $uniqueName
        Move-Item -Path $_.FullName -Destination $destination
    }
}

# Remove all subdirectories
Get-ChildItem -Path $Path -Recurse -Directory | Sort-Object -Property FullName -Descending | ForEach-Object {
    Remove-Item -Path $_.FullName -Force -Recurse
}