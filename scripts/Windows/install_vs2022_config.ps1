$vsPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community"
if (-not (Test-Path $vsPath)) {
    $vsPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Preview"
}

Write-Host "Initializing Visual Studio Experimental Instance"
& "$vsPath\Common7\IDE\devenv.exe" /RootSuffix Exp /ResetSettings General.vssettings /Command File.Exit

Write-Host "Warm up default .NET Core SDK"

$projectPath = "$env:temp\TestCoreApp"
New-Item -Path $projectPath -Force -ItemType Directory | Out-Null
Push-Location -Path $projectPath
& $env:ProgramFiles\dotnet\dotnet.exe new console
Pop-Location
Remove-Item $projectPath -Force -Recurse