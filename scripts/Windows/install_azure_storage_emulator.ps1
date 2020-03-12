function GetEmulatorVersion {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    $x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
        | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
        | Where-Object { $_.DisplayName -and $_.DisplayName.contains('Azure Storage Emulator') } `
        | Sort-Object -Property DisplayName `
        | Select-Object -Property DisplayName,DisplayVersion
}

GetEmulatorVersion

Write-Host "Installing Azure storage emulator 5.10..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\MicrosoftAzureStorageEmulator.msi"
(New-Object Net.WebClient).DownloadFile('https://go.microsoft.com/fwlink/?LinkId=717179&clcid=0x409', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /q
Remove-Item $msiPath

GetEmulatorVersion

Write-Host "Installed Azure storage emulator" -ForegroundColor Green