Write-Host "Installing VS Test Agent 2019..." -ForegroundColor Cyan
$testAgentPath = "$env:TEMP\vs_TestAgent.exe"
(New-Object Net.WebClient).DownloadFile('https://download.visualstudio.microsoft.com/download/pr/c782dfb5-ece2-4295-97f2-225b4a8e576e/742730493cc7f2fecacb7f3b9cfaa373/vs_testagent.exe', $testAgentPath)
Start-Process $testAgentPath -ArgumentList '--quiet', '--norestart', '--nocache' -NoNewWindow -Wait
Remove-Item -Force v$testAgentPath -ErrorAction Ignore
Write-Host "OK"  -ForegroundColor Green

Write-Host "Installing Microsoft Build Tools 2019..." -ForegroundColor Cyan
$buildToolsPath = "$env:TEMP\vs_BuildTools.exe"
(New-Object Net.WebClient).DownloadFile('https://download.visualstudio.microsoft.com/download/pr/a08183e4-3087-4df5-a074-d3bdf1ad5eb8/20816d670f7909277d9793dc3e80b3c2/vs_buildtools.exe', $buildToolsPath)
setx /M DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1 | out-null
Start-Process $buildToolsPath `
-ArgumentList `
'--add', 'Microsoft.VisualStudio.Workload.MSBuildTools', `
'--add', 'Microsoft.VisualStudio.Workload.NetCoreBuildTools', `
'--add', 'Microsoft.VisualStudio.Workload.WebBuildTools', `
'--add', 'Microsoft.VisualStudio.Wcf.BuildTools.ComponentGroup', `
'--add', 'Microsoft.Component.ClickOnce.MSBuild', `
'--quiet', '--norestart', '--nocache' `
-NoNewWindow -Wait; `
Remove-Item  -Force $buildToolsPath -ErrorAction Ignore
Write-Host "OK"  -ForegroundColor Green

Write-Host "Cleaning temporary files"  -ForegroundColor Cyan
Remove-Item -Force -Recurse "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\" -ErrorAction Ignore
Remove-Item -Force -Recurse ${Env:TEMP}\* -ErrorAction Ignore
Remove-Item -Force -Recurse "${Env:ProgramData}\Package Cache\" -ErrorAction Ignore
Write-Host "OK" -ForegroundColor Green

Write-Host "Setting up path"  -ForegroundColor Cyan
Add-SessionPath "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow\"
Add-SessionPath "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\"

Add-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow\"
Add-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\"
Write-Host "OK" -ForegroundColor Green