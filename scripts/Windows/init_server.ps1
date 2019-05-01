# Disable UAC

Write-Host "Disabling UAC"
Write-Host "============="

Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value "0"

Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green  


# Set PowerShell execution policy to unrestricted

Write-Host "Changing PS execution policy to Unrestricted"
Write-Host "============================================"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -ErrorAction Ignore
Write-Host "PS policy updated"


# Disable Server Manager auto-start

Write-Host "Disabling Server Manager auto-start"
Write-Host "==================================="

$serverManagerMachineKey = "HKLM:\SOFTWARE\Microsoft\ServerManager"
$serverManagerUserKey = "HKCU:\SOFTWARE\Microsoft\ServerManager"
if(Test-Path $serverManagerMachineKey) {
    Set-ItemProperty -Path $serverManagerMachineKey -Name "DoNotOpenServerManagerAtLogon" -Value 1
    Write-Host "Disabled Server Manager at logon for all users" -ForegroundColor Green
}
if(Test-Path $serverManagerUserKey) {
    Set-ItemProperty -Path $serverManagerUserKey -Name "CheckedUnattendLaunchSetting" -Value 0
    Write-Host "Disabled Server Manager for current user" -ForegroundColor Green
}


# Disable WER

Write-Host "Disabling Windows Error Reporting (WER)"
Write-Host "======================================="

$werKey = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
Set-ItemProperty $werKey -Name "ForceQueue" -Value 1

if(Test-Path "$werKey\Consent") {
    Set-ItemProperty "$werKey\Consent" -Name "DefaultConsent" -Value 1
}
Write-Host "Windows Error Reporting (WER) dialog has been disabled." -ForegroundColor Green  


# Disable IE ESC and Welcome Screen

Write-Host "Disabling Internet Explorer ESC"
Write-Host "==============================="

$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
if((Test-Path $AdminKey) -or (Test-Path $UserKey)) {
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer -ErrorAction SilentlyContinue
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

Write-Host "Disabling Internet Explorer Welcome Screen"
Write-Host "=========================================="

$AdminKey = "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main"
New-Item -Path $AdminKey -Value 1 -Force
Set-ItemProperty -Path $AdminKey -Name "DisableFirstRunCustomize" -Value 1 -Force
Write-Host "Disabled IE Welcome screen" -ForegroundColor Green


# Disable Antivirus

Write-Host "Disabling Antivirus"
Write-Host "==================="

Set-MpPreference -DisableRealtimeMonitoring $true


# Disable Windows Update

Write-Host "Disabling Windows Updates"
Write-Host "========================="

$AutoUpdatePath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
If (Test-Path -Path $AutoUpdatePath) {
    Set-ItemProperty -Path $AutoUpdatePath -Name NoAutoUpdate -Value 1
    Write-Host "Disabled Windows Update"
}
else {
    Write-Host "Windows Update key does not exist"
}

# Allow connecting to any host via WinRM

Write-Host "WinRM - allow * hosts"
Write-Host "====================="

cmd /c 'winrm set winrm/config/client @{TrustedHosts="*"}'
Write-Host "WinRM configured"

# Disable new network location wizard

Write-Host "Disabling new network location wizard"
Write-Host "====================================="

reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff /f
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Network\NetworkLocationWizard /v HideWizard /t REG_DWORD /d 1 /f

Write-Host "Netwotk location wizard disabled"

# .NET 3.5

Write-Host "Installing .NET 3.5"
Write-Host "==================="

Install-WindowsFeature NET-Framework-Core
Write-Host ".NET 3.5 installed"