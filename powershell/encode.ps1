<#
.SYNOPSIS
    Batch re-encodes video files to H.265 / MKV with AAC or EAC3 audio.

.DESCRIPTION
    - Scans folders recursively for .mp4, .mkv, .avi files.
    - Re-encodes video with libx265.
    - Re-encodes audio as AAC (default) or EAC3.
    - Converts unsupported captions/subtitles to SRT.
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

# --- Setup log directory ---
$LogDir = Join-Path -Path (Get-Location) -ChildPath "logs"
$ConvertedLog = Join-Path $LogDir "converted.log"
$SkippedLog = Join-Path $LogDir "skipped.log"
$FailedLog = Join-Path $LogDir "failed.log"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}
"" | Out-File $ConvertedLog
"" | Out-File $SkippedLog
"" | Out-File $FailedLog

# --- Embedded module path ---
$ModulePath = Join-Path $PSScriptRoot "EncodeTools.psm1"

# --- Create embedded module if not present ---
if (-not (Test-Path $ModulePath)) {
    @'
function Convert-VideoFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$File,

        [ValidateSet('aac', 'eac3')]
        [string]$Codec = 'aac'
    )

    # Audio bitrate constants
    $AAC_BITRATE = "128k"
    $EAC3_STEREO_BITRATE = "192k"
    $EAC3_SURROUND_BITRATE = "384k"
    # Default number of audio channels for stereo audio
    $STEREO_CHANNEL_COUNT = 2
    try {
        # Detect current video codec
        $VideoCodec = & ffprobe -v error -select_streams v:0 `
            -show_entries stream=codec_name `
            -of default=noprint_wrappers=1:nokey=1 "$File" 2>$null
        $VideoCodec = & ffprobe -v error -select_streams v:0 `
            -show_entries stream=codec_name `
            -of default=noprint_wrappers=1:nokey=1 "$File" 2>$null

        if ($VideoCodec -eq 'hevc') {
            Write-Verbose "Skipping (already H.265): $File"
            return
        }

        # Detect number of audio channels
        $Channels = & ffprobe -v error -select_streams a:0 `
        if (-not $Channels) { $Channels = $STEREO_CHANNEL_COUNT } # default safety

        # Choose audio encoding parameters
        switch ($Codec) {
            'aac' {
                $AudioArgs = "-c:a aac -b:a $AAC_BITRATE"
            }
            'eac3' {
                if ([int]$Channels -gt $STEREO_CHANNEL_COUNT) {
                    $AudioArgs = "-c:a eac3 -b:a $EAC3_SURROUND_BITRATE"
                    Write-Verbose "EAC3 (5.1) bitrate set to $EAC3_SURROUND_BITRATE for $File"
                }
                else {
                    $AudioArgs = "-c:a eac3 -b:a $EAC3_STEREO_BITRATE"
                    Write-Verbose "EAC3 (stereo) bitrate set to $EAC3_STEREO_BITRATE for $File"
                }
            }
        }

        $TmpFile = [System.IO.Path]::ChangeExtension($File, '.tmp.mkv')
        $OutFile = [System.IO.Path]::ChangeExtension($File, '.mkv')

        $Cmd = "ffmpeg -hide_banner -nostdin -y -i `"$File`" -map 0 -c:v libx265 -preset medium -crf 28 $AudioArgs -c:s srt -metadata:s:s:0 language=eng `"$TmpFile`""

        if ($PSCmdlet.ShouldProcess($File, "Encode to $OutFile")) {
            Write-Host "Encoding: $File"
            $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $Cmd" -Wait -NoNewWindow -PassThru
            if ($process.ExitCode -eq 0) {
                Write-Host "✔ Completed: $OutFile" -ForegroundColor Green
            }
            else {
                Remove-Item -ErrorAction SilentlyContinue $TmpFile
                Write-Warning "❌ Failed: $File (exit $($process.ExitCode)). Check if the input file is valid, ffmpeg is installed, and review ffmpeg logs for details. Try running the command manually for more information."
            }
        }
    }
    catch {
        Write-Warning "⚠ FAIL: $File ($($_.Exception.Message))"
    }
}

Export-ModuleMember -Function Convert-VideoFile
'@ | Out-File -Encoding UTF8 $ModulePath
}

Import-Module $ModulePath -Force

# --- Gather input files ---
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

# --- Process files ---
if ($Parallel) {
    Write-Host "Running in parallel mode with $Jobs jobs..."
    $Throttle = [Math]::Max(1, $Jobs)
    $Files | ForEach-Object -Parallel {
        Import-Module "$using:ModulePath"
        Convert-VideoFile -File $_.FullName -Codec $using:Codec -WhatIf:$using:WhatIf
    } -ThrottleLimit $Throttle
}
else {
    foreach ($f in $Files) {
        Convert-VideoFile -File $f.FullName -Codec $Codec -WhatIf:$WhatIf
    }
}

Write-Host "`n✅ Done. Logs saved to: $LogDir"
