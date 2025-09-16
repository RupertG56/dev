param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [switch]$dryRun = $false
)

# Get all files in the specified path
$files = Get-ChildItem -Path $Path -File

# Regex to match s\d+ (e.g., s01, s2)
$seasonRegex = [regex]'s(\d+)'

foreach ($file in $files) {
    $match = $seasonRegex.Match($file.Name)
    if ($match.Success) {
        $seasonNumber = [int]$match.Groups[1].Value
        $seasonFolder = "Season $($seasonNumber.ToString("D2"))"
        $seasonFolderPath = Join-Path $Path $seasonFolder

        # Create the season folder if it doesn't exist
        if (-not (Test-Path $seasonFolderPath)) {
            if ($dryRun) {
                New-Item -Path $seasonFolderPath -ItemType Directory -WhatIf | Out-Null
            } else {
                Write-Output "Creating folder: $seasonFolderPath"
                New-Item -Path $seasonFolderPath -ItemType Directory | Out-Null
            }
        }

        # Move the file into the season folder
        if ($dryRun) {
            Move-Item -Path $file.FullName -Destination $seasonFolderPath -WhatIf
        } else {
            Write-Output "Moving file '$($file.Name)' to '$seasonFolder'"
            Move-Item -Path $file.FullName -Destination $seasonFolderPath
        }
    }
}