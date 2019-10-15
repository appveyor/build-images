Write-Host "Installing JDK 12 ..." -ForegroundColor Cyan

$jdkPath = "${env:ProgramFiles}\Java\jdk12"

if(Test-Path $jdkPath) {
    Remove-Item $jdkPath -Recurse -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\openjdk-12_windows-x64_bin.zip"
(New-Object Net.WebClient).DownloadFile('https://download.java.net/java/GA/jdk12.0.2/e482c34c86bd4bf8b56c0b35558996b9/10/GPL/openjdk-12.0.2_windows-x64_bin.zip', $zipPath)

Write-Host "Unpacking..."
7z x $zipPath -oC:\jdk12_temp | Out-Null
[IO.Directory]::Move('C:\jdk12_temp\jdk-12.0.2', $jdkPath)
Remove-Item 'C:\jdk12_temp' -Recurse -Force
del $zipPath

cmd /c "`"$jdkPath\bin\java`" --version"

Write-Host "JDK 12 installed" -ForegroundColor Green