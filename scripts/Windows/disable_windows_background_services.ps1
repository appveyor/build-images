# Local Group Policies
Write-Host "Modifying Local Group Policies"

New-Item -Path 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry -Value 0

New-Item -Path 'HKLM:\Software\Policies\Microsoft\FindMyDevice' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\FindMyDevice' -Name AllowFindMyDevice -Value 0

New-Item -Path 'HKLM:\Software\Policies\Microsoft\Windows\Windows Search' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\Windows Search' -Name AllowCortana -Value 0

New-Item -Path 'HKLM:\Software\Policies\Microsoft\Windows Defender' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware -Value 1
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows Defender' -Name ServiceKeepAlive -Value 0

New-Item -Path 'HKLM:\Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\MicrosoftEdge\PhishingFilter' -Name EnabledV9 -Value 0

New-Item -Path 'HKLM:\Software\Policies\Microsoft\Windows\System' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\System' -Name EnableSmartScreen -Value 0

New-Item -Path 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name NoAutoUpdate -Value 1


# Disable scheduled tasks
#Get-ScheduledTask -TaskName 'packer-*' | Unregister-ScheduledTask -Confirm:$false
Get-ScheduledTask -TaskPath '\Microsoft\VisualStudio\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Application Experience\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Customer Experience Improvement Program\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\.NET Framework\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Chkdsk\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Data Integrity Scan\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Diagnosis\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\DiskCleanup\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\DiskDiagnostic\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\DiskFootprint\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Maintenance\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Power Efficiency Diagnostics\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Server Manager\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Servicing\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Speech\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Error Reporting\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\WindowsColorSystem\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }
Get-ScheduledTask -TaskPath '\Microsoft\Windows\WindowsUpdate\*' | Disable-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $_.URI }

# Windows services
Write-Host "Disable unnecessary Windows services"

Set-Service diagtrack -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service vmicvss -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service VSS -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service winrm -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service UsoSvc -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service DPS -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service spooler -StartupType Disabled -ErrorAction SilentlyContinue


Set-Service IpOverUsbSvc -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service gupdate -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service gupdatem -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service SQLWriter -StartupType Manual -ErrorAction SilentlyContinue
Set-Service 'Bonjour Service' -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service PcaSvc -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service GoogleVssProvider -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service GoogleVssAgent -StartupType Disabled -ErrorAction SilentlyContinue
