Write-Host "Installing NVM 1.1.8..." -ForegroundColor Cyan

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$nvmPath = "$env:SYSTEMDRIVE\Tools\nvm"
$symLinkPath = "$env:ProgramFiles\nodejs"

Remove-Item $nvmPath -Recurse -Force -ErrorAction SilentlyContinue

# nunit
$zipPath = "$env:TEMP\nvm-noinstall.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/coreybutler/nvm-windows/releases/download/1.1.8/nvm-noinstall.zip', $zipPath)
7z x $zipPath -y -o"$nvmPath" | Out-Null
Remove-Item $zipPath

# configure
[Environment]::SetEnvironmentVariable('NVM_HOME', $nvmPath, 'Machine')
[Environment]::SetEnvironmentVariable('NVM_SYMLINK', $symLinkPath, 'Machine')

$env:NVM_HOME = $nvmPath
$env:NVM_SYMLINK = $symLinkPath

$settings = @(
    "root: $nvmPath"
    "path: $symLinkPath"
    "proxy: none"
    "arch: 64"
)

Set-Content -Path "$nvmPath\settings.txt" -Value $settings

Add-Path $nvmPath
Add-SessionPath $nvmPath
Add-Path $symLinkPath
Add-SessionPath $symLinkPath
Add-Path "$env:APPDATA\npm"

Get-Command nvm

Write-Host "NVM installed" -ForegroundColor Green

Write-Host "Installing Node versions..." -ForegroundColor Cyan

$node_versions = @("4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "latest", "lts")

# install nodes
foreach($node_version in $node_versions) {
    Write-Host "Installing Node $node_version..." -ForegroundColor Cyan
    nvm install $node_version "32"
    nvm install $node_version "64"
}

# test nodes
foreach($node_version in $node_versions) {
    Write-Host "Testing Node $node_version 32-bit..." -ForegroundColor Cyan
    nvm use $node_version "32"

    node --version
    npm --version

    Write-Host "Testing Node $node_version 64-bit..." -ForegroundColor Cyan
    nvm use $node_version "64"

    node --version
    npm --version
}

dir "$nvmPath" | ft *

# check default version
node --version
npm --version

Write-Host "Node versions installed" -ForegroundColor Green
