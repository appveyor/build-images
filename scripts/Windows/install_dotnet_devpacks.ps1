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
install-devpack -version "4.6.2" -location "https://download.visualstudio.microsoft.com/download/pr/ea744c52-1db4-4173-943d-a5d18e7e0d97/105c0e17be525bb0cebc7795d7aa1c32/ndp462-devpack-kb3151934-enu.exe"

if (-not $env:INSTALL_LATEST_ONLY) {
  install-devpack -version "4.7" -location "https://download.visualstudio.microsoft.com/download/pr/fe069d49-7999-4ac8-bf8d-625282915070/d52a6891b5014014e1f12df252fab620/ndp47-devpack-kb3186612-enu.exe"
  install-devpack -version "4.7.1" -location "https://download.visualstudio.microsoft.com/download/pr/e5eb8d37-5bbd-4fb7-a71d-b749e010ef9f/601437d729667ecd29020a829fbc4881/ndp471-devpack-enu.exe"
}
install-devpack -version "4.7.2" -location "https://download.visualstudio.microsoft.com/download/pr/158dce74-251c-4af3-b8cc-4608621341c8/9c1e178a11f55478e2112714a3897c1a/ndp472-devpack-enu.exe"
install-devpack -version "4.8" -location "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/c8c829444416e811be84c5765ede6148/ndp48-devpack-enu.exe"