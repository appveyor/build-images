. "$PSScriptRoot\common.ps1"

Write-Host "Uninstalling Service Fabric" -ForegroundColor Cyan

function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    $x64userItems = @(Get-ChildItem "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + $x64userItems + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
        | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
        | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
        | Select-Object UninstallString).UninstallString
}

Write-Host "Uninstalling Service Fabric SDK..."

$sdkUninstallString = GetUninstallString "Microsoft Azure Service Fabric SDK"
if ($sdkUninstallString) {
    $uninstallCommand = $sdkUninstallString.replace('MsiExec.exe /I{', '/x{').replace('MsiExec.exe /X{', '/x{')
    cmd /c start /wait msiexec.exe $uninstallCommand /quiet
} else {
    Write-Host "Service Fabric SDK not found" -ForegroundColor Yellow
}

Write-Host "Uninstalling Service Fabric Runtime..."

$runtimeUninstallString = GetUninstallString "Microsoft Azure Service Fabric"
if ($runtimeUninstallString) {
     Start-ProcessWithOutput $runtimeUninstallString
} else {
    Write-Host "Service Fabric Runtime not found" -ForegroundColor Yellow
}

Write-Host "Service Fabric uninstalled" -ForegroundColor Green
