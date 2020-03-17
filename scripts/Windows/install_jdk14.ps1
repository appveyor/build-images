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
7z x $zipPath -oC:\jdk13_temp | Out-Null
[IO.Directory]::Move('C:\jdk14_temp\jdk-14', $jdkPath)
Remove-Item 'C:\jdk14_temp' -Recurse -Force
Remove-Item $zipPath

cmd /c "`"$jdkPath\bin\java`" --version"

if ($env:INSTALL_LATEST_ONLY) {
    Add-Path "$jdkPath\bin"
}

Write-Host "JDK 13 installed" -ForegroundColor Green