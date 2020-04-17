Write-Host "Installing Strawberry Perl 5.30..." -ForegroundColor Cyan

$msiPath = "$env:TEMP\strawberry-perl-5.30.2.1-64bit.msi"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('http://strawberryperl.com/download/5.30.2.1/strawberry-perl-5.30.2.1-64bit.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /qn /norestart
Remove-Item $msiPath

C:\Strawberry\perl\bin\perl.exe --version

Write-Host "Strawberry Perl installed" -ForegroundColor Green