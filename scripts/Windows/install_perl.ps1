Write-Host "Installing Strawberry Perl 5.40.2.1..." -ForegroundColor Cyan

$msiPath = "$env:TEMP\strawberry-perl-5.40.2.1-64bit.msi"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_54021_64bit_UCRT/strawberry-perl-5.40.2.1-64bit.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /qn /norestart
Remove-Item $msiPath

Remove-Path 'C:\Strawberry\c\bin'
Remove-Path 'C:\Strawberry\perl\bin'
Remove-Path 'C:\Strawberry\perl\site\bin'

C:\Strawberry\perl\bin\perl.exe --version

Write-Host "Strawberry Perl installed" -ForegroundColor Green