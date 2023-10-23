$llvmVersion = "17.0.3"
Write-Host "Installing LLVM $llvmVersion ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\LLVM-$llvmVersion-win64.exe"
(New-Object Net.WebClient).DownloadFile("https://github.com/llvm/llvm-project/releases/download/llvmorg-$llvmVersion/LLVM-$llvmVersion-win64.exe", $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /S
Add-Path "$env:ProgramFiles\LLVM\bin"
Add-SessionPath "$env:ProgramFiles\LLVM\bin"

cmd /c clang --version

Write-Host "Installed" -ForegroundColor Green
