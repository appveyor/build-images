Write-Host "Installing Mercurial"
Write-Host "===================="

Write-Host "Downloading..."
$msiPath = "$env:TEMP\mercurial-6.1.4-x64.msi"
(New-Object Net.WebClient).DownloadFile('https://www.mercurial-scm.org/release/windows/mercurial-6.1.4-x64.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet

del $msiPath

Add-Path "$env:ProgramFiles\Mercurial"
Add-SessionPath "$env:ProgramFiles\Mercurial"

Write-Host "Mercurial installed"