Write-Host "Installing Chocolatey"
Write-Host "====================="

if(Test-Path 'C:\ProgramData\chocolatey\bin') {
    # update
    Write-Host "Updating Chocolatey..." -ForegroundColor Cyan
    choco upgrade chocolatey
} else {
    # install
    Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

choco --version
choco feature enable -n allowGlobalConfirmation

Write-Host "Chocolatey installed" -ForegroundColor Green