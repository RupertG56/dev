# --- Embedded module path ---
$ModulePath = Join-Path $PSScriptRoot "EncodeTools.psm1"
Import-Module $ModulePath -Force
$Files = Get-ChildItem -Recurse -Include *.mp4, *.mkv, *.avi

foreach ($File in $Files) {
    $File | Export-Mp4ToMkv 
}