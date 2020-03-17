Write-Host "Installing JDK 13 ..." -ForegroundColor Cyan

New-Item "${env:ProgramFiles}\Java" -ItemType Directory -Force | Out-Null

$jdkPath = "${env:ProgramFiles}\Java\jdk13"

if(Test-Path $jdkPath) {
    Remove-Item $jdkPath -Recurse -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\openjdk-13_windows-x64_bin.zip"
(New-Object Net.WebClient).DownloadFile('https://download.java.net/java/GA/jdk13/5b8a42f3905b406298b72d750b6919f6/33/GPL/openjdk-13_windows-x64_bin.zip', $zipPath)

Write-Host "Unpacking..."
$tempPath = "$env:TEMP\jdk13_temp"
7z x $zipPath -o"$tempPath" | Out-Null
[IO.Directory]::Move("$tempPath\jdk-13", $jdkPath)
Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -ErrorAction SilentlyContinue

cmd /c "`"$jdkPath\bin\java`" --version"

if ($env:INSTALL_LATEST_ONLY) {
    Add-Path "$jdkPath\bin"
}

Write-Host "JDK 13 installed" -ForegroundColor Green