Write-Host "Installing xUnit 2.0..." -ForegroundColor Cyan
$xunitPath = "$env:SYSTEMDRIVE\Tools\xUnit20"

Remove-Item $xunitPath -Recurse -Force

$tempPath = "$env:TEMP\xunit20"
nuget install xunit.runner.console -excludeversion -outputdirectory $tempPath

[IO.Directory]::Move("$tempPath\xunit.runner.console\tools\net462", $xunitPath)
del $tempPath -Recurse -Force

[Environment]::SetEnvironmentVariable("xunit20", $xunitPath, "Machine")
Add-Path $xunitPath
Write-Host "xUnit 2.0 installed" -ForegroundColor Green