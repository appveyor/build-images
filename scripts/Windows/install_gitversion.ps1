Write-Host "Installing GitVersion 4.x..." -ForegroundColor Cyan
$gvPath = "$env:SYSTEMDRIVE\Tools\GitVersion"
if(Test-Path $gvPath) {
    del $gvPath -Recurse -Force
}

$tempPath = "$env:USERPROFILE\GitVersion"
nuget install gitversion.commandline -excludeversion -outputdirectory $tempPath

[IO.Directory]::Move("$tempPath\gitversion.commandline\tools", $gvPath)
del $tempPath -Recurse -Force
Add-Path $gvPath
Write-Host "GitVersion 4.x installed" -ForegroundColor Green