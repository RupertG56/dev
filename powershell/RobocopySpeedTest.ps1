# Define source and destination
$Source = "C:\Users\rjone\DRmare\Burn Notice The Fall of Sam Axe"
$Destination = "Z:\plexmedia\movies\"
$LogFile = "Z:\dump\robocopy.log"

# Start a timer
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Run robocopy with logging
$rcArgs = @(
    $Source
    $Destination
    "/E"              # Don't mirror, just copy all subdirs
    "/MT:16"            # Multithreading
    "/R:1"              # Retry once on failure
    "/W:1"              # Wait 1 second between retries
    "/NP"               # No progress (cleaner output)
    "/TEE"              # Output to console and log
    "/LOG:$LogFile"     # Write log file
)

& robocopy @rcArgs

# Stop timer
$Stopwatch.Stop()

# Parse robocopy log for bytes copied
$BytesCopied = Select-String -Path $LogFile -Pattern "Bytes :\s+(\d+)" |
ForEach-Object { [int64]($_.Matches[0].Groups[1].Value) } |
Measure-Object -Sum | Select-Object -ExpandProperty Sum

# Calculate throughput
$Seconds = $Stopwatch.Elapsed.TotalSeconds
$MB = [math]::Round($BytesCopied / 1MB, 2)
$MBps = [math]::Round($MB / $Seconds, 2)

Write-Host "`n========== Copy Summary ==========" -ForegroundColor Cyan
Write-Host "Copied: $MB MB"
Write-Host "Time:   $Seconds seconds"
Write-Host "Speed:  $MBps MB/s"
Write-Host "==================================`n" -ForegroundColor Cyan
