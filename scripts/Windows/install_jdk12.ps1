Write-Host "Installing JDK 12 ..." -ForegroundColor Cyan

New-Item "${env:ProgramFiles}\Java" -ItemType Directory -Force | Out-Null

$jdkPath = "${env:ProgramFiles}\Java\jdk12"

if(Test-Path $jdkPath) {
    Remove-Item $jdkPath -Recurse -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\openjdk-12_windows-x64_bin.zip"
(New-Object Net.WebClient).DownloadFile('https://download.java.net/java/GA/jdk12.0.2/e482c34c86bd4bf8b56c0b35558996b9/10/GPL/openjdk-12.0.2_windows-x64_bin.zip', $zipPath)

Write-Host "Unpacking..."
$tempPath = "$env:TEMP\jdk12_temp"
7z x $zipPath -o"$tempPath" | Out-Null
[IO.Directory]::Move("$tempPath\jdk-12.0.2", $jdkPath)
Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -ErrorAction SilentlyContinue

cmd /c "`"$jdkPath\bin\java`" --version"

Write-Host "JDK 12 installed" -ForegroundColor Green