Write-Host "Installing NuGet"
Write-Host "================"

$nugetPath = "$env:SYSTEMDRIVE\Tools\NuGet"
if(-not (Test-Path $nugetPath)) {
    New-Item $nugetPath -ItemType Directory -Force | Out-Null
}

(New-Object Net.WebClient).DownloadFile('https://dist.nuget.org/win-x86-commandline/latest/nuget.exe', "$nugetPath\nuget.exe")

Add-Path $nugetPath
Add-SessionPath $nugetPath    

Write-Host "NuGet installed" -ForegroundColor Green