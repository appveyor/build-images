. "$PSScriptRoot\install_qt_module.ps1"

# Delete old Qt 5.12.x
# It's examples and docs

$installDir = "$env:SystemDrive\Qt"

Write-Host "Deleting old Qt 5.12 installations..." -ForegroundColor Cyan

$versions_to_delete = @(
    "5.6",
    "5.9",
    "5.9.1",
    "5.9.2",
    "5.9.3",
    "5.9.4",
    "5.9.5",
    "5.9.7",
    "5.9.8",
    "5.10.0",
    "5.11.0",
    "5.11.1",
    "5.11.2",
    "5.12*",
    "5.13.0"
)

foreach($version_to_delete in $versions_to_delete) {

    # Delete Qt
    Write-Host "Deleting $version_to_delete installation..."
    Get-Item "$installDir\$version_to_delete" -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -Confirm:$false

    # Delete Docs
    Write-Host "Deleting $version_to_delete Docs..."
    Get-Item "$installDir\Docs\$version_to_delete" -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -Confirm:$false

    # Delete Examples
    Write-Host "Deleting $version_to_delete Examples..."
    Get-Item "$installDir\Examples\$version_to_delete" -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -Confirm:$false
}


Write-Host "Installing Qt 5.12.7 ..." -ForegroundColor Cyan

if ($env:VS_VERSION -eq "2017") {
    $component_groups = @(
        @{
            version = "5.12.7"
            components = @(
                "win32_msvc2017",
                "win64_msvc2017_64",
                "win32_mingw73",
                "win64_mingw73",
                "debug_info",
                "debug_info.win32_msvc2017",
                "debug_info.win64_msvc2017_64",
                "qtcharts",
                "qtcharts.win32_mingw73",
                "qtcharts.win32_msvc2017",
                "qtcharts.win64_mingw73",
                "qtcharts.win64_msvc2017_64",
            
                "qtquick3d",
                "qtquick3d.win32_mingw73",
                "qtquick3d.win32_msvc2017",
                "qtquick3d.win64_mingw73",
                "qtquick3d.win64_msvc2017_64",
            
                "qtdatavis3d",
                "qtdatavis3d.win32_mingw73",
                "qtdatavis3d.win32_msvc2017",
                "qtdatavis3d.win64_mingw73",
                "qtdatavis3d.win64_msvc2017_64",
                "qtlottie",
                "qtlottie.win32_mingw73",
                "qtlottie.win32_msvc2017",
                "qtlottie.win64_mingw73",
                "qtlottie.win64_msvc2017_64",
                "qtnetworkauth",
                "qtnetworkauth.win32_mingw73",
                "qtnetworkauth.win32_msvc2017",
                "qtnetworkauth.win64_mingw73",
                "qtnetworkauth.win64_msvc2017_64",
                "qtpurchasing",
                "qtpurchasing.win32_mingw73",
                "qtpurchasing.win32_msvc2017",
                "qtpurchasing.win64_mingw73",
                "qtpurchasing.win64_msvc2017_64",
                "qtscript",
                "qtscript.win32_mingw73",
                "qtscript.win32_msvc2017",
                "qtscript.win64_mingw73",
                "qtscript.win64_msvc2017_64",
                "qtvirtualkeyboard",
                "qtvirtualkeyboard.win32_mingw73",
                "qtvirtualkeyboard.win32_msvc2017",
                "qtvirtualkeyboard.win64_mingw73",
                "qtvirtualkeyboard.win64_msvc2017_64",
                "qtwebengine",
                "qtwebengine.win32_msvc2017",
                "qtwebengine.win64_msvc2017_64",
                "qtwebglplugin",
                "qtwebglplugin.win32_mingw73",
                "qtwebglplugin.win32_msvc2017",
                "qtwebglplugin.win64_mingw73",
                "qtwebglplugin.win64_msvc2017_64",
            
                "qtquicktimeline",
                "qtquicktimeline.win32_mingw73",
                "qtquicktimeline.win32_msvc2017",
                "qtquicktimeline.win64_mingw73",
                "qtquicktimeline.win64_msvc2017_64"
            )
        }
    )
}

if ($env:VS_VERSION -eq "2015") {
    $component_groups = @(
        @{
            version = "5.12.7"
            components = @(
                "win32_msvc2017",
                "win64_msvc2015_64",
                "win32_mingw73",
                "win64_mingw73",
                "debug_info",
                "debug_info.win64_msvc2015_64",
                "qtcharts",
                "qtcharts.win32_mingw73",
                "qtcharts.win64_mingw73",
                "qtcharts.win64_msvc2015_64",
            
                "qtquick3d",
                "qtquick3d.win32_mingw73",
                "qtquick3d.win64_mingw73",
                "qtquick3d.win64_msvc2015_64",
            
                "qtdatavis3d",
                "qtdatavis3d.win32_mingw73",
                "qtdatavis3d.win64_mingw73",
                "qtdatavis3d.win64_msvc2015_64",
                "qtlottie",
                "qtlottie.win32_mingw73",
                "qtlottie.win64_mingw73",
                "qtlottie.win64_msvc2015_64",
                "qtnetworkauth",
                "qtnetworkauth.win32_mingw73",
                "qtnetworkauth.win64_mingw73",
                "qtnetworkauth.win64_msvc2015_64",
                "qtpurchasing",
                "qtpurchasing.win32_mingw73",
                "qtpurchasing.win64_mingw73",
                "qtpurchasing.win64_msvc2015_64",
                "qtscript",
                "qtscript.win32_mingw73",
                "qtscript.win64_mingw73",
                "qtscript.win64_msvc2015_64",
                "qtvirtualkeyboard",
                "qtvirtualkeyboard.win32_mingw73",
                "qtvirtualkeyboard.win64_mingw73",
                "qtvirtualkeyboard.win64_msvc2015_64",
                "qtwebengine",
                "qtwebengine.win64_msvc2015_64",
                "qtwebglplugin",
                "qtwebglplugin.win32_mingw73",
                "qtwebglplugin.win64_mingw73",
                "qtwebglplugin.win64_msvc2015_64",
            
                "qtquicktimeline",
                "qtquicktimeline.win32_mingw73",
                "qtquicktimeline.win64_mingw73",
                "qtquicktimeline.win64_msvc2015_64"
            )
        }
    )
}


# install components
foreach($componentGroup in $component_groups) {
    if ($componentGroup.version) {
        foreach($component in $componentGroup.components) {
            Install-QtComponent -Version $componentGroup.version -Name $component -Path $installDir
        }
        ConfigureQtVersion $installDir $componentGroup.version
    } else {
        foreach($component in $componentGroup.components) {
            Install-QtComponent -Id $component -Path $installDir
        }
    }
}

$v56 = Get-Item "$installDir\5.6.*"
if ($v56) {
    cmd /c mklink /J "$installDir\5.6" $v56.FullName
}

$v59 = Get-Item "$installDir\5.9.*"
if ($v59) {
    cmd /c mklink /J "$installDir\5.9" $v59.FullName
}

$v512 = Get-Item "$installDir\5.12.*"
if ($v512) {
    cmd /c mklink /J "$installDir\5.12" $v512.FullName
}

Write-Host "Qt 5.12.7 installed" -ForegroundColor Green