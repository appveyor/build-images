﻿Write-Host "Installing Azure PowerShell ..." -ForegroundColor Cyan

Install-Module -Name Az -Scope CurrentUser -AllowClobber

Write-Host "Installed" -ForegroundColor Green

# Disable Azure PowerShell data collection
$azureCollectionProfilePath = "$env:APPDATA\Windows Azure Powershell\AzurePSDataCollectionProfile.json"
Write-Host "Creating AzurePSDataCollectionProfile.json"
New-Item -path "$env:APPDATA\Windows Azure Powershell" -Type directory -Force | Out-Null
Set-Content -path $azureCollectionProfilePath -value '{"enableAzureDataCollection":false}' -Force

Write-Host "Testing new cmdlets"
Get-Command Connect-AzAccount
Get-Command Get-AzRmStorageContainer

Write-Host "Testing cmdlets in compatibility mode"
Enable-AzureRmAlias
Get-Command Login-AzureRmAccount
Get-Command Get-AzureRmApiManagementBackend
