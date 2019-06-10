if (test-path C:\Tools\vcpkg) {
  cd C:\Tools\vcpkg
  git pull
  .\bootstrap-vcpkg.bat
  }
else {
  cd C:\Tools
  git clone https://github.com/Microsoft/vcpkg
  .\vcpkg\bootstrap-vcpkg.bat
  Add-Path C:\Tools\vcpkg
  Add-SessionPath C:\Tools\vcpkg
}
