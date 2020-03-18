Write-Host "Installing AWS SDK..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\AWSToolsAndSDKForNet.msi"
(New-Object Net.WebClient).DownloadFile('http://sdk-for-net.amazonwebservices.com/latest/AWSToolsAndSDKForNet.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet
del $msiPath

# checking installation
# Get-Command Remove-EC2Instance

Write-Host "AWS SDK installed" -ForegroundColor Green