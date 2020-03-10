# Input variables
# $build_agent_mode = "..."
# $appveyor_user = "..."
# $appveyor_password = "..."
# $appveyor_url = "..."
# $appveyor_workerId = "..."

Start-Transcript -path $env:WINDIR\TEMP\appveyor-bootstrap.log -append

# Disable UAC

Write-Host "Disabling UAC"
Write-Host "============="

Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value "0"

Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green  

# Set PowerShell execution policy to unrestricted

Write-Host "Changing PS execution policy to Unrestricted"
Write-Host "============================================"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -ErrorAction Ignore -Scope Process
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

Write-Host "Creating AppVeyor user"
Write-Host "======================"

function CreateUser {
    if ($appveyor_password) {
        # password specified
        cmd /c net user $appveyor_user $appveyor_password /add /passwordchg:no /passwordreq:yes /active:yes /Y
    } else {
        # random password
        cmd /c net user $appveyor_user /add /active:yes /Y
    }
    cmd /c net localgroup Administrators $appveyor_user /add
    cmd /c 'winrm set winrm/config/service/auth @{Basic="true"}'
}

if ($build_agent_mode -ne 'Azure') {
	while (-not (Get-LocalUser -Name $appveyor_user -ErrorAction Ignore) -and $count -lt 3) {
	    CreateUser
	    Start-Sleep -s 1
	    $count++
	}
	if (-not (Get-LocalUser -Name $appveyor_user -ErrorAction Ignore)) { throw "Unable to create user '$appveyor_user'" }
}

Set-LocalUser -Name $appveyor_user -Password (ConvertTo-SecureString -AsPlainText $appveyor_password -Force) -PasswordNeverExpires:$true

Write-Host "User created"

Write-Host "Enabling Windows auto-logon"
Write-Host "==========================="

Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -ErrorAction SilentlyContinue
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -PropertyType String -Value 1 | Out-Null

Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUsername -ErrorAction SilentlyContinue
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUsername -PropertyType String -Value $appveyor_user | Out-Null

Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -ErrorAction SilentlyContinue
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -PropertyType String -Value $appveyor_password | Out-Null

# https://docs.microsoft.com/en-us/windows/desktop/SecAuthN/msgina-dll-features
Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoLogonCount -ErrorAction SilentlyContinue

Write-Host "Autologon enabled"


Write-Host "Installing AppVeyor Build Agent"
Write-Host "==============================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$destPath = "$env:ProgramFiles\AppVeyor\BuildAgent"

$versionFeedUrl = 'https://appveyordownloads.blob.core.windows.net/build-agent/appveyor-build-agent-windows-version-6.0.txt'

if ($env:build_agent_version_feed_url) {
    $versionFeedUrl = $env:build_agent_version_feed_url
}

Write-Host "Querying for the latest version of Build Agent from $versionFeedUrl"
$versionInfo = (New-Object Net.WebClient).DownloadString($versionFeedUrl).split(' ')
Write-Host "Installing Build Agent version $($versionInfo[0])"

Write-Host "Downloading..."
$zipPath = "$env:TEMP\appveyor-build-agent.zip"
(New-Object Net.WebClient).DownloadFile($versionInfo[1], $zipPath)

Write-Host "Unpacking..."
Expand-Archive -LiteralPath $zipPath -DestinationPath $destPath | Out-Null

Remove-Item $zipPath -Force

# Add build agent settings
New-Item "HKLM:\Software\AppVeyor" -Name "Build Agent" -Force | Out-Null
Set-ItemProperty "HKLM:\Software\AppVeyor\Build Agent" -Name "Mode" -Value $build_agent_mode

# Enable auto load on system start
Set-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "AppVeyor.BuildAgent" `
	-Value "powershell -File `"$destPath\update-appveyor-agent.ps1`""

# Make PS modules visible to external PS sessions
$AppVeyorModulesPath = "$destPath\Modules"
$PSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
if(-not $PSModulePath.contains($AppVeyorModulesPath)) {
    [Environment]::SetEnvironmentVariable('PSModulePath', "$PSModulePath;$AppVeyorModulesPath", 'Machine')
}

Write-Host "AppVeyor Build Agent installed" -ForegroundColor Green

if ($build_agent_mode -eq 'Azure' -and $appveyor_url -and $appveyor_workerId) {
    Set-ItemProperty "HKLM:\Software\AppVeyor\Build Agent" -Name "AppVeyorUrl" -Value $appveyor_url
    Set-ItemProperty "HKLM:\Software\AppVeyor\Build Agent" -Name "WorkerId" -Value $appveyor_workerId
}

Stop-Transcript -ErrorAction SilentlyContinue | Out-Null

Restart-Computer