<#
.SYNOPSIS
    Batch re-encodes video files to H.265 / MKV with AAC or EAC3 audio.

.DESCRIPTION
    - Scans folders recursively for .mp4, .mkv, .avi files.
    - Re-encodes video with libx265.
    - Re-encodes audio as AAC (default) or EAC3.
    - Keeps subtitles intact.
    - Outputs new .mkv files beside originals.
    - Supports parallel jobs and WhatIf mode.
    - Logs all actions in a "logs" subfolder.
#>

param (
    [Parameter(Mandatory, Position = 0)]
    [string[]]$Path,

    [ValidateSet('aac', 'eac3')]
    [string]$Codec = 'aac',

    [switch]$Parallel,

    [int]$Jobs = [Environment]::ProcessorCount,

    [switch]$WhatIf
)

$LogDir = Join-Path -Path (Get-Location) -ChildPath "logs"
$ConvertedLog = Join-Path $LogDir "converted.log"
$SkippedLog   = Join-Path $LogDir "skipped.log"
$FailedLog    = Join-Path $LogDir "failed.log"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

"" | Out-File $ConvertedLog
"" | Out-File $SkippedLog
"" | Out-File $FailedLog

switch ($Codec) {
    'aac'  { $AudioArgs = "-c:a aac -b:a 128k" }
    'eac3' { $AudioArgs = "-c:a eac3 -b:a 192k" }
}

# Save this function in its own file, e.g., Convert-VideoFile.ps1

. ".\Convert-VideoFile.ps1"

$Extensions = @("*.mp4", "*.mkv", "*.avi")
$Files = @()
foreach ($p in $Path) {
    foreach ($ext in $Extensions) {
        $Files += Get-ChildItem -Path $p -Recurse -Include $ext -File -ErrorAction SilentlyContinue
    }
}

if (-not $Files) {
    Write-Warning "No matching video files found."
    exit
}

if ($Parallel) {
    Write-Host "Running in parallel mode with $Jobs jobs..."
    $Throttle = [Math]::Max(1, $Jobs)
    $Files | ForEach-Object -Parallel {
        . ".\Convert-VideoFile.ps1"
        Convert-VideoFile $_.FullName
    } -ThrottleLimit $Throttle
}
else {
    foreach ($f in $Files) {
        Convert-VideoFile $f.FullName
    }
}

Write-Host "`n✅ Done. Logs saved to: $LogDir"
