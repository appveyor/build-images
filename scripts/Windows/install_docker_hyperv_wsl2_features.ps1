$ErrorActionPreference = "Continue"

# Enable the two features WSL2 needs
$features = @(
  "Microsoft-Windows-Subsystem-Linux",
  "VirtualMachinePlatform"
)


foreach ($f in $features) {
  $state = (Get-WindowsOptionalFeature -Online -FeatureName $f).State
  if ($state -ne "Enabled") {
    Write-Host "Enabling $f"
    $r = Enable-WindowsOptionalFeature -Online -FeatureName $f -All -NoRestart
    if ($r.RestartNeeded) { $needsReboot = $true }
  } else {
    Write-Host "$f already enabled"
  }
}

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
  $hypervReq = (systeminfo | Select-String "Hyper-V Requirements").Line
  Write-Host $hypervReq
}



# WSL feature

#wsl --install --no-distribution

wsl --list --online

wsl --status 2>&1 | Write-Host

# make srue wsl kernel is present
wsl --update 2>&1 | Write-Host

wsl --shutdown 2>&1 | Write-Host

wsl --status 2>&1 | Write-Host
