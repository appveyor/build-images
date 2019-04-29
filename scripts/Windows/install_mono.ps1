Write-Host "Installing Mono..." -ForegroundColor Cyan

function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
        | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
        | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
        | Select UninstallString).UninstallString
}

# uinstall Mono 3.2.3
$uninstallCommand = (GetUninstallString 'Mono for Windows')
if($uninstallCommand) {
    Write-Host "Uninstalling Mono..."
    $uninstallCommand = $uninstallCommand.replace('MsiExec.exe ', '')
    cmd /c start /wait msiexec.exe $uninstallCommand /quiet
}

# install mono
Write-Host "Downloading..."
$msiPath = "$($env:USERPROFILE)\mono-4.2.3.4-gtksharp-2.12.30-win32-0.msi"
(New-Object Net.WebClient).DownloadFile('http://download.mono-project.com/archive/4.2.3/windows-installer/mono-4.2.3.4-gtksharp-2.12.30-win32-0.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /q
del $msiPath

# check
if(Test-Path 'C:\Program Files (x86)\Mono\bin') {
    Write-host "Mono installed" -ForegroundColor Green
}