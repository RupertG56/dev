$DriveLetter = "Z"
$NetworkPath = "\\192.168.1.2\nas"
$SecretName = "samba"
$secret = Get-Secret -Name $SecretName -ErrorAction SilentlyContinue
$credential = $null

# Retrieve credential from Windows Credential Manager
if ($secret) {
    $credential = New-Object System.Management.Automation.PSCredential ($SecretName, $secret)
}

if ($credential) {
    # Check if the drive is already mapped
    if (Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue) {
        Write-Host "Drive ${DriveLetter}: is currently mounted. Unmounting..."
        # Disconnect the mapped network drive
        Remove-PSDrive -Name $DriveLetter -Force
    }
    else {
        Write-Host "Drive ${DriveLetter}: is not mounted. Mounting to $NetworkPath..."
        # Mount the network drive with Persist to ensure it shows in File Explorer
        New-PSDrive -Name $DriveLetter -PSProvider FileSystem -Root $NetworkPath -Persist -Scope Global -Credential $credential
    }
}