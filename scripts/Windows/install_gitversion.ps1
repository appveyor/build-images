﻿Write-Host "Installing GitVersion..." -ForegroundColor Cyan
$gvPath = "$env:SYSTEMDRIVE\Tools\GitVersion"
if(Test-Path $gvPath) {
    Remove-Item $gvPath -Recurse -Force
}

$tempPath = "$env:USERPROFILE\GitVersion"
nuget install gitversion.commandline -Version 5.1.3 -ExcludeVersion -OutputDirectory $tempPath

[IO.Directory]::Move("$tempPath\gitversion.commandline\tools", $gvPath)
Remove-Item $tempPath -Recurse -Force
Add-Path $gvPath
Write-Host "GitVersion installed" -ForegroundColor Green