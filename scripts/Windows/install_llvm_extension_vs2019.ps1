$vsixPath = "$($env:USERPROFILE)\llvm.vsix"
Write-Host "Downloading llvm.vsix..."
(New-Object Net.WebClient).DownloadFile('https://llvmextensions.gallerycdn.vsassets.io/extensions/llvmextensions/llvm-toolchain/1.0.359557/1556628491732/llvm.vsix', $vsixPath)
"`"C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\VSIXInstaller.exe`" /q /a $vsixPath" | out-file ".\install-vsix.cmd" -Encoding ASCII
Write-Host "Installing..."
& .\install-vsix.cmd
Write-Host "Deleting temporary files..."
Remove-Item $vsixPath -ErrorAction Ignore
Remove-Item .\install-vsix.cmd -ErrorAction Ignore
Write-Host "OK" -ForegroundColor Green
