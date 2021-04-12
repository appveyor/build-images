$cmakeVersion = "3.20.1"

$cmakeUninstallPath = "${env:ProgramFiles}\CMake\Uninstall.exe"
if([IO.File]::Exists($cmakeUninstallPath)) {
    Write-Host "Uninstalling previous CMake ..." -ForegroundColor Cyan
    # uninstall existent
    "`"$cmakeUninstallPath`" /S" | out-file ".\uninstall-cmake.cmd" -Encoding ASCII
    & .\uninstall-cmake.cmd
    Remove-Item .\uninstall-cmake.cmd
    Start-Sleep -s 10
}

Write-Host "Installing CMake $cmakeVersion ..." -ForegroundColor Cyan
$msiPath = "$env:TEMP\cmake-$cmakeVersion-windows-x86_64.msi"

Write-Host "Downloading..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object Net.WebClient).DownloadFile("https://github.com/Kitware/CMake/releases/download/v$cmakeVersion/cmake-$cmakeVersion-windows-x86_64.msi", $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet
Remove-Item $msiPath

Add-Path "${env:ProgramFiles}\CMake\bin"

remove-path 'C:\ProgramData\chocolatey\bin'
add-path 'C:\ProgramData\chocolatey\bin'

Write-Host "CMake installed" -ForegroundColor Green
