Write-Host "Cleaning up PATH..." -ForegroundColor Cyan

Remove-Path 'C:\Program Files (x86)\Microsoft Emulator Manager\1.0\'
Remove-Path 'C:\Program Files (x86)\Microsoft SDKs\TypeScript\1.0\'
Remove-Path 'C:\Program Files (x86)\Windows Phone TShell\'
Remove-Path 'C:\Program Files (x86)\Microsoft SQL Server\120\DTS\Binn\'
Remove-Path 'C:\Program Files\Microsoft SQL Server\110\DTS\Binn\'
Remove-Path 'c:\Program Files\Microsoft SQL Server\100\DTS\Binn\'
Remove-Path 'c:\Program Files\Microsoft SQL Server\100\Tools\Binn\'
Remove-Path 'C:\Program Files\Microsoft SQL Server\110\Tools\Binn\'
Remove-Path 'c:\Program Files (x86)\Microsoft SQL Server\100\Tools\Binn\'
Remove-Path 'C:\Program Files (x86)\Microsoft SQL Server\110\Tools\Binn\'
Remove-Path 'C:\Program Files\Windows Fabric\bin\Fabric\Fabric.Code.1.0'

Write-Host "Done" -ForegroundColor Green