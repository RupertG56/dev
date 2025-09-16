param(
    [Parameter(Mandatory=$true)]
    [string]$RootFolder,
    [ValidateSet("MD5","SHA1","SHA256","SHA512")]
    [string]$Algorithm = "SHA256"
)

Get-ChildItem -Path $RootFolder -Recurse -File | ForEach-Object {
    $hash = Get-FileHash -Path $_.FullName -Algorithm $Algorithm
    $relativePath = Resolve-Path -Relative -Path $_.FullName
    "$($hash.Hash) *$relativePath" | Out-File -FilePath "$RootFolder\checksums.sha256" -Append -Encoding utf8
}
Write-Host "Checksums written to $RootFolder\checksums.sha256"