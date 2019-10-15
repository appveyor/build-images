Write-Host "Installing Erlang..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$($env:TEMP)\otp_win64_20.2.exe"
(New-Object Net.WebClient).DownloadFile('http://www.erlang.org/download/otp_win64_20.2.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /S
del $exePath

Remove-Path "${env:ProgramFiles}\erl7.1\bin"
Remove-Path "${env:ProgramFiles}\erl7.3\bin"
Remove-Path "${env:ProgramFiles}\erl8.2\bin"
Remove-Path "${env:ProgramFiles}\erl8.3\bin"

Add-Path "${env:ProgramFiles}\erl9.2\bin"
[Environment]::SetEnvironmentVariable("ERLANG_HOME", "${env:ProgramFiles}\erl9.2", "Machine")

# ${env:ProgramFiles}\erl9.2

$x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
$x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
    | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
    | Where-Object { $_.DisplayName -and $_.DisplayName.contains('Erlang') } `
    | Sort-Object -Property DisplayName `
    | Select-Object -Property DisplayName,DisplayVersion

Write-Host "Installed Erlang" -ForegroundColor Green