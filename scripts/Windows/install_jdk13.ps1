Write-Host "Installing JDK 13 ..." -ForegroundColor Cyan

$jdkPath = "${env:ProgramFiles}\Java\jdk13"

if(Test-Path $jdkPath) {
    Remove-Item $jdkPath -Recurse -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\openjdk-13_windows-x64_bin.zip"
(New-Object Net.WebClient).DownloadFile('https://download.java.net/java/GA/jdk13/5b8a42f3905b406298b72d750b6919f6/33/GPL/openjdk-13_windows-x64_bin.zip', $zipPath)

Write-Host "Unpacking..."
7z x $zipPath -oC:\jdk13_temp | Out-Null
[IO.Directory]::Move('C:\jdk13_temp\jdk-13', $jdkPath)
Remove-Item 'C:\jdk13_temp' -Recurse -Force
del $zipPath

cmd /c "`"$jdkPath\bin\java`" --version"

if ($env:INSTALL_LATEST_ONLY) {
    Add-Path "$jdkPath\bin"
}

Write-Host "JDK 13 installed" -ForegroundColor Green