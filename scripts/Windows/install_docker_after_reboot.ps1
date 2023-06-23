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
			Write-Host "Pulling and running '$serverCoreTag' images in '$isolation' mode"
			docker pull mcr.microsoft.com/windows/servercore:$serverCoreTag
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/servercore:$serverCoreTag cmd /c echo hello_world

			docker pull mcr.microsoft.com/windows/nanoserver:$nanoServerTag
			docker run --rm --isolation=$isolation mcr.microsoft.com/windows/nanoserver:$nanoServerTag cmd /c echo hello_world	
		}
	}
}

#PullRunDockerImages 14393 'ltsc2016' 'sac2016'
#PullRunDockerImages 16299 '1709' '1709'
#PullRunDockerImages 17134 '1803' '1803'
PullRunDockerImages 17763 'ltsc2019' '1809'

docker pull mcr.microsoft.com/dotnet/framework/aspnet:4.8