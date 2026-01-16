Write-Host "Installing AWS CLI..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\AWSCLIV2.msi"
(New-Object Net.WebClient).DownloadFile('https://awscli.amazonaws.com/AWSCLIV2.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet
Remove-Item $msiPath

Add-SessionPath "$env:ProgramFiles\Amazon\AWSCLI"
Add-Path "$env:ProgramFiles\Amazon\AWSCLI"

# checking installation
# aws --version

Write-Host "AWS CLI installed" -ForegroundColor Green
