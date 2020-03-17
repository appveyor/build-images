Write-Host "Installing JDK 14 ..." -ForegroundColor Cyan

New-Item "${env:ProgramFiles}\Java" -ItemType Directory -Force | Out-Null

$jdkPath = "${env:ProgramFiles}\Java\jdk14"

if(Test-Path $jdkPath) {
    Remove-Item $jdkPath -Recurse -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\openjdk-14_windows-x64_bin.zip"
(New-Object Net.WebClient).DownloadFile('https://download.java.net/java/GA/jdk14/076bab302c7b4508975440c56f6cc26a/36/GPL/openjdk-14_windows-x64_bin.zip', $zipPath)

Write-Host "Unpacking..."
$tempPath = "$env:TEMP\jdk14_temp"
7z x $zipPath -o"$tempPath" | Out-Null
[IO.Directory]::Move("$tempPath\jdk-14", $jdkPath)
Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -ErrorAction SilentlyContinue

cmd /c "`"$jdkPath\bin\java`" --version"

if ($env:INSTALL_LATEST_ONLY) {
    Add-Path "$jdkPath\bin"
}

Write-Host "JDK 13 installed" -ForegroundColor Green