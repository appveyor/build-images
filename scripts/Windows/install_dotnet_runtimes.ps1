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
#any AppVeyor-supported Windows build prior to 19042 can only handle .net-4.8.
if ((Get-CimInstance win32_OperatingSystem).BuildNumber -lt 19042) {
  install-runtime -version "4.8" -location "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/c9b8749dd99fc0d4453b2a3e4c37ba16/ndp48-web.exe" -release 528049
} else {
  install-runtime -version "4.8.1" -location "https://download.microsoft.com/download/4/b/2/cd00d4ed-ebdd-49ee-8a33-eabc3d1030e3/NDP481-Web.exe" -release 533320
}

