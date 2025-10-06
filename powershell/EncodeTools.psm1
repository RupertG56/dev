# File: EncodeTools.psm1
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
