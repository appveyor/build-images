Write-Host "Cleaning up PATH..." -ForegroundColor Cyan

Remove-Path "${env:ProgramFiles(x86)}\Microsoft Emulator Manager\1.0\"
Remove-Path "${env:ProgramFiles(x86)}\Microsoft SDKs\TypeScript\1.0\"
Remove-Path "${env:ProgramFiles(x86)}\Windows Phone TShell\"
Remove-Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\120\DTS\Binn\"
Remove-Path "${env:ProgramFiles}\Microsoft SQL Server\110\DTS\Binn\"
Remove-Path "${env:ProgramFiles}\Microsoft SQL Server\100\DTS\Binn\"
Remove-Path "${env:ProgramFiles}\Microsoft SQL Server\100\Tools\Binn\"
Remove-Path "${env:ProgramFiles}\Microsoft SQL Server\110\Tools\Binn\"
Remove-Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\100\Tools\Binn\"
Remove-Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\Tools\Binn\"
Remove-Path "${env:ProgramFiles}\Windows Fabric\bin\Fabric\Fabric.Code.1.0"

Write-Host "Done" -ForegroundColor Green