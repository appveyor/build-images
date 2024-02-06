. "$PSScriptRoot\common.ps1"

Write-Host "Completing the configuration of Docker for Desktop..." 

Start-Sleep -s 10
$ErrorActionPreference = "Stop"
# stop docker first to remove sign up screen
Stop-Process -Name "Docker Desktop"

wsl -l -v

& "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"

# wait while  Docker Desktop is started
Start-Sleep -s 60


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
			Start-ProcessWithOutput "docker pull mcr.microsoft.com/windows/servercore:$serverCoreTag"
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/servercore:$serverCoreTag cmd /c echo hello_world
			
			Start-ProcessWithOutput "docker pull mcr.microsoft.com/windows/nanoserver:$nanoServerTag"
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/nanoserver:$nanoServerTag cmd /c echo hello_world	
		}
	}
}


Write-Host "Switching Docker to Linux mode..."
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchLinuxEngine
Start-Sleep -s 20
docker version -f '{{.Server.Os}}'
docker version

Start-ProcessWithOutput "docker pull busybox"
docker pull busybox -q
docker run --rm -v 'C:\:/user-profile' busybox ls /user-profile

Start-ProcessWithOutput "docker pull alpine"
docker run --rm alpine echo hello_world

Write-Host "Switching Docker to Windows mode..."
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchWindowsEngine
Start-Sleep -s 20
docker version -f '{{.Server.Os}}'
docker version

PullRunDockerImages 17763 'ltsc2019' '1809'

Start-ProcessWithOutput "docker pull mcr.microsoft.com/dotnet/framework/aspnet:4.8"

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
