. "$PSScriptRoot\common.ps1"

Write-warning "Checking if WSL feature is installed..."
$i = 0
$installed = $false
while ($i -lt 30) {
  $i += 1
  $installed = (Get-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online).State -eq 'Enabled'
  if ($installed) {
    Write-Host "WSL feature is installed"
    break
  }
  Write-warning "Retrying in 10 seconds..."
  Start-Sleep -s 10
}

if (-not $installed) {
    Write-Error "WSL feature is not installed"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Install-WslDistro {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [Parameter(Mandatory = $true)]
        [string]$DownloadUrl,

        [Parameter(Mandatory = $true)]
        [string]$PackagePath,

        [Parameter(Mandatory = $true)]
        [string]$InstallPath,

        [Parameter(Mandatory = $true)]
        [string]$LauncherName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("apt", "zypper", "none")]
        [string]$PackageManager = "none"
    )

    Write-Warning "Installing $DisplayName for WSL"

    if (Test-Path $PackagePath) {
        Remove-Item $PackagePath -Force
    }

    if (Test-Path $InstallPath) {
        Remove-Item $InstallPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null

    (New-Object Net.WebClient).DownloadFile($DownloadUrl, $PackagePath)

    $extractPath = "$InstallPath-extract"
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    tar -xf $PackagePath -C $extractPath

    $bundleManifest = Get-ChildItem $extractPath -Filter AppxBundleManifest.xml -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bundleManifest) {
        $x64Appx = Get-ChildItem $extractPath -Filter "*_x64.appx" -Recurse | Select-Object -First 1
        if (-not $x64Appx) {
            throw "Could not find x64 appx inside bundle for $DisplayName"
        }

        $innerAppxPath = $x64Appx.FullName
        $innerExtractPath = "$InstallPath-inner"
        if (Test-Path $innerExtractPath) {
            Remove-Item $innerExtractPath -Recurse -Force
        }
        New-Item -ItemType Directory -Path $innerExtractPath -Force | Out-Null
        tar -xf $innerAppxPath -C $innerExtractPath

        Remove-Item $extractPath -Recurse -Force
        Move-Item $innerExtractPath -Destination $extractPath
    }

    Get-ChildItem $extractPath -Force | ForEach-Object {
        Move-Item $_.FullName -Destination $InstallPath -Force
    }

    Remove-Item $PackagePath -Force -ErrorAction SilentlyContinue
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }

    $launcher = Get-ChildItem $InstallPath -Filter $LauncherName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $launcher) {
        $launcher = Get-ChildItem $InstallPath -Filter *.exe -Recurse | `
            Where-Object { $_.Name -notmatch 'vc_redist|setup|installer' } | `
            Select-Object -First 1
    }
    if (-not $launcher) {
        throw "Could not find distro launcher in $InstallPath"
    }

    $launcherPath = $launcher.FullName
    Write-Host "Using launcher $launcherPath"
    Start-ProcessWithOutput "`"$launcherPath`" install --root"
    Start-ProcessWithOutput "`"$launcherPath`" run adduser appveyor --gecos `"First,Last,RoomNumber,WorkPhone,HomePhone`" --disabled-password"
    Start-ProcessWithOutput "`"$launcherPath`" run `"echo 'appveyor:Password12!' | sudo chpasswd`""
    Start-ProcessWithOutput "`"$launcherPath`" run usermod -aG sudo appveyor"
    Start-ProcessWithOutput "`"$launcherPath`" run `"echo -e 'appveyor\tALL=(ALL)\tNOPASSWD: ALL' > /etc/sudoers.d/appveyor`""
    Start-ProcessWithOutput "`"$launcherPath`" run chmod 0755 /etc/sudoers.d/appveyor"
    Start-ProcessWithOutput "`"$launcherPath`" config --default-user appveyor"

    if ($PackageManager -eq "apt") {
        Start-ProcessWithOutput "`"$launcherPath`" run sudo apt-get update"
    }
    elseif ($PackageManager -eq "zypper") {
        Start-ProcessWithOutput "`"$launcherPath`" run sudo zypper --non-interactive refresh"
    }
}

$distros = @(
    @{
        DisplayName = "Ubuntu 20.04"
        DownloadUrl = "https://appveyordownloads.blob.core.windows.net/misc/Ubuntu_2004.2021.825.0_x64.zip"
        PackagePath = "$env:TEMP\wsl-ubuntu-2004.appx"
        InstallPath = "C:\WSL\Ubuntu2004"
        LauncherName = "ubuntu.exe"
        PackageManager = "apt"
    }
    @{
        DisplayName = "Ubuntu 22.04"
        DownloadUrl = "https://publicwsldistros.blob.core.windows.net/wsldistrostorage/Ubuntu2204LTS-230518_x64.appx"
        PackagePath = "$env:TEMP\wsl-ubuntu-2204.appx"
        InstallPath = "C:\WSL\Ubuntu2204"
        LauncherName = "ubuntu2204.exe"
        PackageManager = "apt"
    }
    @{
        DisplayName = "Ubuntu 24.04"
        DownloadUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/Ubuntu2404-240425.AppxBundle"
        PackagePath = "$env:TEMP\wsl-ubuntu-2404.appxbundle"
        InstallPath = "C:\WSL\Ubuntu2404"
        LauncherName = "ubuntu2404.exe"
        PackageManager = "apt"
    }
    @{
        DisplayName = "openSUSE Leap 15.6"
        DownloadUrl = "https://publicwsldistros.blob.core.windows.net/wsldistrostorage/SUSELeap15p6-240801_x64.Appx"
        PackagePath = "$env:TEMP\wsl-opensuse-leap-156.appx"
        InstallPath = "C:\WSL\OpenSUSE-Leap-15.6"
        LauncherName = "openSUSE-Leap-15.6.exe"
        PackageManager = "zypper"
    }
)

foreach ($distro in $distros) {
    Install-WslDistro `
        -DisplayName $distro.DisplayName `
        -DownloadUrl $distro.DownloadUrl `
        -PackagePath $distro.PackagePath `
        -InstallPath $distro.InstallPath `
        -LauncherName $distro.LauncherName `
        -PackageManager $distro.PackageManager
}

# Testing WSL
# ===========

wslconfig /setdefault Ubuntu-20.04
wsl lsb_release -a

wslconfig /setdefault Ubuntu-22.04
wsl lsb_release -a

wslconfig /setdefault Ubuntu-24.04
wsl lsb_release -a

wslconfig /setdefault openSUSE-Leap-15.6
wsl cat /etc/os-release

# Rename C:\Windows\System32\bash.exe to avoid conflicts with default Git's bash
# ===========

takeown /F "$env:SystemRoot\System32\bash.exe"
icacls "$env:SystemRoot\System32\bash.exe" /grant administrators:F
ren "$env:SystemRoot\System32\bash.exe" wsl-bash.exe
