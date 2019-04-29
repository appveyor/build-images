$ErrorActionPreference = "Stop"

# Containers feature

$containersFeature = (Get-WindowsOptionalFeature -FeatureName Containers -Online)
if ($containersFeature -and $containersFeature.State -ne 'Enabled') {
	Write-Host "Installing Containers feature"
	Enable-WindowsOptionalFeature -FeatureName Containers -Online -All -NoRestart
}

# Hyper-V feature

if ((Get-WmiObject Win32_Processor).VirtualizationFirmwareEnabled[0] -and (Get-WmiObject Win32_Processor).SecondLevelAddressTranslationExtensions[0]) {
	Write-Host "Installing Hyper-V feature"
	Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
} else {
	Write-Host "Skipping Hyper-V installation - virtualization is not enabled"
}

# WSL feature

$wslFeature = (Get-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online)

if ($wslFeature -and $wslFeature.State -ne 'Enabled') {
	Write-Host "Installing WSL feature"
	Enable-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online -All -NoRestart
}