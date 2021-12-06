Write-Host "Installing xUnit 2.4.1..." -ForegroundColor Cyan
$xunitPath = "$env:SYSTEMDRIVE\Tools\xUnit20"

Remove-Item $xunitPath -Recurse -Force -ErrorAction SilentlyContinue

$tempPath = "$env:TEMP\xunit20"
nuget install xunit.runner.console -version 2.4.1 -excludeversion -outputdirectory $tempPath

[IO.Directory]::Move("$tempPath\xunit.runner.console\tools\net462", $xunitPath)
Remove-Item $tempPath -Recurse -Force

[Environment]::SetEnvironmentVariable("xunit20", $xunitPath, "Machine")
Add-Path $xunitPath
Write-Host "xUnit 2.0 installed" -ForegroundColor Green