Write-Host "Installing Apache Maven 3.8.5 ..." -ForegroundColor Cyan

$apachePath = "${env:ProgramFiles(x86)}\Apache"
$mavenPath = "$apachePath\Maven"

if (Test-Path $mavenPath) {
    Remove-Item $mavenPath -Recurse -Force
}

if (-not (Test-Path $apachePath)) {
    New-Item $apachePath -ItemType directory -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\apache-maven-3.8.5-bin.zip"
(New-Object Net.WebClient).DownloadFile('https://dlcdn.apache.org/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.zip', $zipPath)

Write-Host "Unpacking..."
7z x $zipPath -oC:\apache-maven | Out-Null
[IO.Directory]::Move('C:\apache-maven\apache-maven-3.8.5', $mavenPath)
Remove-Item 'C:\apache-maven' -Recurse -Force
Remove-Item $zipPath

[Environment]::SetEnvironmentVariable("M2_HOME", $mavenPath, "Machine")
[Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenPath, "Machine")

Add-Path "$mavenPath\bin"
Add-SessionPath "$mavenPath\bin"

mvn --version

Write-Host "Apache Maven 3.8.5 installed" -ForegroundColor Green