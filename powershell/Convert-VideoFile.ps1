function Convert-VideoFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$File
    )

    process {
        try {
            $VideoCodec = & ffprobe -v error -select_streams v:0 `
                -show_entries stream=codec_name `
                -of default=noprint_wrappers=1:nokey=1 "$File" 2>$null

            if ($VideoCodec -eq "hevc") {
                "SKIP: $File ($VideoCodec)" | Tee-Object -FilePath $SkippedLog -Append
                return
            }

            $TmpFile = [System.IO.Path]::ChangeExtension($File, ".tmp.mkv")
            $OutFile = [System.IO.Path]::ChangeExtension($File, ".mkv")

            #$Cmd = "ffmpeg -hide_banner -nostdin -y -i `"$File`" -c:v libx265 -preset medium -crf 28 $AudioArgs -c:s copy `"$TmpFile`""
            $Cmd = "ffmpeg -hide_banner -nostdin -y -i `"$File`" -map 0 -c:v libx265 -preset medium -crf 28 $AudioArgs -c:s srt -metadata:s:s:0 language=eng `"$TmpFile`""


            if ($WhatIf) {
                Write-Host "DRY-RUN: $Cmd"
                return
            }

            Write-Host "ENCODING: $File"

            $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $Cmd" -Wait -NoNewWindow -PassThru
            if ($process.ExitCode -eq 0) {
                Move-Item -Force $TmpFile $OutFile
                "OK: $OutFile" | Tee-Object -FilePath $ConvertedLog -Append
            }
            else {
                Remove-Item -ErrorAction SilentlyContinue $TmpFile
                "FAIL: $File" | Tee-Object -FilePath $FailedLog -Append
            }
        }
        catch {
            "FAIL: $File ($($_.Exception.Message))" | Tee-Object -FilePath $FailedLog -Append
        }
    }
}