if (test-path C:\Tools\vcpkg) {
  vcpkg version | findstr /psi "version"
  Push-Location C:\Tools\vcpkg
  cmd /c git pull
  .\bootstrap-vcpkg.bat
  }
else {
  Push-Location C:\Tools
  git clone https://github.com/Microsoft/vcpkg
  .\vcpkg\bootstrap-vcpkg.bat
  Add-Path C:\Tools\vcpkg
  Add-SessionPath C:\Tools\vcpkg
}
Pop-Location
vcpkg version | findstr /psi "version"
