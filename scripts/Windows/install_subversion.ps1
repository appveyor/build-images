Write-Host "Installing Subversion"
Write-Host "====================="

$msiPath = "$env:TEMP\Setup-Subversion-1.8.17.msi"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://phoenixnap.dl.sourceforge.net/project/win32svn/1.8.17/Setup-Subversion-1.8.17.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /q
del $msiPath
    
Add-Path "${env:ProgramFiles(x86)}\Subversion\bin"
Add-SessionPath "${env:ProgramFiles(x86)}\Subversion\bin"

svn --version
Write-Host "Subversion installed"