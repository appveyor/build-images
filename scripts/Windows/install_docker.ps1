$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# What Windows is that?
$osVerBuild = (Get-CimInstance Win32_OperatingSystem).BuildNumber

# Major  Minor  Build  Revision
# -----  -----  -----  --------
# 10     0      17763  0

# Windows Server 2016	10.0.14393
# Windows 10 (1709)		10.0.16299
# Windows 10 (1803)		10.0.17134
# Windows Server 2019	10.0.17763

function ContainersFeatureInstalled () {
  $containersFeature = (Get-WindowsOptionalFeature -FeatureName Containers -Online)
  if (-not $containersFeature -or $containersFeature.State -ne 'Enabled') {
	  return $false
  }
  else {
    return $true
  }  
}

Write-Host "Checking if Containers feature is installed..." 
$i = 0
$installed = $false
while ($i -lt 20) {
  $i +=1  
  $installed = ContainersFeatureInstalled
  if ($installed) {Write-Host "OK"; break}
  Write-warning "Retrying in 10 seconds..."
  Start-Sleep -s 10;
}

if (-not $installed) {
	Write-Host "Containers feature is not installed"
    return
}


#Get list of avaliable docker versions
$dockerDownloadUrl = "https://download.docker.com/win/static/stable/x86_64/"
$availableVersions = ((Invoke-WebRequest -Uri $dockerDownloadUrl -UseBasicParsing).Links | Where-Object {$_.href -like "docker*"}).href | Sort-Object -Descending
       
#Parse the versions from the file names
$availableVersions = ($availableVersions | Select-String -Pattern "docker-(\d+\.\d+\.\d+).+"  -AllMatches | Select-Object -Expand Matches | %{ $_.Groups[1].Value })
$version = $availableVersions[0]

$packageUrl = $dockerDownloadUrl + "docker-$version.zip"
$tempDownloadFolder = "$env:UserProfile\DockerDownloads"
if(!(Test-Path "$tempDownloadFolder")) {
    mkdir -Path $tempDownloadFolder | Out-Null
} elseif(Test-Path "$tempDownloadFolder\docker-$version") {
    Remove-Item -Recurse -Force "$tempDownloadFolder\docker-$version"
}
Write-Output "Downloading from $packageUrl to $tempDownloadFolder\docker-$version.zip"
(New-Object Net.WebClient).DownloadFile($packageUrl, "$tempDownloadFolder\docker-$version.zip")

Expand-Archive -Path "$tempDownloadFolder\docker-$version.zip" -DestinationPath "$tempDownloadFolder\docker-$version"


Write-Output "Copying Docker folder..."
[IO.Directory]::Move("$tempDownloadFolder\docker-$version\docker", "$env:ProgramFiles\Docker")
# Copy-Item -Path "$tempDownloadFolder\docker-$version\docker\docker.exe" -Destination $env:ProgramFiles\Docker\docker.exe
# Write-Output "Copying Docker daemon executable..."
# Copy-Item -Path "$tempDownloadFolder\docker-$version\docker\dockerd.exe" -Destination $env:ProgramFiles\Docker\dockerd.exe
$env:path = "$env:ProgramFiles\Docker;$env:path"

& dockerd --register-service --service-name docker


Write-Host "Installing docker-compose"
(New-Object Net.WebClient).DownloadFile('https://github.com/docker/compose/releases/download/1.23.2/docker-compose-Windows-x86_64.exe', "$env:ProgramFiles\Docker\docker-compose.exe")

Write-Host "Starting Docker"
Start-Service docker

Write-Host "Downloading docker-credential-wincred"
(New-Object Net.WebClient).DownloadFile('https://github.com/docker/docker-credential-helpers/releases/download/v0.6.0/docker-credential-wincred-v0.6.0-amd64.zip', "$env:TEMP\docker-credential-wincred-v0.6.0-amd64.zip")
Expand-Archive -Path "$env:TEMP\docker-credential-wincred-v0.6.0-amd64.zip" -DestinationPath "$env:ProgramFiles\Docker" -Force
Remove-Item "$env:TEMP\docker-credential-wincred-v0.6.0-amd64.zip"
Write-Host "docker-credential-wincred installed"
