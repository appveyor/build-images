. "$PSScriptRoot\common.ps1"

Write-Host "Installing minimal Qt 6.x set with Qt Online Installer..." -ForegroundColor Cyan

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$qtRoot = "C:\Qt"
$qtMirror = "http://qt.mirror.constant.com"
$installerUrl = "https://download.qt.io/official_releases/online_installers/qt-online-installer-windows-x64-online.exe"
$installerPath = "$env:TEMP\qt-online-installer-windows-x64-online.exe"

function Get-VersionId($version) {
    return $version.Replace('.', '')
}

function Get-QtPackageIds($version, $suffixes) {
    $versionId = Get-VersionId $version
    return $suffixes | ForEach-Object { "qt.qt6.$versionId.$_" }
}

function Invoke-QtInstall($toolPath, $packages, [switch]$UseRoot) {
    if (-not $packages -or $packages.Count -eq 0) {
        return
    }

    $arguments = @()
    if ($UseRoot) {
        $arguments += "--root `"$qtRoot`""
    }

    $arguments += @(
        "--mirror $qtMirror",
        "--accept-licenses",
        "--accept-obligations",
        "--default-answer",
        "--confirm-command",
        "install"
    )
    $arguments += $packages

    Start-ProcessWithOutput "`"$toolPath`" $($arguments -join ' ')"
}

function CreateJunction($link, $target) {
    if (Test-Path $link) {
        $existingItem = Get-Item $link -Force
        if (-not ($existingItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Refusing to replace existing non-junction path '$link'."
        }

        Remove-Item $link -Force
    }

    cmd /c mklink /J $link $target | Out-Null
}

$qtTools = @(
    "qt.tools.win32_mingw530",
    "qt.tools.win32_mingw810",
    "qt.tools.win64_mingw810",
    "qt.tools.win64_mingw900",
    "qt.tools.ifw.47",
    "qt.license.thirdparty"
)

$qtExtensionGroups = @(
    @{
        version = "6.11.1"
        packages = @(
            "extensions.qtwebengine.6111.win64_msvc2022_64",
            "extensions.qtwebengine.6111.win64_msvc2022_arm64_cross_compiled",
            "extensions.qtpdf.6111.win64_msvc2022_64",
            "extensions.qtpdf.6111.win64_msvc2022_arm64_cross_compiled"
        )
    }
    @{
        version = "6.10.3"
        packages = @(
            "extensions.qtwebengine.6103.win64_msvc2022_64",
            "extensions.qtwebengine.6103.win64_msvc2022_arm64_cross_compiled",
            "extensions.qtpdf.6103.win64_msvc2022_64",
            "extensions.qtpdf.6103.win64_msvc2022_arm64_cross_compiled"
        )
    }
)

$qtAliasGroups = @(
    @{
        version = "6.11.1"
        packages = @(
            "qt6.11.1-sdk"
        )
    }
    @{
        version = "6.10.3"
        packages = @(
            "qt6.10.3-sdk"
        )
    }
)

New-Item $qtRoot -ItemType Directory -Force | Out-Null

Write-Host "Downloading Qt Online Installer..." -ForegroundColor Cyan
(New-Object Net.WebClient).DownloadFile($installerUrl, $installerPath)

$primaryVersion = "6.11.1"
$primaryPackages = $qtAliasGroups[0].packages + $qtExtensionGroups[0].packages + $qtTools
Invoke-QtInstall $installerPath $primaryPackages -UseRoot

$maintenanceTool = Join-Path $qtRoot "MaintenanceTool.exe"
if (-not (Test-Path $maintenanceTool)) {
    throw "Qt Maintenance Tool was not created at '$maintenanceTool'."
}

$secondaryVersion = "6.10.3"
$secondaryPackages = $qtAliasGroups[1].packages + $qtExtensionGroups[1].packages
Invoke-QtInstall $maintenanceTool $secondaryPackages

if (-not (Test-Path "C:\Qt\6.11.1")) {
    throw "Qt 6.11.1 was not installed under '$qtRoot'."
}

if (-not (Test-Path "C:\Qt\6.10.3")) {
    throw "Qt 6.10.3 was not installed under '$qtRoot'."
}

CreateJunction -link "C:\Qt\6.11" -target "C:\Qt\6.11.1"
CreateJunction -link "C:\Qt\6.10" -target "C:\Qt\6.10.3"

Remove-Item $installerPath -Force -ErrorAction SilentlyContinue

Write-Host "Installed Qt 6.11.1 and 6.10.3 with Qt Online Installer" -ForegroundColor Green
