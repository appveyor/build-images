Write-Host "Completing the configuration of Docker for Desktop..." 

$ErrorActionPreference = "Stop"

# start Docker
& "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"

# wait while  Docker Desktop is started

$i = 0
$finished = $false

Write-Host "Waiting for Docker to start..."

while ($i -lt (300)) {
  $i +=1
  
  $dockerSvc = (Get-Service com.docker.service -ErrorAction SilentlyContinue)
  if ((Get-Process 'Docker Desktop' -ErrorAction SilentlyContinue) -and $dockerSvc -and $dockerSvc.status -eq 'Running') {
    $finished = $true
    Write-Host "Docker started!"
    break
  }
  Write-Host "Retrying in 5 seconds..."
  sleep 5;
}

if (-not $finished) {
    Throw "Docker has not started"
}

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

function PullRunDockerImages($minOsBuild, $serverCoreTag, $nanoServerTag) {
	$hypervFeature = (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online)
	$hypervInstalled = ($hypervFeature -and $hypervFeature.State -eq 'Enabled')

	if ($osVerBuild -ge $minOsBuild) {
		# Windows Server 2016 or above
		
		$isolation = $null
		if ($osVerBuild -gt $minOsBuild -and $hypervInstalled) {
			$isolation = 'hyperv'
		} elseif ($osVerBuild -eq $minOsBuild) {
			$isolation = 'default'
		}
		
		if ($isolation) {
			Write-Host "Pulling and running '$serverCoreTag' images in '$isolation' mode"
			docker pull mcr.microsoft.com/windows/servercore:$serverCoreTag
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/servercore:$serverCoreTag cmd /c echo hello_world

			docker pull mcr.microsoft.com/windows/nanoserver:$nanoServerTag
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/nanoserver:$nanoServerTag cmd /c echo hello_world	
		}
	}
}

Write-Host "Setting experimental mode"
$configPath = "$env:programdata\docker\config\daemon.json"
if (Test-Path $configPath) {
  $daemonConfig = Get-Content $configPath | ConvertFrom-Json
  $daemonConfig | Add-Member NoteProperty "experimental" $true -force
  $daemonConfig | ConvertTo-Json -Depth 20 | Set-Content -Path $configPath
} else {
  New-Item "$env:programdata\docker\config" -ItemType Directory -Force | Out-Null
  Set-Content -Path $configPath -Value '{ "experimental": true }'
}

Write-Host "Switching Docker to Linux mode..."
Switch-DockerLinux
docker version

docker pull busybox
docker run --rm -v 'C:\:/user-profile' busybox ls /user-profile

docker pull alpine
docker run --rm alpine echo hello_world

Write-Host "Switching Docker to Windows mode..."
Switch-DockerWindows
docker version

docker pull busybox
docker run --rm -v "$env:USERPROFILE`:/user-profile" busybox ls /user-profile

if (-not $env:INSTALL_LATEST_ONLY) {
	PullRunDockerImages 14393 'ltsc2016' 'sac2016'
	PullRunDockerImages 17134 '1803' '1803'
}
PullRunDockerImages 17763 'ltsc2019' '1809'

docker pull mcr.microsoft.com/dotnet/framework/aspnet:4.8

Write-Host "Disable SMB share for disk C:"
Remove-SmbShare -Name C -ErrorAction SilentlyContinue -Force

# enable Docker auto run
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Docker Desktop" `
	-Value "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"

Write-Host "Disabling automatic updates and usage statistics"
$settingsPath = "$env:appdata\Docker\settings.json"
if (Test-Path $settingsPath) {
	$dockerSettings = Get-Content $settingsPath | ConvertFrom-Json
	$dockerSettings | Add-Member NoteProperty "checkForUpdates" $false -force
	$dockerSettings | Add-Member NoteProperty "analyticsEnabled" $false -force
	$dockerSettings | ConvertTo-Json -Depth 20 | Set-Content -Path $settingsPath
} else {
	Write-Warning "$settingsPath was not found!"
}

Write-Host "Docker CE installed and configured"

#Switch-DockerLinux