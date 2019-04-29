Write-Host "Installing PowerShellGet"
Write-Host "========================"

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PowerShellGet -Force
Set-PSRepository -InstallationPolicy Trusted -Name PSGallery

Write-Host "PowerShellGet installed"