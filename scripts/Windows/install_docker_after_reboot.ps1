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

$hypervFeature = (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online)
$hypervInstalled = ($hypervFeature -and $hypervFeature.State -eq 'Enabled')
function PullRunDockerImages($minOsBuild, $serverCoreTag, $nanoServerTag) {
	if ($osVerBuild -ge $minOsBuild) {
		# Windows Server 2016 or above
		
		$isolation = $null
		if ($osVerBuild -gt $minOsBuild -and $hypervInstalled) {
			$isolation = 'hyperv'
		} elseif ($osVerBuild -eq $minOsBuild) {
			$isolation = 'default'
		}
		
		if ($isolation) {
			Write-Host "Pulling and running 'mcr.microsoft.com/windows/servercore:$serverCoreTag' image in '$isolation' mode" -ForegroundColor Magenta
			docker pull mcr.microsoft.com/windows/servercore:$serverCoreTag
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/servercore:$serverCoreTag cmd /c echo hello_world

			Write-Host "Pulling and running 'mcr.microsoft.com/windows/nanoserver:$serverCoreTag' image in '$isolation' mode" -ForegroundColor Magenta
			docker pull mcr.microsoft.com/windows/nanoserver:$nanoServerTag
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/nanoserver:$nanoServerTag cmd /c echo hello_world	
		}
	}
}

function PullDockerImage($imageName) {
	Write-Host "Pulling $imageName" -ForegroundColor Magenta
	docker pull $imageName
}

PullRunDockerImages 14393 'ltsc2016' 'sac2016'
PullRunDockerImages 16299 '1709' '1709'
PullRunDockerImages 17134 '1803' '1803'
PullRunDockerImages 17763 'ltsc2019' '1809'
PullRunDockerImages 18362 '1903' '1903'
PullRunDockerImages 18363 '1909' '1909'
PullRunDockerImages 19041 '2004' '2004'

if ($env:INSTALL_EXTRA_DOCKER_IMAGES) {
	# https://hub.docker.com/_/microsoft-dotnet-framework-sdk/
	PullDockerImage 'mcr.microsoft.com/dotnet/framework/sdk:4.8'
	PullDockerImage 'mcr.microsoft.com/dotnet/framework/sdk:3.5'

	# https://hub.docker.com/_/microsoft-dotnet-framework-aspnet/
	PullDockerImage 'mcr.microsoft.com/dotnet/framework/aspnet:4.8'
	PullDockerImage 'mcr.microsoft.com/dotnet/framework/aspnet:3.5'

	# https://hub.docker.com/_/microsoft-dotnet-core-sdk/
	PullDockerImage 'mcr.microsoft.com/dotnet/core/sdk:3.1'
	PullDockerImage 'mcr.microsoft.com/dotnet/core/sdk:2.1'
}

Write-Host "Installed Docker images:" -ForegroundColor Yellow
docker images --digests