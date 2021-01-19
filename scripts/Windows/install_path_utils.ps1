Write-Host "Installing Path-Utils"
Write-Host "====================="

$pathUtilsPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\path-utils"
New-Item $pathUtilsPath -ItemType Directory -Force

$srcPath = "$env:TEMP\path-utils.psm1"
if (-not (Test-Path $srcPath)) {
    $srcPath = "$PSScriptRoot\path-utils.psm1"
}
Copy-Item $srcPath -Destination $pathUtilsPath

Remove-Module path-utils -ErrorAction SilentlyContinue
Import-Module path-utils

$UserModulesPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
$PSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
if(-not $PSModulePath.contains($UserModulesPath)) {
    [Environment]::SetEnvironmentVariable('PSModulePath', "$PSModulePath;$UserModulesPath", 'Machine')
}

Write-Host "Path-Utils installed"