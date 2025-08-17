Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

. "$PSScriptRoot/install_qt_module.ps1"

$installDir = "$env:HOME/Qt"

$component_groups = @(
    @{
        version    = "6.9.1"
        components = @(
            "linux_gcc_64",
            "debug_info",
            "debug_info.linux_gcc64",
            "addons.qt3d",
            "addons.qt3d.linux_gcc64",
            "addons.qtcharts",
            "addons.qtcharts.linux_gcc64",
            "addons.qtconnectivity",
            "addons.qtconnectivity.linux_gcc64",
            "addons.qtdatavis3d",
            "addons.qtdatavis3d.linux_gcc64",
            "addons.qthttpserver",
            "addons.qthttpserver.linux_gcc64",
            "addons.qtimageformats",
            "addons.qtimageformats.linux_gcc64",
            "addons.qtlanguageserver",
            "addons.qtlanguageserver.linux_gcc64",
            "addons.qtlottie",
            "addons.qtlottie.linux_gcc64",
            "addons.qtmultimedia",
            "addons.qtmultimedia.linux_gcc64",
            "addons.qtnetworkauth",
            "addons.qtnetworkauth.linux_gcc64",
            "addons.qtpdf",
            "addons.qtpdf.linux_gcc64",
            "addons.qtpositioning",
            "addons.qtpositioning.linux_gcc64",
            "addons.qtquick3dphysics",
            "addons.qtquick3dphysics.linux_gcc64",
            "addons.qtremoteobjects",
            "addons.qtremoteobjects.linux_gcc64",
            "addons.qtscxml",
            "addons.qtscxml.linux_gcc64",
            "addons.qtsensors",
            "addons.qtsensors.linux_gcc64",
            "addons.qtserialbus",
            "addons.qtserialbus.linux_gcc64",
            "addons.qtserialport",
            "addons.qtserialport.linux_gcc64",
            "addons.qtspeech",
            "addons.qtspeech.linux_gcc64",
            "addons.qtvirtualkeyboard",
            "addons.qtvirtualkeyboard.linux_gcc64",
            "addons.qtwebchannel",
            "addons.qtwebchannel.linux_gcc64",
            "addons.qtwebengine",
            "addons.qtwebengine.linux_gcc64",
            "addons.qtwebsockets",
            "addons.qtwebsockets.linux_gcc64",
            "addons.qtwebview",
            "addons.qtwebview.linux_gcc64",
            "qt5compat",
            "qt5compat.linux_gcc64",
            "qtquick3d",
            "qtquick3d.linux_gcc64",
            "qtquicktimeline",
            "qtquicktimeline.linux_gcc64",
            "qtshadertools",
            "qtshadertools.linux_gcc64",
            "qtwaylandcompositor",
            "qtwaylandcompositor.linux_gcc64"
        )
    }
)

if (-not $env:INSTALL_LATEST_ONLY) {
    $component_groups += @(
        @{
            version    = "6.8.3"
            components = @(
                "linux_gcc_64",
                "debug_info",
                "debug_info.linux_gcc64",
                "addons.qt3d",
                "addons.qt3d.linux_gcc64",
                "addons.qtcharts",
                "addons.qtcharts.linux_gcc64",
                "addons.qtconnectivity",
                "addons.qtconnectivity.linux_gcc64",
                "addons.qtdatavis3d",
                "addons.qtdatavis3d.linux_gcc64",
                "addons.qthttpserver",
                "addons.qthttpserver.linux_gcc64",
                "addons.qtimageformats",
                "addons.qtimageformats.linux_gcc64",
                "addons.qtlanguageserver",
                "addons.qtlanguageserver.linux_gcc64",
                "addons.qtlottie",
                "addons.qtlottie.linux_gcc64",
                "addons.qtmultimedia",
                "addons.qtmultimedia.linux_gcc64",
                "addons.qtnetworkauth",
                "addons.qtnetworkauth.linux_gcc64",
                "addons.qtpdf",
                "addons.qtpdf.linux_gcc64",
                "addons.qtpositioning",
                "addons.qtpositioning.linux_gcc64",
                "addons.qtquick3dphysics",
                "addons.qtquick3dphysics.linux_gcc64",
                "addons.qtremoteobjects",
                "addons.qtremoteobjects.linux_gcc64",
                "addons.qtscxml",
                "addons.qtscxml.linux_gcc64",
                "addons.qtsensors",
                "addons.qtsensors.linux_gcc64",
                "addons.qtserialbus",
                "addons.qtserialbus.linux_gcc64",
                "addons.qtserialport",
                "addons.qtserialport.linux_gcc64",
                "addons.qtspeech",
                "addons.qtspeech.linux_gcc64",
                "addons.qtvirtualkeyboard",
                "addons.qtvirtualkeyboard.linux_gcc64",
                "addons.qtwebchannel",
                "addons.qtwebchannel.linux_gcc64",
                "addons.qtwebengine",
                "addons.qtwebengine.linux_gcc64",
                "addons.qtwebsockets",
                "addons.qtwebsockets.linux_gcc64",
                "addons.qtwebview",
                "addons.qtwebview.linux_gcc64",
                "qt5compat",
                "qt5compat.linux_gcc64",
                "qtquick3d",
                "qtquick3d.linux_gcc64",
                "qtquicktimeline",
                "qtquicktimeline.linux_gcc64",
                "qtshadertools",
                "qtshadertools.linux_gcc64",
                "qtwaylandcompositor",
                "qtwaylandcompositor.linux_gcc64"
            )
        }
        @{
            version    = "6.5.3"
            components = @(
                "gcc_64",
                "debug_info",
                "debug_info.gcc_64",
                "addons.qt3d",
                "addons.qt3d.gcc_64",
                "addons.qtcharts",
                "addons.qtcharts.gcc_64",
                "addons.qtdatavis3d",
                "addons.qtdatavis3d.gcc_64",
                "addons.qtimageformats",
                "addons.qtimageformats.gcc_64",
                "addons.qtlottie",
                "addons.qtlottie.gcc_64",
                "addons.qtnetworkauth",
                "addons.qtnetworkauth.gcc_64",
                "addons.qtscxml",
                "addons.qtscxml.gcc_64",
                "addons.qtvirtualkeyboard",
                "addons.qtvirtualkeyboard.gcc_64",
                "qt5compat",
                "qt5compat.gcc_64",
                "qtquick3d",
                "qtquick3d.gcc_64",
                "qtquicktimeline",
                "qtquicktimeline.gcc_64",
                "qtshadertools",
                "qtshadertools.gcc_64",
                "qtwaylandcompositor",
                "qtwaylandcompositor.gcc_64"
            )
        }
        @{
            version    = "5.15.2"
            components = @(
                "gcc_64",
                "debug_info",
                "debug_info.gcc_64",
                "qtcharts",
                "qtcharts.gcc_64",
                "qtdatavis3d",
                "qtdatavis3d.gcc_64",
                "qtlottie",
                "qtlottie.gcc_64"
                "qtnetworkauth",
                "qtnetworkauth.gcc_64",
                "qtpurchasing",
                "qtpurchasing.gcc_64",
                "qtquick3d",
                "qtquick3d.gcc_64",
                "qtquicktimeline",
                "qtquicktimeline.gcc_64",
                "qtscript",
                "qtscript.gcc_64",
                "qtvirtualkeyboard",
                "qtvirtualkeyboard.gcc_64",
                "qtwaylandcompositor",
                "qtwaylandcompositor.gcc_64",
                "qtwebengine",
                "qtwebengine.gcc_64",
                "qtwebglplugin",
                "qtwebglplugin.gcc_64"
            )
        }
    )
}

$component_groups += @(
    @{
        components = @(
            "qt.tools.ifw.47",
            "qt.license.thirdparty"
        )
    }
)

# install components
foreach ($componentGroup in $component_groups) {
    if ($componentGroup.version) {
        foreach ($component in $componentGroup.components) {
            Install-QtComponent -Version $componentGroup.version -Name $component -Path $installDir
        }
        ConfigureQtVersion $installDir $componentGroup.version
    }
    else {
        foreach ($component in $componentGroup.components) {
            Install-QtComponent -Id $component -Path $installDir
        }
    }
}

# set aliases
ln -s "$HOME/Qt/5.15.2" "$HOME/Qt/latest"
ln -s "$HOME/Qt/6.9.1" "$HOME/Qt/6.9"
ln -s "$HOME/Qt/6.8.3" "$HOME/Qt/6.8"
ln -s "$HOME/Qt/6.5.3" "$HOME/Qt/6.5"
ln -s "$HOME/Qt/5.15.2" "$HOME/Qt/5.15"

Write-Host "Qt 5.x installed" -ForegroundColor Green
