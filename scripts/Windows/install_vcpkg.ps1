. "$PSScriptRoot\common.ps1"

if (test-path "$env:SystemDrive\Tools\vcpkg") {
  Write-Host "vcpkg is already installed. Updating..." -ForegroundColor Cyan
  vcpkg version | findstr /psi "version"
  Push-Location "$env:SystemDrive\Tools\vcpkg"
  Start-ProcessWithOutput "git pull"
  .\bootstrap-vcpkg.bat
  vcpkg integrate install
  Write-Host "vcpkg updated" -ForegroundColor Green
}
else {
  Write-Host "Installing vcpkg..." -ForegroundColor Cyan
  Push-Location "$env:SystemDrive\Tools"
  Start-ProcessWithOutput "git clone https://github.com/Microsoft/vcpkg"
  .\vcpkg\bootstrap-vcpkg.bat  
  Add-Path "$env:SystemDrive\Tools\vcpkg"
  Add-SessionPath "$env:SystemDrive\Tools\vcpkg"
  vcpkg integrate install
  Write-Host "vcpkg installed" -ForegroundColor Green
}
Pop-Location
vcpkg version | findstr /psi "version"