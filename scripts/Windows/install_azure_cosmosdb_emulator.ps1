function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
        | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
        | Where-Object { $_.DisplayName -and $_.DisplayName.Contains($productName) } `
        | Select UninstallString).UninstallString
}

$uninstallCommand = GetUninstallString "Azure Cosmos DB Emulator"

if ($uninstallCommand) {
    Write-Host "Uninstalling existing installation of CosmosDB Emulator ..." -ForegroundColor Cyan

    $uninstallCommand = $uninstallCommand.replace('MsiExec.exe /I{', '/x{').replace('MsiExec.exe /X{', '/x{')
    cmd /c start /wait msiexec.exe $uninstallCommand /quiet

    Write-Host "Uninstalled $name" -ForegroundColor Green
}

Write-Host "Installing CosmosDB Emulator ..." -ForegroundColor Cyan
$msiPath = "$($env:TEMP)\cosmosdb.msi"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://aka.ms/cosmosdb-emulator', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet /qn
del $msiPath

dir "${env:ProgramFiles}\Azure Cosmos DB Emulator\"

Write-Host "CosmosDB Emulator installed" -ForegroundColor Green