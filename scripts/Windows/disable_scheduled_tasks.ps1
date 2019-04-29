Write-Host "Unregister unnecessary tasks"

Get-ScheduledTask | Where-Object {$_.TaskName -like "packer-*"} `
    | Foreach-Object { Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false }

Write-Host "Disabling unnecessary scheduled tasks..." -ForegroundColor Cyan

Disable-ScheduledTask -TaskName GoogleUpdateTaskMachineCore
Disable-ScheduledTask -TaskName GoogleUpdateTaskMachineUA
Disable-ScheduledTask -TaskName 'User_Feed_Synchronization-{7976E8A0-BFFF-474E-8112-C8CF337491B5}'

Disable-ScheduledTask -TaskPath '\Microsoft\VisualStudio' -TaskName 'VSIX Auto Update 14'
Disable-ScheduledTask -TaskPath '\Microsoft\VisualStudio' -TaskName 'VSIX Auto Update 15.0.26323.1'
Disable-ScheduledTask -TaskPath '\Microsoft\VisualStudio' -TaskName 'VSIX Auto Update 15.0.26430.4'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\.NET Framework' -TaskName '.NET Framework NGEN v4.0.30319'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\.NET Framework' -TaskName '.NET Framework NGEN v4.0.30319 64'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\.NET Framework' -TaskName '.NET Framework NGEN v4.0.30319 64 Critical'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\.NET Framework' -TaskName '.NET Framework NGEN v4.0.30319 Critical'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Active Directory Rights Management Services Client' `
    -TaskName 'AD RMS Rights Policy Template Management (Automated)'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Active Directory Rights Management Services Client' `
    -TaskName 'AD RMS Rights Policy Template Management (Manual)'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\AppID' -TaskName 'SmartScreenSpecific'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Application Experience' -TaskName 'Microsoft Compatibility Appraiser' 
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Application Experience' -TaskName 'ProgramDataUpdater'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Application Experience' -TaskName 'StartupAppTask'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\ApplicationData' -TaskName 'appuriverifierdaily'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\ApplicationData' -TaskName 'appuriverifierinstall'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\ApplicationData' -TaskName 'CleanupTemporaryState'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\ApplicationData' -TaskName 'DsSvcCleanup'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\DiskDiagnostic' -TaskName 'Microsoft-Windows-DiskDiagnosticResolver'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\DiskDiagnostic' -TaskName 'Microsoft-Windows-DiskDiagnosticDataCollector'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\DiskFootprint' -TaskName 'Diagnostics'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\DiskFootprint' -TaskName 'StorageSense'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\DiskCleanup' -TaskName SilentCleanup
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Diagnosis' -TaskName Scheduled
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag' -TaskName ScheduledDefrag
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Data Integrity Scan' -TaskName 'Data Integrity Scan'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Data Integrity Scan' -TaskName 'Data Integrity Scan for Crash Recovery'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Device Information' -TaskName 'Device'
# Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Device Setup' -TaskName 'Metadata Refresh' # Access denied

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Customer Experience Improvement Program' -TaskName Consolidator
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Customer Experience Improvement Program' -TaskName KernelCeipTask
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Customer Experience Improvement Program' -TaskName UsbCeip
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Chkdsk' -TaskName ProactiveScan
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Autochk' -TaskName Proxy

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\LanguageComponentsInstaller' -TaskName 'Installation'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Maintenance' -TaskName 'WinSAT'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Maps' -TaskName 'MapsToastTask'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\MUI' -TaskName 'LPRemove'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Power Efficiency Diagnostics' -TaskName 'AnalyzeSystem'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Servicing' -TaskName 'StartComponentCleanup'

# Disable-ScheduledTask -TaskPath '\Microsoft\Windows\SettingSync' -TaskName 'BackgroundUploadTask' # Access denied
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\SettingSync' -TaskName 'BackupTask'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\SettingSync' -TaskName 'NetworkStateChangeTask'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Speech' -TaskName 'SpeechModelDownloadTask'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\UpdateOrchestrator' -TaskName 'Refresh Settings'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\UpdateOrchestrator' -TaskName 'Schedule Scan'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\User Profile Service' -TaskName 'HiveUploadTask'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Defender' -TaskName 'Windows Defender Cache Maintenance'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Defender' -TaskName 'Windows Defender Cleanup'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Defender' -TaskName 'Windows Defender Scheduled Scan'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Defender' -TaskName 'Windows Defender Verification'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Windows Error Reporting' -TaskName 'QueueReporting'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Server Manager' -TaskName 'CleanupOldPerfLogs'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Server Manager' -TaskName 'ServerManager'

Disable-ScheduledTask -TaskPath '\Microsoft\Windows\WindowsUpdate' -TaskName 'Automatic App Update'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\WindowsUpdate' -TaskName 'sih'

Disable-ScheduledTask -TaskPath '\Microsoft\XblGameSave' -TaskName 'XblGameSaveTask'
Disable-ScheduledTask -TaskPath '\Microsoft\XblGameSave' -TaskName 'XblGameSaveTaskLogon'

Disable-ScheduledTask -TaskPath '\MySQL\Installer' -TaskName 'ManifestUpdate'

# These two tasks are responsible for search capability in Windows Start Menu
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\TextServicesFramework' -TaskName 'MsCtfMonitor'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Wininet' -TaskName 'CacheTask'
#####

Write-Host "Disabled scheduled tasks" -ForegroundColor Green