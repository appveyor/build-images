Write-Host "Installing Apache Maven 3.9.16 ..." -ForegroundColor Cyan

$apachePath = "${env:ProgramFiles(x86)}\Apache"
$mavenPath = "$apachePath\Maven"

if (Test-Path $mavenPath) {
    Remove-Item $mavenPath -Recurse -Force
}

if (-not (Test-Path $apachePath)) {
    New-Item $apachePath -ItemType directory -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\apache-maven-3.9.16-bin.zip"
(New-Object Net.WebClient).DownloadFile('https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.zip', $zipPath)
if (-not (Test-Path $zipPath)) { throw "Unable to find $zipPath" }

Write-Host "Unpacking..."
7z x $zipPath -oC:\apache-maven | Out-Null
if (-not (Test-Path 'C:\apache-maven\apache-maven-3.9.16')) { throw "Unpacked Maven directory was not created." }
[IO.Directory]::Move('C:\apache-maven\apache-maven-3.9.16', $mavenPath)
Remove-Item 'C:\apache-maven' -Recurse -Force
Remove-Item $zipPath

[Environment]::SetEnvironmentVariable("M2_HOME", $mavenPath, "Machine")
[Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenPath, "Machine")

Add-Path "$mavenPath\bin"
Add-SessionPath "$mavenPath\bin"

mvn --version

Write-Host "Apache Maven 3.9.16 installed" -ForegroundColor Green
