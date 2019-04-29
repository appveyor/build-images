Write-Host "Setting up final docker steps to run at RunOnce"

(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/appveyor/ci/master/scripts/prepare-docker.ps1', "$env:ProgramFiles\AppVeyor\prepare-docker.ps1")

# Prepare docker on the next start
New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion" -Name "RunOnce" -Force | Out-Null

Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "!prepare-docker" `
	-Value 'powershell -File "C:\Program Files\AppVeyor\prepare-docker.ps1"'

Write-Host "Done"
