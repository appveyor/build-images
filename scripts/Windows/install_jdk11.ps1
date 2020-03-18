Write-Host "Installing JDK 11 ..." -ForegroundColor Cyan

New-Item "${env:ProgramFiles}\Java" -ItemType Directory -Force | Out-Null

$jdkPath = "${env:ProgramFiles}\Java\jdk11"

if(Test-Path $jdkPath) {
    Remove-Item $jdkPath -Recurse -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\openjdk-11.0.2_windows-x64_bin.zip"
(New-Object Net.WebClient).DownloadFile('https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_windows-x64_bin.zip', $zipPath)

Write-Host "Unpacking..."
$tempPath = "$env:TEMP\jdk11_temp"
7z x $zipPath -o"$tempPath" | Out-Null
[IO.Directory]::Move("$tempPath\jdk-11.0.2", $jdkPath)
Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zipPath -ErrorAction SilentlyContinue

cmd /c "`"$jdkPath\bin\java`" --version"

Write-Host "JDK 11 installed" -ForegroundColor Green