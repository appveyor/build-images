function devpack-installed ($version) {
  if (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where {$_.DisplayName -eq "Microsoft .NET Framework $($version) Developer Pack"}) {
    return $true
  }
}

#needed for 4.5.2 which has different naming convention
function multitargetingpack-installed ($version) {
  if (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where {$_.DisplayName -eq "Microsoft .NET Framework $($version) Multi-Targeting Pack"}) {
    return $true
  }
}

function install-devpack ($version, $location) {
  if (devpack-installed -version $version) {
    Write-Host ".NET Framework $($version) Developer Pack already installed." -ForegroundColor Cyan
  }
  elseif (multitargetingpack-installed -version $version) {
    Write-Host ".NET Framework $($version) Multi-Targeting Pack already installed." -ForegroundColor Cyan
  }
  else {
    Write-Host ".NET Framework $($version) Developer Pack..." -ForegroundColor Cyan
    Write-Host "Downloading..."
    $exePath = "$env:TEMP\$($version)-devpack.exe"
    (New-Object Net.WebClient).DownloadFile($location, $exePath)
    Write-Host "Installing..."
    cmd /c start /wait "$exePath" /quiet /norestart
    Remove-Item $exePath -Force -ErrorAction Ignore
    Write-Host "Installed" -ForegroundColor Green
  }
}

if (-not $env:INSTALL_LATEST_ONLY) {
  install-devpack -version "4.5.2" -location "https://download.microsoft.com/download/4/3/B/43B61315-B2CE-4F5B-9E32-34CCA07B2F0E/NDP452-KB2901951-x86-x64-DevPack.exe"
  install-devpack -version "4.6.1" -location "https://download.microsoft.com/download/F/1/D/F1DEB8DB-D277-4EF9-9F48-3A65D4D8F965/NDP461-DevPack-KB3105179-ENU.exe"
}
install-devpack -version "4.6.2" -location "https://download.microsoft.com/download/E/F/D/EFD52638-B804-4865-BB57-47F4B9C80269/NDP462-DevPack-KB3151934-ENU.exe"

if (-not $env:INSTALL_LATEST_ONLY) {
  install-devpack -version "4.7" -location "https://download.microsoft.com/download/A/1/D/A1D07600-6915-4CB8-A931-9A980EF47BB7/NDP47-DevPack-KB3186612-ENU.exe"
  install-devpack -version "4.7.1" -location "https://download.microsoft.com/download/9/0/1/901B684B-659E-4CBD-BEC8-B3F06967C2E7/NDP471-DevPack-ENU.exe"
}
install-devpack -version "4.7.2" -location "https://download.visualstudio.microsoft.com/download/pr/158dce74-251c-4af3-b8cc-4608621341c8/9c1e178a11f55478e2112714a3897c1a/ndp472-devpack-enu.exe"
install-devpack -version "4.8" -location "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/c8c829444416e811be84c5765ede6148/ndp48-devpack-enu.exe"