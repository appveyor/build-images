function runtime-installed ($release) {
  if ((Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' | Get-ItemPropertyValue -Name Release) -eq $release) {
    return $true
  }
}

function install-runtime ($version, $location, $release) {
  if (runtime-installed -release $release) {
    Write-Host ".NET Framework $($version) runtime already installed." -ForegroundColor Cyan
  }
  else {
    Write-Host ".NET Framework $($version) runtime..." -ForegroundColor Cyan
    Write-Host "Downloading..."
    $exePath = "$env:TEMP\$($version)-runtime.exe"
    (New-Object Net.WebClient).DownloadFile($location, $exePath)
    Write-Host "Installing..."
    cmd /c start /wait "$exePath" /quiet /norestart
    Remove-Item $exePath -Force -ErrorAction Ignore
    Write-Host "Installed" -ForegroundColor Green
  }
}

#release from https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed
install-runtime -version "4.8" -location "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/c9b8749dd99fc0d4453b2a3e4c37ba16/ndp48-web.exe" -release 528049