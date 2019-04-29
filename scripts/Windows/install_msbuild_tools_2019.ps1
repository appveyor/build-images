Write-Host "Installing Microsoft Build Tools 2019..." -ForegroundColor Cyan

$msbuild15Path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\15.0\Bin"

if(-not (Test-Path $msbuild15Path)) {
    $exePath = "$env:TEMP\vs_BuildTools.exe"
    (New-Object Net.WebClient).DownloadFile('https://download.visualstudio.microsoft.com/download/pr/1e5ff7fe-162b-4a3d-8fda-3267702b551d/e25ce34fd81235ebbd79010afad8e63f/vs_buildtools.exe', $exePath)
    cmd /c start /wait $exePath --passive --norestart
    del $exePath
}

Add-SessionPath $msbuild15Path
Add-Path $msbuild15Path

Write-Host "Microsoft Build Tools 2019 installed" -ForegroundColor Green