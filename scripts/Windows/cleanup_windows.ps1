Write-Host "Cleaning up Windows..." -ForegroundColor Cyan

function DisplayDiskInfo() {
    Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName, 
    @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } }, 
    @{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}}, 
    @{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } }, 
    @{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } |
    Format-Table -AutoSize | Out-String
}

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

# enable protected mode for all IE security zones
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1' -Name "2500" -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2' -Name "2500" -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3' -Name "2500" -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4' -Name "2500" -Value 0

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

DisplayDiskInfo

Write-Host "Done cleaning up Windows" -ForegroundColor Green