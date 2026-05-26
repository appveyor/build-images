Write-Host "Installing minimal Qt 6.x set ..." -ForegroundColor Cyan

. "$PSScriptRoot\install_qt_module.ps1"

$installDir = "C:\Qt"

$modernComponents = @(
    "win64_mingw",
    "win64_msvc2022_64",
    "win64_msvc2022_arm64_cross_compiled",
    "debug_info",
    "debug_info.win64_mingw",
    "debug_info.win64_msvc2022_64",
    "debug_info.win64_msvc2022_arm64_cross_compiled",

    "addons.qt3d",
    "addons.qt3d.win64_mingw",
    "addons.qt3d.win64_msvc2022_64",
    "addons.qt3d.win64_msvc2022_arm64_cross_compiled",

    "addons.qtactiveqt",
    "addons.qtactiveqt.win64_mingw",
    "addons.qtactiveqt.win64_msvc2022_64",
    "addons.qtactiveqt.win64_msvc2022_arm64_cross_compiled",

    "addons.qtcharts",
    "addons.qtcharts.win64_mingw",
    "addons.qtcharts.win64_msvc2022_64",
    "addons.qtcharts.win64_msvc2022_arm64_cross_compiled",

    "addons.qtconnectivity",
    "addons.qtconnectivity.win64_mingw",
    "addons.qtconnectivity.win64_msvc2022_64",
    "addons.qtconnectivity.win64_msvc2022_arm64_cross_compiled",

    "addons.qtdatavis3d",
    "addons.qtdatavis3d.win64_mingw",
    "addons.qtdatavis3d.win64_msvc2022_64",
    "addons.qtdatavis3d.win64_msvc2022_arm64_cross_compiled",

    "addons.qtgraphs",
    "addons.qtgraphs.win64_mingw",
    "addons.qtgraphs.win64_msvc2022_64",
    "addons.qtgraphs.win64_msvc2022_arm64_cross_compiled",

    "addons.qtgrpc",
    "addons.qtgrpc.win64_mingw",
    "addons.qtgrpc.win64_msvc2022_64",
    "addons.qtgrpc.win64_msvc2022_arm64_cross_compiled",

    "addons.qthttpserver",
    "addons.qthttpserver.win64_mingw",
    "addons.qthttpserver.win64_msvc2022_64",
    "addons.qthttpserver.win64_msvc2022_arm64_cross_compiled",

    "addons.qtimageformats",
    "addons.qtimageformats.win64_mingw",
    "addons.qtimageformats.win64_msvc2022_64",
    "addons.qtimageformats.win64_msvc2022_arm64_cross_compiled",

    "addons.qtlanguageserver",
    "addons.qtlanguageserver.win64_mingw",
    "addons.qtlanguageserver.win64_msvc2022_64",
    "addons.qtlanguageserver.win64_msvc2022_arm64_cross_compiled",

    "addons.qtlocation",
    "addons.qtlocation.win64_mingw",
    "addons.qtlocation.win64_msvc2022_64",
    "addons.qtlocation.win64_msvc2022_arm64_cross_compiled",

    "addons.qtlottie",
    "addons.qtlottie.win64_mingw",
    "addons.qtlottie.win64_msvc2022_64",
    "addons.qtlottie.win64_msvc2022_arm64_cross_compiled",

    "addons.qtmultimedia",
    "addons.qtmultimedia.win64_mingw",
    "addons.qtmultimedia.win64_msvc2022_64",
    "addons.qtmultimedia.win64_msvc2022_arm64_cross_compiled",

    "addons.qtnetworkauth",
    "addons.qtnetworkauth.win64_mingw",
    "addons.qtnetworkauth.win64_msvc2022_64",
    "addons.qtnetworkauth.win64_msvc2022_arm64_cross_compiled",

    "addons.qtpositioning",
    "addons.qtpositioning.win64_mingw",
    "addons.qtpositioning.win64_msvc2022_64",
    "addons.qtpositioning.win64_msvc2022_arm64_cross_compiled",

    "addons.qtquick3dphysics",
    "addons.qtquick3dphysics.win64_mingw",
    "addons.qtquick3dphysics.win64_msvc2022_64",
    "addons.qtquick3dphysics.win64_msvc2022_arm64_cross_compiled",

    "addons.qtquickeffectmaker",
    "addons.qtquickeffectmaker.win64_mingw",
    "addons.qtquickeffectmaker.win64_msvc2022_64",

    "addons.qtremoteobjects",
    "addons.qtremoteobjects.win64_mingw",
    "addons.qtremoteobjects.win64_msvc2022_64",
    "addons.qtremoteobjects.win64_msvc2022_arm64_cross_compiled",

    "addons.qtscxml",
    "addons.qtscxml.win64_mingw",
    "addons.qtscxml.win64_msvc2022_64",
    "addons.qtscxml.win64_msvc2022_arm64_cross_compiled",

    "addons.qtsensors",
    "addons.qtsensors.win64_mingw",
    "addons.qtsensors.win64_msvc2022_64",
    "addons.qtsensors.win64_msvc2022_arm64_cross_compiled",

    "addons.qtserialbus",
    "addons.qtserialbus.win64_mingw",
    "addons.qtserialbus.win64_msvc2022_64",
    "addons.qtserialbus.win64_msvc2022_arm64_cross_compiled",

    "addons.qtserialport",
    "addons.qtserialport.win64_mingw",
    "addons.qtserialport.win64_msvc2022_64",
    "addons.qtserialport.win64_msvc2022_arm64_cross_compiled",

    "addons.qtspeech",
    "addons.qtspeech.win64_mingw",
    "addons.qtspeech.win64_msvc2022_64",
    "addons.qtspeech.win64_msvc2022_arm64_cross_compiled",

    "addons.qtvirtualkeyboard",
    "addons.qtvirtualkeyboard.win64_mingw",
    "addons.qtvirtualkeyboard.win64_msvc2022_64",
    "addons.qtvirtualkeyboard.win64_msvc2022_arm64_cross_compiled",

    "addons.qtwebchannel",
    "addons.qtwebchannel.win64_mingw",
    "addons.qtwebchannel.win64_msvc2022_64",
    "addons.qtwebchannel.win64_msvc2022_arm64_cross_compiled",

    "addons.qtwebsockets",
    "addons.qtwebsockets.win64_mingw",
    "addons.qtwebsockets.win64_msvc2022_64",
    "addons.qtwebsockets.win64_msvc2022_arm64_cross_compiled",

    "addons.qtwebview",
    "addons.qtwebview.win64_mingw",
    "addons.qtwebview.win64_msvc2022_64",

    "addons.qt5compat",
    "addons.qt5compat.win64_mingw",
    "addons.qt5compat.win64_msvc2022_64",
    "addons.qt5compat.win64_msvc2022_arm64_cross_compiled",

    "addons.qtquick3d",
    "addons.qtquick3d.win64_mingw",
    "addons.qtquick3d.win64_msvc2022_64",
    "addons.qtquick3d.win64_msvc2022_arm64_cross_compiled",

    "addons.qtquicktimeline",
    "addons.qtquicktimeline.win64_mingw",
    "addons.qtquicktimeline.win64_msvc2022_64",
    "addons.qtquicktimeline.win64_msvc2022_arm64_cross_compiled",

    "addons.qtshadertools",
    "addons.qtshadertools.win64_mingw",
    "addons.qtshadertools.win64_msvc2022_64",
    "addons.qtshadertools.win64_msvc2022_arm64_cross_compiled"
)

$component_groups = @(
    @{
        version    = "6.11.1"
        components = $modernComponents
    }
    @{
        version    = "6.10.3"
        components = $modernComponents
    }
    @{
        components = @(
            "qt.tools.win32_mingw530",
            "qt.tools.win32_mingw810",
            "qt.tools.win64_mingw810",
            "qt.tools.win64_mingw900",
            "qt.tools.ifw.47",
            "qt.license.thirdparty"
        )
    }
)

$extension_groups = @(
    @{
        version = "6.11.1"
        extensions = @(
            "extensions.qtwebengine.6111.win64_msvc2022_64"
            "extensions.qtwebengine.6111.win64_msvc2022_arm64_cross_compiled"
            "extensions.qtpdf.6111.win64_msvc2022_64"
            "extensions.qtpdf.6111.win64_msvc2022_arm64_cross_compiled"
        )
    }
    @{
        version = "6.10.3"
        extensions = @(
            "extensions.qtwebengine.6103.win64_msvc2022_64"
            "extensions.qtwebengine.6103.win64_msvc2022_arm64_cross_compiled"
            "extensions.qtpdf.6103.win64_msvc2022_64"
            "extensions.qtpdf.6103.win64_msvc2022_arm64_cross_compiled"
        )
    }
)

foreach ($componentGroup in $component_groups) {
    if ($componentGroup.version) {
        $newPath = [IO.Path]::Combine($installDir, $componentGroup.version)
        foreach ($component in $componentGroup.components) {
            Install-QtComponent -Version $componentGroup.version -Name $component -Path $newPath
        }
        ConfigureQtVersion $installDir $componentGroup.version
    }
    else {
        foreach ($component in $componentGroup.components) {
            Install-QtComponent -Id $component -Path $installDir
        }
    }
}

foreach ($extensionGroup in $extension_groups) {
    $newPath = [IO.Path]::Combine($installDir, $extensionGroup.version)
    foreach ($extension in $extensionGroup.extensions) {
        Install-QtExtension -Version $extensionGroup.version -Name $extension -Path $newPath
    }
}

Write-Host "Compacting C:\Qt..." -NoNewline
compact /c /i /s:C:\Qt | Out-Null
Write-Host "OK" -ForegroundColor Green

$sym_links = @{
    "6.11" = "6.11.1"
    "6.10" = "6.10.3"
}

foreach ($link in $sym_links.Keys) {
    $target = $sym_links[$link]
    New-Item -ItemType SymbolicLink -Path "$installDir\$link" -Target "$installDir\$target" -Force | Out-Null
}

Write-Host "Minimal Qt 6.x installed" -ForegroundColor Green
