Write-warning "Checking if WSL feature is installed..."
$i = 0
$installed = $false
while ($i -lt 30) {
  $i +=1  
  $installed = (Get-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online).State -eq 'Enabled'
  if ($installed) {
    Write-host "WSL feature is installed"
    break
  }
  Write-warning "Retrying in 10 seconds..."
  sleep 10;
}

if (-not $installed) {
    Write-error "WSL feature is not installed"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Ubuntu 16.04
# ============

Write-warning "Installing Ubuntu 16.04 for WSL"

(New-Object Net.WebClient).DownloadFile('https://aka.ms/wsl-ubuntu-1604', "$env:TEMP\wsl-ubuntu-1604.zip")
Expand-Archive -Path "$env:TEMP\wsl-ubuntu-1604.zip" -DestinationPath "C:\WSL\Ubuntu1604" -Force
Remove-Item "$env:TEMP\wsl-ubuntu-1604.zip"


$ubuntuExe = "C:\WSL\Ubuntu1604\ubuntu1604.exe"
$bsdtar = "C:\WSL\Ubuntu1604\rootfs\bsdtar"

Start-Process $ubuntuExe
while($true) {
	Start-Sleep -s 10
	if (-not (Test-Path $bsdtar)) {
		Get-Process "ubuntu1604" | Stop-Process
		break
	}
}

. $ubuntuExe run adduser appveyor --gecos `"First,Last,RoomNumber,WorkPhone,HomePhone`" --disabled-password
. $ubuntuExe run "echo 'appveyor:Password12!' | sudo chpasswd"
. $ubuntuExe run usermod -aG sudo appveyor
. $ubuntuExe run "echo -e `"`"appveyor\tALL=(ALL)\tNOPASSWD: ALL`"`" > /etc/sudoers.d/appveyor"
. $ubuntuExe run chmod 0755 /etc/sudoers.d/appveyor
. $ubuntuExe config --default-user appveyor
. $ubuntuExe run sudo apt-get update

# Ubuntu 18.04
# ============

Write-warning "Installing Ubuntu 18.04 for WSL"

(New-Object Net.WebClient).DownloadFile('https://aka.ms/wsl-ubuntu-1804', "$env:TEMP\wsl-ubuntu-1804.zip")
Expand-Archive -Path "$env:TEMP\wsl-ubuntu-1804.zip" -DestinationPath "C:\WSL\Ubuntu1804" -Force
Remove-Item "$env:TEMP\wsl-ubuntu-1804.zip"

$ubuntuExe = "C:\WSL\Ubuntu1804\ubuntu1804.exe"
. $ubuntuExe install --root
. $ubuntuExe run adduser appveyor --gecos `"First,Last,RoomNumber,WorkPhone,HomePhone`" --disabled-password
. $ubuntuExe run "echo 'appveyor:Password12!' | sudo chpasswd"
. $ubuntuExe run usermod -aG sudo appveyor
. $ubuntuExe run "echo -e `"`"appveyor\tALL=(ALL)\tNOPASSWD: ALL`"`" > /etc/sudoers.d/appveyor"
. $ubuntuExe run chmod 0755 /etc/sudoers.d/appveyor
. $ubuntuExe config --default-user appveyor
. $ubuntuExe run sudo apt-get update

# Ubuntu 20.04
# ============

Write-warning "Installing Ubuntu 20.04 for WSL"

(New-Object Net.WebClient).DownloadFile('https://appveyordownloads.blob.core.windows.net/misc/Ubuntu_2004.2021.825.0_x64.zip', "$env:TEMP\wsl-ubuntu-2004.zip")
Expand-Archive -Path "$env:TEMP\wsl-ubuntu-2004.zip" -DestinationPath "C:\WSL\Ubuntu2004" -Force
Remove-Item "$env:TEMP\wsl-ubuntu-2004.zip"

$ubuntuExe = "C:\WSL\Ubuntu2004\ubuntu.exe"
. $ubuntuExe install --root
. $ubuntuExe run adduser appveyor --gecos `"First,Last,RoomNumber,WorkPhone,HomePhone`" --disabled-password
. $ubuntuExe run "echo 'appveyor:Password12!' | sudo chpasswd"
. $ubuntuExe run usermod -aG sudo appveyor
. $ubuntuExe run "echo -e `"`"appveyor\tALL=(ALL)\tNOPASSWD: ALL`"`" > /etc/sudoers.d/appveyor"
. $ubuntuExe run chmod 0755 /etc/sudoers.d/appveyor
. $ubuntuExe config --default-user appveyor
. $ubuntuExe run sudo apt-get update


# OpenSUSE
# ========

Write-warning "Installing OpenSUSE for WSL"

(New-Object Net.WebClient).DownloadFile('https://aka.ms/wsl-opensuse-42', "$env:TEMP\wsl-opensuse.zip")
Expand-Archive -Path "$env:TEMP\wsl-opensuse.zip" -DestinationPath "C:\WSL\OpenSUSE" -Force
Remove-Item "$env:TEMP\wsl-opensuse.zip"

$suseExe = "C:\WSL\OpenSUSE\openSUSE-42.exe"
$bsdtar = "C:\WSL\OpenSUSE\rootfs\bsdtar"

Start-Process $suseExe
while($true) {
	Start-Sleep -s 10
	if (-not (Test-Path $bsdtar)) {
		Get-Process "openSUSE-42" | Stop-Process
		break
	}
}


# Testing WSL
# ===========

wslconfig /setdefault ubuntu-16.04
wsl lsb_release -a

wslconfig /setdefault ubuntu-18.04
wsl lsb_release -a

wslconfig /setdefault ubuntu
wsl lsb_release -a

# Rename C:\Windows\System32\bash.exe to avoid conflicts with default Git's bash
# ===========

takeown /F "$env:SystemRoot\System32\bash.exe"
icacls "$env:SystemRoot\System32\bash.exe" /grant administrators:F
ren "$env:SystemRoot\System32\bash.exe" wsl-bash.exe