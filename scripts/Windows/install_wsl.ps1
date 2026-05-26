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
        [string]$InstallPath
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

    $bundleExtractPath = "$InstallPath-bundle"
    if (Test-Path $bundleExtractPath) {
        Remove-Item $bundleExtractPath -Recurse -Force
    }

    $extension = [IO.Path]::GetExtension($PackagePath)
    if ($extension -eq ".appxbundle") {
        New-Item -ItemType Directory -Path $bundleExtractPath -Force | Out-Null
        tar -xf $PackagePath -C $bundleExtractPath
        $x64Appx = Get-ChildItem $bundleExtractPath -Filter "*_x64.appx" | Select-Object -First 1
        if (-not $x64Appx) {
            throw "Could not find x64 appx inside $PackagePath"
        }
        tar -xf $x64Appx.FullName -C $InstallPath
    }
    else {
        tar -xf $PackagePath -C $InstallPath
    }

    Remove-Item $PackagePath -Force
    if (Test-Path $bundleExtractPath) {
        Remove-Item $bundleExtractPath -Recurse -Force
    }

    $launcher = Get-ChildItem $InstallPath -Filter *.exe | Select-Object -First 1
    if (-not $launcher) {
        throw "Could not find distro launcher in $InstallPath"
    }

    $launcherPath = $launcher.FullName
    & $launcherPath install --root
    & $launcherPath run adduser appveyor --gecos `"First,Last,RoomNumber,WorkPhone,HomePhone`" --disabled-password
    & $launcherPath run "echo 'appveyor:Password12!' | sudo chpasswd"
    & $launcherPath run usermod -aG sudo appveyor
    & $launcherPath run "echo -e `"`"appveyor\tALL=(ALL)\tNOPASSWD: ALL`"`" > /etc/sudoers.d/appveyor"
    & $launcherPath run chmod 0755 /etc/sudoers.d/appveyor
    & $launcherPath config --default-user appveyor
    & $launcherPath run sudo apt-get update 2>$null
    & $launcherPath run sudo zypper --non-interactive refresh 2>$null
}

$distros = @(
    @{
        DisplayName = "Ubuntu 20.04"
        DownloadUrl = "https://aka.ms/wslubuntu2004"
        PackagePath = "$env:TEMP\wsl-ubuntu-2004.appx"
        InstallPath = "C:\WSL\Ubuntu2004"
    }
    @{
        DisplayName = "Ubuntu 22.04"
        DownloadUrl = "https://aka.ms/wslubuntu2204"
        PackagePath = "$env:TEMP\wsl-ubuntu-2204.appx"
        InstallPath = "C:\WSL\Ubuntu2204"
    }
    @{
        DisplayName = "Ubuntu 24.04"
        DownloadUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/Ubuntu2404-240425.AppxBundle"
        PackagePath = "$env:TEMP\wsl-ubuntu-2404.appxbundle"
        InstallPath = "C:\WSL\Ubuntu2404"
    }
    @{
        DisplayName = "openSUSE Leap 15.6"
        DownloadUrl = "https://publicwsldistros.blob.core.windows.net/wsldistrostorage/SUSELeap15p6-240801_x64.Appx"
        PackagePath = "$env:TEMP\wsl-opensuse-leap-156.appx"
        InstallPath = "C:\WSL\OpenSUSE-Leap-15.6"
    }
)

foreach ($distro in $distros) {
    Install-WslDistro `
        -DisplayName $distro.DisplayName `
        -DownloadUrl $distro.DownloadUrl `
        -PackagePath $distro.PackagePath `
        -InstallPath $distro.InstallPath
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
