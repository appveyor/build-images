Write-Host "Installing Azure PowerShell ..." -ForegroundColor Cyan

Install-Module -Name Az -Scope CurrentUser -AllowClobber -RequiredVersion 9.1.1

Write-Host "Installed" -ForegroundColor Green
Get-InstalledModule -Name Az.Accounts
# Disable Azure PowerShell data collection
$azureCollectionProfilePath = "$env:APPDATA\Windows Azure Powershell\AzurePSDataCollectionProfile.json"
Write-Host "Creating AzurePSDataCollectionProfile.json"
New-Item -path "$env:APPDATA\Windows Azure Powershell" -Type directory -Force | Out-Null
Set-Content -path $azureCollectionProfilePath -value '{"enableAzureDataCollection":false}' -Force

Write-Host "Testing new cmdlets"
Get-Command Connect-AzAccount
Get-Command Get-AzRmStorageContainer

# Uninstall-Module -Name Az.Accounts -Force
# Install-Module -Name Az.Accounts -RequiredVersion 2.12.1

Write-Host "Testing cmdlets in compatibility mode"
Enable-AzureRmAlias
Get-Command Login-AzureRmAccount
Get-Command Get-AzureRmApiManagementBackend
