Write-Host "Disabling unnecessary Windows services..." -ForegroundColor Cyan

Stop-Service IpOverUsbSvc
Set-Service IpOverUsbSvc -StartupType Manual

Set-Service gupdate -StartupType Disabled
Set-Service gupdatem -StartupType Disabled

Stop-Service 'Bonjour Service'
Set-Service 'Bonjour Service' -StartupType Disabled

Stop-Service SQLWriter
Set-Service SQLWriter -StartupType Manual

Stop-Service 'Bonjour Service'
Set-Service 'Bonjour Service' -StartupType Manual

Stop-Service PcaSvc
Set-Service PcaSvc -StartupType Manual

Stop-Service Spooler
Set-Service Spooler -StartupType Manual

Stop-Service GoogleVssAgent
Set-Service GoogleVssAgent -StartupType Manual

Stop-Service GoogleVssProvider
Set-Service GoogleVssProvider -StartupType Manual

Write-Host "Disabled Windows services" -ForegroundColor Green