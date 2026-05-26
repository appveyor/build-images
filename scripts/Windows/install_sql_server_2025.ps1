Write-Host "Downloading SQL Server 2025..."
$isoPath = "$env:TEMP\SQLServer2025-x64-ENU-EntDev.iso"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/dea8c210-c44a-4a9d-9d80-0c81578860c5/ENU/SQLServer2025-x64-ENU-EntDev.iso', $isoPath)

$extractPath = "$env:TEMP\SQLServer2025-x64-ENU-EntDev"
Write-Host "Extracting..."
7z x $isoPath -aoa -o"$extractPath" | Out-Null

Write-Host "Installing..."
cmd /c start /wait $extractPath\setup.exe /q /ACTION=Install /FEATURES=SQLEngine,FullText,Tools /INSTANCENAME=SQL2025 /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" /TCPENABLED=1 /SECURITYMODE=SQL /SAPWD=Password12! /IACCEPTSQLSERVERLICENSETERMS

Write-Host "Deleting temporary files..."
Remove-Item $isoPath -Force -ErrorAction Ignore
Remove-Item $extractPath -Recurse -Force -ErrorAction Ignore

Write-Host "SQL Server 2025 installed" -ForegroundColor Green
