Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

. "$PSScriptRoot/install_qt_module.ps1"

$installDir = "$env:HOME/Qt"

$component_groups = @(
    @{
        version    = "6.9.2"
        components = @(
            "linux_gcc_64",
            "debug_info",
            "debug_info.linux_gcc_64",
            "addons.qt3d",
            "addons.qt3d.linux_gcc_64",
            "addons.qtcharts",
            "addons.qtcharts.linux_gcc_64",
            "addons.qtconnectivity",
            "addons.qtconnectivity.linux_gcc_64",
            "addons.qtdatavis3d",
            "addons.qtdatavis3d.linux_gcc_64",
            "addons.qthttpserver",
            "addons.qthttpserver.linux_gcc_64",
            "addons.qtimageformats",
            "addons.qtimageformats.linux_gcc_64",
            "addons.qtlanguageserver",
            "addons.qtlanguageserver.linux_gcc_64",
            "addons.qtlottie",
            "addons.qtlottie.linux_gcc_64",
            "addons.qtmultimedia",
            "addons.qtmultimedia.linux_gcc_64",
            "addons.qtnetworkauth",
            "addons.qtnetworkauth.linux_gcc_64",
            "addons.qtpdf",
            "addons.qtpdf.linux_gcc_64",
            "addons.qtpositioning",
            "addons.qtpositioning.linux_gcc_64",
            "addons.qtquick3dphysics",
            "addons.qtquick3dphysics.linux_gcc_64",
            "addons.qtremoteobjects",
            "addons.qtremoteobjects.linux_gcc_64",
            "addons.qtscxml",
            "addons.qtscxml.linux_gcc_64",
            "addons.qtsensors",
            "addons.qtsensors.linux_gcc_64",
            "addons.qtserialbus",
            "addons.qtserialbus.linux_gcc_64",
            "addons.qtserialport",
            "addons.qtserialport.linux_gcc_64",
            "addons.qtspeech",
            "addons.qtspeech.linux_gcc_64",
            "addons.qtvirtualkeyboard",
            "addons.qtvirtualkeyboard.linux_gcc_64",
            "addons.qtwebchannel",
            "addons.qtwebchannel.linux_gcc_64",
            "addons.qtwebengine",
            "addons.qtwebengine.linux_gcc_64",
            "addons.qtwebsockets",
            "addons.qtwebsockets.linux_gcc_64",
            "addons.qtwebview",
            "addons.qtwebview.linux_gcc_64",
            "qt5compat",
            "qt5compat.linux_gcc_64",
            "qtquick3d",
            "qtquick3d.linux_gcc_64",
            "qtquicktimeline",
            "qtquicktimeline.linux_gcc_64",
            "qtshadertools",
            "qtshadertools.linux_gcc_64",
            "qtwaylandcompositor",
            "qtwaylandcompositor.linux_gcc_64"
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
                "debug_info.linux_gcc_64",
                "addons.qt3d",
                "addons.qt3d.linux_gcc_64",
                "addons.qtcharts",
                "addons.qtcharts.linux_gcc_64",
                "addons.qtconnectivity",
                "addons.qtconnectivity.linux_gcc_64",
                "addons.qtdatavis3d",
                "addons.qtdatavis3d.linux_gcc_64",
                "addons.qthttpserver",
                "addons.qthttpserver.linux_gcc_64",
                "addons.qtimageformats",
                "addons.qtimageformats.linux_gcc_64",
                "addons.qtlanguageserver",
                "addons.qtlanguageserver.linux_gcc_64",
                "addons.qtlottie",
                "addons.qtlottie.linux_gcc_64",
                "addons.qtmultimedia",
                "addons.qtmultimedia.linux_gcc_64",
                "addons.qtnetworkauth",
                "addons.qtnetworkauth.linux_gcc_64",
                "addons.qtpdf",
                "addons.qtpdf.linux_gcc_64",
                "addons.qtpositioning",
                "addons.qtpositioning.linux_gcc_64",
                "addons.qtquick3dphysics",
                "addons.qtquick3dphysics.linux_gcc_64",
                "addons.qtremoteobjects",
                "addons.qtremoteobjects.linux_gcc_64",
                "addons.qtscxml",
                "addons.qtscxml.linux_gcc_64",
                "addons.qtsensors",
                "addons.qtsensors.linux_gcc_64",
                "addons.qtserialbus",
                "addons.qtserialbus.linux_gcc_64",
                "addons.qtserialport",
                "addons.qtserialport.linux_gcc_64",
                "addons.qtspeech",
                "addons.qtspeech.linux_gcc_64",
                "addons.qtvirtualkeyboard",
                "addons.qtvirtualkeyboard.linux_gcc_64",
                "addons.qtwebchannel",
                "addons.qtwebchannel.linux_gcc_64",
                "addons.qtwebengine",
                "addons.qtwebengine.linux_gcc_64",
                "addons.qtwebsockets",
                "addons.qtwebsockets.linux_gcc_64",
                "addons.qtwebview",
                "addons.qtwebview.linux_gcc_64",
                "qt5compat",
                "qt5compat.linux_gcc_64",
                "qtquick3d",
                "qtquick3d.linux_gcc_64",
                "qtquicktimeline",
                "qtquicktimeline.linux_gcc_64",
                "qtshadertools",
                "qtshadertools.linux_gcc_64",
                "qtwaylandcompositor",
                "qtwaylandcompositor.linux_gcc_64"
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

$extension_groups = @(
    @{
        version = "6.9.2"
        extensions = @(
            "extensions.qtwebengine.linux_gcc_64"
            "extensions.qtpdf.linux_gcc_64"
        )
    }
    @{
        version = "6.8.3"
        extensions = @(
            "extension.qtwebengine.linux_gcc_64"
            "extension.qtpdf.linux_gcc_64"
        )
    }
)

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
if ($componentGroup.version -and $componentGroup.version -ge "6.8.0") {
        $newPath = [IO.Path]::Combine($installDir, $componentGroup.version)
        foreach ($component in $componentGroup.components) {
            Write-Host("6.8 and up")
            Install-QtComponent -Version $componentGroup.version -Name $component -Path "$newPath"
        }
        ConfigureQtVersion $installDir $componentGroup.version
    }
    elseif ($componentGroup.version) {
        foreach ($component in $componentGroup.components) {
            Write-Host("component: $component")
            Write-Host("installDir: $installDir")
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

# install extensions
foreach ($extensionGroup in $extension_groups) {
if ($extensionGroup.version) {
        foreach ($extension in $extensionGroup.extensions) {
            Write-Host("component: $extension")
            Write-Host("installDir: $installDir")
            Install-QtExtension -Version $extensionGroup.version -Name $extension -Path $installDir
        }
        #ConfigureQtVersion $installDir $extensionGroup.version

    }
    else {
        foreach ($extension in $extensionGroup.extensions) {
            Install-QtExtension -Id $extension -Path $installDir
        }
    }
}

# set aliases
ln -s "$HOME/Qt/5.15.2" "$HOME/Qt/latest"
ln -s "$HOME/Qt/6.9.2" "$HOME/Qt/6.9"
ln -s "$HOME/Qt/6.8.3" "$HOME/Qt/6.8"
ln -s "$HOME/Qt/6.5.3" "$HOME/Qt/6.5"
ln -s "$HOME/Qt/5.15.2" "$HOME/Qt/5.15"

Write-Host "Qt 5.x installed" -ForegroundColor Green
