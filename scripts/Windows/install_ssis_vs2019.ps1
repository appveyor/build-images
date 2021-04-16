Write-Host "Installing SQL Server Integration Services Projects" -ForegroundColor Cyan

# install runtime
Write-Host "Downloading..."
$exePath = "$env:TEMP\Microsoft.DataTools.IntegrationServices.exe"
(New-Object Net.WebClient).DownloadFile('https://ssis.gallerycdn.vsassets.io/extensions/ssis/sqlserverintegrationservicesprojects/3.12.1/1615963475094/Microsoft.DataTools.IntegrationServices.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /quiet
Remove-Item $exePath

Write-Host "SQL Server Integration Services Projects installed" -ForegroundColor Green

# -----

Write-Host "Installing Microsoft Analysis Services Projects" -ForegroundColor Cyan

$vsixPath = "$env:TEMP\data-tools.vsix"
Write-Host "Downloading VS extension package..."
(New-Object Net.WebClient).DownloadFile('https://probitools.gallerycdn.vsassets.io/extensions/probitools/microsoftanalysisservicesmodelingprojects/2.9.17/1617148425070/Microsoft.DataTools.AnalysisServices.vsix', $vsixPath)

Write-Host "Installing package..."

$vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community"
if (-not (Test-Path $vsPath)) {
    $vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Preview"
}

Start-Process "$vsPath\Common7\IDE\VSIXInstaller.exe" "/q /a $vsixPath" -Wait

Write-Host "Microsoft Analysis Services Projects installed" -ForegroundColor Green