# File: EncodeTools.psm1
function Convert-VideoFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$File,

        [ValidateSet('aac', 'eac3')]
        [string]$Codec = 'aac'
    )

    begin {
        switch ($Codec) {
            'aac' { $AudioArgs = "-c:a aac -b:a 128k" }
            'eac3' { $AudioArgs = "-c:a eac3 -b:a 192k" }
        }
    }

    process {
        try {
            $VideoCodec = & ffprobe -v error -select_streams v:0 `
                -show_entries stream=codec_name `
                -of default=noprint_wrappers=1:nokey=1 "$File" 2>$null

            if ($VideoCodec -eq 'hevc') {
                Write-Verbose "Skipping: $File ($VideoCodec)"
                return
            }

            $TmpFile = [System.IO.Path]::ChangeExtension($File, '.tmp.mkv')
            $OutFile = [System.IO.Path]::ChangeExtension($File, '.mkv')
            $Cmd = "ffmpeg -hide_banner -nostdin -y -i `"$File`" -map 0 -c:v libx265 -preset medium -crf 28 $AudioArgs -c:s srt -metadata:s:s:0 language=eng `"$TmpFile`""

            if ($PSCmdlet.ShouldProcess($File, "Encode to $OutFile")) {
                Write-Host "Encoding: $File"
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $Cmd" -Wait -NoNewWindow -PassThru
                if ($process.ExitCode -eq 0) {
                    Move-Item -Force $TmpFile $OutFile
                }
                else {
                    Remove-Item -ErrorAction SilentlyContinue $TmpFile
                    Write-Warning "Failed: $File"
                }
            }
        }
        catch {
            Write-Warning "FAIL: $File ($($_.Exception.Message))"
        }
    }
}

Export-ModuleMember -Function Convert-VideoFile
