$vsixPath = "$env:TEMP\llvm.vsix"
Write-Host "Downloading llvm.vsix..."
(New-Object Net.WebClient).DownloadFile('https://llvmextensions.gallerycdn.vsassets.io/extensions/llvmextensions/llvm-toolchain/1.0.363769/1560930595399/llvm.vsix', $vsixPath)

$vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community"
if (-not (Test-Path $vsPath)) {
    $vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Preview"
}

Start-Process "$vsPath\Common7\IDE\VSIXInstaller.exe" "/q /a $vsixPath" -Wait
Remove-Item $vsixPath -Force -ErrorAction Ignore

Write-Host "Installed" -ForegroundColor Green
