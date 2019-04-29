[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# What Windows is that?
$osVer = [System.Environment]::OSVersion.Version

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
  sleep 10;
}

if (-not $installed) {
	Write-Host "Containers feature is not installed"
    return
}

Write-Host "Configure PSGallery trust policy"
Set-PSRepository -InstallationPolicy Trusted -Name PSGallery

Write-Host "Install-Module DockerProvider"
Install-Module DockerMsftProvider -Force

Write-Host "Install-Package Docker"
Install-Package -Name docker -ProviderName DockerMsftProvider -Force

$lcowEnabled = $false
if ($osVer.Major -eq 10 -and $osVer.Build -ge 16299) {
	# 1709 and above is required for LCOW
	
	Write-Host "Enable LCOW"
	(New-Object Net.WebClient).DownloadFile('https://github.com/linuxkit/lcow/releases/download/v4.14.35-v0.3.9/release.zip', "$env:TEMP\linuxkit-lcow.zip")
	Expand-Archive -Path "$env:TEMP\linuxkit-lcow.zip" -DestinationPath "$env:ProgramFiles\Linux Containers" -Force
	Remove-Item "$env:TEMP\linuxkit-lcow.zip"

	Write-Host "Stopping Docker"
	Stop-Service docker

	Write-Host "Re-registering Docker with experimental features enabled"
	dockerd --unregister-service
	dockerd --register-service --experimental
	$lcowEnabled = $true
}

Write-Host "Installing docker-compose"
(New-Object Net.WebClient).DownloadFile('https://github.com/docker/compose/releases/download/1.23.2/docker-compose-Windows-x86_64.exe', "$env:ProgramFiles\Docker\docker-compose.exe")

Write-Host "Starting Docker"
Start-Service docker

$env:path = "$env:ProgramFiles\Docker;$env:path"

Write-Host "Downloading docker-credential-wincred"
(New-Object Net.WebClient).DownloadFile('https://github.com/docker/docker-credential-helpers/releases/download/v0.6.0/docker-credential-wincred-v0.6.0-amd64.zip', "$env:TEMP\docker-credential-wincred-v0.6.0-amd64.zip")
Expand-Archive -Path "$env:TEMP\docker-credential-wincred-v0.6.0-amd64.zip" -DestinationPath "$env:ProgramFiles\Docker" -Force
Remove-Item "$env:TEMP\docker-credential-wincred-v0.6.0-amd64.zip"


if ($lcowEnabled) {
	docker run --rm busybox echo hello_world
	
	# TODO
	# Mapping local folder to a Linux container:
	# docker run --rm -v C:\Test:/c-test busybox cat /c-test/readme.txt	
}

function PullRunDockerImages($minOsBuild, $serverCoreTag, $nanoServerTag) {
	$hypervFeature = (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online)
	$hypervInstalled = ($hypervFeature -and $hypervFeature.State -eq 'Enabled')

	if ($osVer.Build -ge $minOsBuild) {
		# Windows Server 2016 or above
		
		$isolation = $null
		if ($osVer.Build -gt $minOsBuild -and $hypervInstalled) {
			$isolation = 'hyperv'
		} elseif ($osVer.Build -eq $minOsBuild) {
			$isolation = 'default'
		}
		
		if ($isolation) {
			Write-Host "Pulling and running '$serverCoreTag' images in '$isolation' mode"
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/servercore:$serverCoreTag cmd /c echo hello_world
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/nanoserver:$nanoServerTag cmd /c echo hello_world	
		}
	}
}

PullRunDockerImages 14393 'ltsc2016' 'sac2016'
PullRunDockerImages 16299 '1709' '1709'
PullRunDockerImages 17134 '1803' '1803'
PullRunDockerImages 17763 'ltsc2019' '1809'