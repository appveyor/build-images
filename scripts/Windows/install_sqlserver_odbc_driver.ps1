function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    $uninstallString = ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
        | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
        | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
        | Select UninstallString).UninstallString

    if ($uninstallString) {
        return $uninstallString.replace('MsiExec.exe /I{', '/x{').replace('MsiExec.exe /X{', '/x{')
    }
    else {
        return $uninstallString
    }
}

$odbc17Name = "Microsoft ODBC Driver 17 for SQL Server"
$uninstallCommand = (GetUninstallString $odbc17Name)
if ($uninstallCommand) {
    Write-Host "Uninstalling $odbc17Name..."
    cmd /c start /wait msiexec.exe $uninstallCommand /quiet   
}


Write-Host "Installing ODBC driver 18..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\msodbcsql.msi"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/c/5/4/c54c2bf1-87d0-4f6f-b837-b78d34d4d28a/en-US/18.2.1.1/x64/msodbcsql.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /quiet /passive /qn /i $msiPath IACCEPTMSODBCSQLLICENSETERMS=YES
Remove-Item $msiPath -Force -ErrorAction Ignore

# Write-Host "Installing SQLCMD utility..." -ForegroundColor Cyan
# $msiPath = "$env:TEMP\MsSqlCmdLnUtils.msi"
# (New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/a/a/4/aa47b3b0-9f67-441d-8b00-e74cd845ea9f/EN/x64/MsSqlCmdLnUtils.msi', $msiPath)

# cmd /c start /wait msiexec /passive /qn /i $msiPath


Write-Host "ODBC version 18 installed" -ForegroundColor Green


