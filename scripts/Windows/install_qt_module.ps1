# Mirrors: http://download.qt.io/static/mirrorlist/
# Mirrors2: https://download.qt.io/official_releases/qt/5.14/5.14.1/qt-opensource-windows-x86-5.14.1.exe.mirrorlist

$QT_INSTALL_DIR = "C:\Qt"
#$QT_ROOT_URL = 'https://download.qt.io/online/qtsdkrepository/windows_x86/desktop'
$QT_ROOT_URL = 'http://qt.mirror.constant.com/online/qtsdkrepository/windows_x86/desktop'

if ($isLinux) {
    $QT_ROOT_URL = 'http://qt.mirror.constant.com/online/qtsdkrepository/linux_x64/desktop'
} elseif ($isMacOS) {
    $QT_ROOT_URL = 'http://qt.mirror.constant.com/online/qtsdkrepository/mac_x64/desktop'
}

$TOOL_IDS = @(
    "cmake"
    "generic"
    "ifw"
    "maintenance"
    "maintenance_update_reminder"
    "ninja"
    "qt3dstudio"
    "qt3dstudio_openglruntime_240"
    "qt3dstudio_openglruntime_250"
    "qt3dstudio_openglruntime_260"    
    "qt3dstudio_runtime_220"
    "qt3dstudio_runtime_230"
    "qt3dstudio_runtime_240"
    "qtcreator"
    "telemetry"
)

if ($isLinux) {
    $TOOL_IDS += @(
        "openssl_src"
        "openssl_x64"        
    )
} elseif ($isMacOS) {
    $TOOL_IDS += @(
        "qt3dstudio_runtime"
        "qt3dstudio_runtime_210"
    )
} else {
    $TOOL_IDS += @(
        "mingw"
        "openssl_src"
        "openssl_x64"        
        "openssl_x86"
        "qt3dstudio_runtime"
        "qt3dstudio_runtime_210"
        "vcredist"
        )
}

$package_updates = @{}
$feeds_cache = @{}

function GetQtPrefix($version) {
    if ($version.startsWith('6')) {
        return 'qt6'
    } else {
        return 'qt5'
    }
}
function GetVersionId($version) {
    return $version.replace('.', '')
}

function GetReleaseRootUrl($version) {
    return "$QT_ROOT_URL/$(GetQtPrefix $version)_$(GetVersionId $version)"
}

function FetchToolsUpdatePackages($toolsId) {
    FetchUpdatePackages "$QT_ROOT_URL/tools_$toolsId"
}

function FetchReleaseUpdatePackages($version) {
    FetchUpdatePackages "$(GetReleaseRootUrl $version)"
    FetchUpdatePackages "$(GetReleaseRootUrl $version)_src_doc_examples"
}

function SplitString($str) {
    $arr = @()
    if ($str) {
        foreach($item in $str.split(',')) {
            $arr += $item.trim()
        }
    }
    return $arr
}

function GetTempDir() {
    if ($isLinux -or $isMacOS) {
        return "/tmp"
    } else {
        return $env:TEMP
    }
}

function FetchUpdatePackages($feedRootUrl) {
    $feedUrl = "$feedRootUrl/Updates.xml"
    if (-not $feeds_cache.ContainsKey($feedUrl)) {
        # load xml
        Write-Host "Fetching $feedUrl..." -NoNewline -ForegroundColor Gray
        $feedXml = [xml](New-Object Net.WebClient).DownloadString($feedUrl)
        $feeds_cache[$feedUrl] = $feedXml

        # index 'PackageUpdate' nodes
        $totalPackages = 0
        foreach($packageNode in $feedXml.Updates.PackageUpdate) {

            $package = @{
                BaseUrl = $feedRootUrl
                Name = $packageNode.Name
                DisplayName = $packageNode.DisplayName
                Version = $packageNode.Version
                Dependencies = SplitString $packageNode.Dependencies
                DownloadableArchives = SplitString $packageNode.DownloadableArchives
                Installed = $false
            }

            $package_updates[$package.Name] = $package
            $totalPackages++
        }
        Write-Host "$totalPackages"
    }
}

function Install-QtComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        $Version,
        [Parameter(Mandatory=$false)]
        $Name,
        [Parameter(Mandatory=$false)]
        $Id,
        [Parameter(Mandatory=$false)]
        $Path,
        [switch]$whatIf,
        [switch]$excludeDocs,
        [switch]$excludeExamples
    )

    if ($Version -and $Name) {
        FetchReleaseUpdatePackages $version
        InstallComponentById "qt.$(GetQtPrefix $version).$(GetVersionId $version).$Name" $Path -whatif:$whatIf -excludeDocs:$excludeDocs -excludeExamples:$excludeExamples
    } elseif ($Id) {
        InstallComponentById $Id $Path -whatif:$whatIf -excludeDocs:$excludeDocs -excludeExamples:$excludeExamples
    } else {
        throw "Either -Version and -Name should be specified or -Id."
    }
}

function InstallComponentById {
    param(
        $componentId,
        $destPath,
        [switch]$whatIf,
        [switch]$excludeDocs,
        [switch]$excludeExamples
    )

    Write-Host "Installing $componentId" -ForegroundColor Cyan

    $comp = $package_updates[$componentId]

    # if ($whatIf -eq $true) {
    #     $comp
    # }

    if (-not $destPath) {
        $destPath = $QT_INSTALL_DIR
    }

    if ($comp.Installed) {
        Write-Host "Already installed" -ForegroundColor Yellow
        return
    }    

    if ($excludeDocs -eq $true -and $componentId.EndsWith('.doc')) {
        Write-Host "Skipped documentation installation" -ForegroundColor Yellow
        return
    }
    if ($excludeExamples -eq $true  -and $componentId.EndsWith('.examples')) {
        Write-Host "Skipped examples installation" -ForegroundColor Yellow
        return
    }

    # download and extract component archives
    foreach($downloadableArchive in $comp.DownloadableArchives) {
        $fileName = "$($comp.Version)$downloadableArchive"
        $downloadUrl = "$($comp.BaseUrl)/$($comp.Name)/$fileName"
        $sha1 = (New-Object Net.WebClient).DownloadString("$downloadUrl.sha1")

        $tempDir = [IO.Path]::Combine((GetTempDir), "qt5-installer-temp")
        New-Item $tempDir -ItemType Directory -Force | Out-Null

        Write-Host "$($comp.Name)/$fileName - Downloading..." -NoNewline
        $tempFileName = [IO.Path]::Combine($tempDir, $fileName)

        try {
            (New-Object Net.WebClient).DownloadFile($downloadUrl, $tempFileName)
        } catch {
            Write-Host "Error downloading $($downloadUrl): $($_.Exception.Message)" -ForegroundColor Red

            # retrying
            Write-Host "Re-trying to download $($downloadUrl) in 5 seconds"
            Start-Sleep -s 5
            (New-Object Net.WebClient).DownloadFile($downloadUrl, $tempFileName)
        }

        $downloadedSha1 = (Get-FileHash -Algorithm SHA1 $tempFileName).Hash.ToLowerInvariant()

        if ($sha1 -ne $downloadedSha1) {
            throw "SHA1 hashes don't match for $downloadUrl ($sha1) and $tempFileName ($downloadedSha1)"
        }

        Write-Host "Extracting..." -NoNewline
        if ($isLinux -or $isMacOS) {
            7za x $tempFileName -aoa -o"$destPath" | Out-Null
        } else {
            7z x $tempFileName -aoa -o"$destPath" | Out-Null
        }

        Write-Host "OK" -ForegroundColor Green
        $comp.Installed = $true
        Remove-Item $tempFileName
    }

    # recurse dependencies
    foreach($dependencyId in $comp.Dependencies) {
        InstallComponentById $dependencyId $destPath -whatif:$whatIf -excludeDocs:$excludeDocs -excludeExamples:$excludeExamples
    }
}

function ConfigureQtVersion($qtRoot, $version) {
    $versionRoot = [IO.Path]::Combine($qtRoot, $version)
    foreach($componentDir in (Get-ChildItem $versionRoot)) {
        $componentPath = $componentDir.FullName
        $componentBin = [IO.Path]::Combine($componentPath, 'bin')

        # qt.conf
        if (Test-Path $componentBin) {
            $qtConfPath = [IO.Path]::Combine($componentBin, 'qt.conf')
            Write-Host "Creating $qtConfPath"

            Set-Content -Path $qtConfPath -Value "[Paths]
Documentation=../../Docs/Qt-$version
Examples=../../Examples/Qt-$version
Prefix=.."
        
            if (-not $isLinux -and -not $isMacOS) {
                $qtEnvPath = [IO.Path]::Combine($componentBin, 'qtenv2.bat')
                Write-Host "Creating $qtEnvPath"
    
                $mingwDir = $null
                if ($componentDir.Name -eq 'mingw73_32') {
                    $mingwDir = 'mingw730_32'
                } elseif ($componentDir.Name -eq 'mingw73_64') {
                    $mingwDir = 'mingw730_64'
                } elseif ($componentDir.Name -eq 'mingw53_32') {
                    $mingwDir = 'mingw530_32'
                } elseif ($componentDir.Name -eq 'mingw53_64') {
                    $mingwDir = 'mingw530_64'
                }
    
                if ($mingwDir) {
                    $mingwBin = [IO.Path]::Combine($qtRoot, 'Tools', $mingwDir, 'bin')
                    Set-Content -Path $qtEnvPath -Value "@echo off
    echo Setting up environment for Qt usage...
    set PATH=$componentBin;$mingwBin;%PATH%
    cd /D $componentPath"
                } else {
                    Set-Content -Path $qtEnvPath -Value "@echo off
    echo Setting up environment for Qt usage...
    set PATH=$componentBin;%PATH%
    cd /D $componentPath
    echo Remember to call vcvarsall.bat to complete environment setup!"
                }
            }
        }

        $mkspecPath = [IO.Path]::Combine($componentPath, 'mkspecs', 'qconfig.pri')
        if (Test-Path $mkspecPath) {
            Write-Host "Patching $mkspecPath"
            $spec = [IO.File]::ReadAllText($mkspecPath)
            $spec = $spec.Replace('QT_EDITION = Enterprise', 'QT_EDITION = OpenSource').Replace('QT_LICHECK = licheck.exe', 'QT_LICHECK =').Replace('QT_LICHECK = licheck64', 'QT_LICHECK =').Replace('QT_LICHECK = licheck_mac', 'QT_LICHECK =')
            [IO.File]::WriteAllText($mkspecPath, $spec)
        }
    }
}

# fetch tools packages
foreach($tool_id in $TOOL_IDS) {
    FetchToolsUpdatePackages $tool_id
}

# fetch licenses
FetchUpdatePackages "$QT_ROOT_URL/licenses"
