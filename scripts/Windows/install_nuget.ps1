﻿$nugetVersion = '6.7.0'
$nugetUrl = "https://dist.nuget.org/win-x86-commandline/v$nugetVersion/nuget.exe"

$nugetDir = "$env:SystemDrive\Tools\NuGet3"

if (-not (Test-Path $nugetDir)) {
    $nugetDir = "$env:SystemDrive\Tools\NuGet"
    if (-not (Test-Path $nugetDir)) {
        Write-Host "Installing NuGet into $nugetDir"
        New-Item $nugetDir -ItemType Directory -Force | Out-Null
        Add-Path $nugetDir
        Add-SessionPath $nugetDir
    }
    else {
        Write-Host "Updating NuGet in $nugetDir"
    }
}
else {
    Write-Host "Updating NuGet in $nugetDir"
}

(New-Object Net.WebClient).DownloadFile($nugetUrl, "$nugetDir\nuget.exe")

(nuget).split("`n")[0]

# fix sources
nuget sources add -name nuget.org -source https://api.nuget.org/v3/index.json

Write-Host "NuGet updated" -ForegroundColor Green