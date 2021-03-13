. "$PSScriptRoot\common.ps1"

Write-Host "Cleaning up Windows..." -ForegroundColor Cyan

DisplayDiskInfo

<#
Write-Host "Running Cleanup Manager..."
$strKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
$strValueName = "StateFlags0065"

$subkeys = gci -Path "HKLM:\$strKeyPath" -Name
ForEach ($subkey in $subkeys) {
    New-ItemProperty -Path "HKLM:\$strKeyPath\$subkey" -Name $strValueName -PropertyType DWord -Value 2 -ErrorAction SilentlyContinue | Out-Null
}

Start-Process cleanmgr -ArgumentList "/sagerun:65" -Wait -NoNewWindow -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

ForEach ($subkey in $subkeys) {
    Remove-ItemProperty -Path "HKLM:\$strKeyPath\$subkey" -Name $strValueName | Out-Null
}
#>

###

Write-Host "Deleting the contents of windows software distribution..."
Get-ChildItem "$env:SystemRoot\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue | remove-item -force -recurse -ErrorAction SilentlyContinue

Write-Host "Deleting the contents of the Windows Temp folder..."
Get-ChildItem "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue `
    | remove-item -force -recurse -ErrorAction SilentlyContinue

Write-Host "Deleting all files and folders in user's Temp folder..."
Get-ChildItem "$env:SystemDrive\Users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue `
    | remove-item -force -recurse -ErrorAction SilentlyContinue

Write-Host "Removing all files and folders in user's Temporary Internet Files..." 
Get-ChildItem "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Recurse -Force -ErrorAction SilentlyContinue `
    | remove-item -force -recurse -ErrorAction SilentlyContinue

Write-Host "Cleaning up user's Downloads..."
Get-ChildItem "$env:SystemDrive\Users\*\Downloads\*" -Recurse -Force -ErrorAction SilentlyContinue `
    | remove-item -force -recurse -ErrorAction SilentlyContinue

Write-Host "Removing IE history..."
cmd /c start /wait RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255

Write-Host "Removing contents of Recycle Bin..."
$objShell = New-Object -ComObject Shell.Application  
$objFolder = $objShell.Namespace(0xA)
$objFolder.items() | ForEach-Object { Remove-Item $_.path -ErrorAction Ignore -Force -Recurse }

# clear event logs
Write-Host "Clearing Event Logs..."
Clear-EventLog -LogName Application
Clear-EventLog -LogName Security
Clear-EventLog -LogName System
Clear-EventLog -LogName AppVeyor

# Cleanup NuGet cache
# Write-Host "Deleting NuGet cache..."
# if (Test-Path "$env:USERPROFILE\.nuget\packages") {
#     Remove-Item "$env:USERPROFILE.nuget\packages" -Force -Recurse
# }

# clean /etc/hosts
$etcHosts = "$env:windir\System32\drivers\etc\hosts"
$filteredLines = (Get-Content $etcHosts | Where-Object {($_ -notmatch 'host.docker.internal') -and ($_ -notmatch 'gateway.docker.internal') })
Set-Content $etcHosts -Value $filteredLines
Get-Content $etcHosts

DisplayDiskInfo

Write-Host "Done cleaning up Windows" -ForegroundColor Green