# TODO: remove existing installation
# wmic product where name="Azure Cosmos DB Emulator" call uninstall

Write-Host "Installing CosmosDB Emulator ..." -ForegroundColor Cyan
$msiPath = "$($env:TEMP)\cosmosdb.msi"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://aka.ms/cosmosdb-emulator', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet /qn
del $msiPath

dir "${env:ProgramFiles}\Azure Cosmos DB Emulator\"

Write-Host "CosmosDB Emulator installed" -ForegroundColor Green