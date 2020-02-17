Write-Host "Installing Apache Maven 3.6.3 ..." -ForegroundColor Cyan

$apachePath = "${env:ProgramFiles(x86)}\Apache"
$mavenPath = "$apachePath\Maven"

if(Test-Path $mavenPath) {
    Remove-Item $mavenPath -Recurse -Force
}

if(-not (Test-Path $apachePath)) {
    New-Item $apachePath -ItemType directory -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\apache-maven-3.6.3-bin.zip"
(New-Object Net.WebClient).DownloadFile('http://apache.mirror.colo-serv.net/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.zip', $zipPath)

Write-Host "Unpacking..."
7z x $zipPath -oC:\apache-maven | Out-Null
[IO.Directory]::Move('C:\apache-maven\apache-maven-3.6.3', $mavenPath)
Remove-Item 'C:\apache-maven' -Recurse -Force
del $zipPath

[Environment]::SetEnvironmentVariable("M2_HOME", $mavenPath, "Machine")
[Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenPath, "Machine")

Add-Path "$mavenPath\bin"
Add-SessionPath "$mavenPath\bin"

mvn --version

Write-Host "Apache Maven 3.6.3 installed" -ForegroundColor Green