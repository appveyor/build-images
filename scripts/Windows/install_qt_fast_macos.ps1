Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

. "$PSScriptRoot/install_qt_module.ps1"

$installDir = "$env:HOME/Qt"

$component_groups = @(
    @{
        version    = "6.4.0"
        components = @(
            "clang_64",
            "debug_info",
            "debug_info.clang_64",
            "addons.qt3d",
            "addons.qt3d.clang_64",
            "addons.qtcharts",
            "addons.qtcharts.clang_64",
            "addons.qtconnectivity",
            "addons.qtconnectivity.clang_64",            
            "addons.qtdatavis3d",
            "addons.qtdatavis3d.clang_64",
            "addons.qthttpserver",
            "addons.qthttpserver.clang_64",            
            "addons.qtimageformats",
            "addons.qtimageformats.clang_64",
            "addons.qtlanguageserver",
            "addons.qtlanguageserver.clang_64",                 
            "addons.qtlottie",
            "addons.qtlottie.clang_64",
            "addons.qtmultimedia",
            "addons.qtmultimedia.clang_64",            
            "addons.qtnetworkauth",
            "addons.qtnetworkauth.clang_64",
            "addons.qtpdf",
            "addons.qtpdf.clang_64",            
            "addons.qtpositioning",
            "addons.qtpositioning.clang_64",            
            "addons.qtquick3dphysics",
            "addons.qtquick3dphysics.clang_64",
            "addons.qtremoteobjects",
            "addons.qtremoteobjects.clang_64",                             
            "addons.qtscxml",
            "addons.qtscxml.clang_64",
            "addons.qtsensors",
            "addons.qtsensors.clang_64",            
            "addons.qtserialbus",
            "addons.qtserialbus.clang_64",
            "addons.qtserialport",
            "addons.qtserialport.clang_64",            
            "addons.qtspeech",
            "addons.qtspeech.clang_64",              
            "addons.qtvirtualkeyboard",
            "addons.qtvirtualkeyboard.clang_64",            
            "addons.qtwebchannel",
            "addons.qtwebchannel.clang_64",            
            "addons.qtwebengine",
            "addons.qtwebengine.clang_64", 
            "addons.qtwebsockets",
            "addons.qtwebsockets.clang_64",       
            "addons.qtwebview",
            "addons.qtwebview.clang_64",                                
            "qt5compat",
            "qt5compat.clang_64",        
            "qtquick3d",
            "qtquick3d.clang_64",
            "qtquicktimeline",
            "qtquicktimeline.clang_64",                     
            "qtshadertools",
            "qtshadertools.clang_64"
        )
    }
)

if (-not $env:INSTALL_LATEST_ONLY) {
    $component_groups += @(
        @{
            version    = "6.3.1"
            components = @(
                "clang_64",
                "debug_info",
                "debug_info.clang_64",
                "addons.qt3d",
                "addons.qt3d.clang_64",
                "addons.qtcharts",
                "addons.qtcharts.clang_64",
                "addons.qtdatavis3d",
                "addons.qtdatavis3d.clang_64",
                "addons.qtimageformats",
                "addons.qtimageformats.clang_64",
                "addons.qtlottie",
                "addons.qtlottie.clang_64",
                "addons.qtnetworkauth",
                "addons.qtnetworkauth.clang_64",
                "addons.qtscxml",
                "addons.qtscxml.clang_64",
                "addons.qtvirtualkeyboard",
                "addons.qtvirtualkeyboard.clang_64",            
                "qt5compat",
                "qt5compat.clang_64",        
                "qtquick3d",
                "qtquick3d.clang_64",
                "qtquicktimeline",
                "qtquicktimeline.clang_64",                     
                "qtshadertools",
                "qtshadertools.clang_64"
            )
        }        
        @{
            version    = "6.2.4"
            components = @(
                "clang_64",
                "debug_info",
                "debug_info.clang_64",
                "addons.qt3d",
                "addons.qt3d.clang_64",
                "addons.qtcharts",
                "addons.qtcharts.clang_64",
                "addons.qtdatavis3d",
                "addons.qtdatavis3d.clang_64",
                "addons.qtimageformats",
                "addons.qtimageformats.clang_64",
                "addons.qtlottie",
                "addons.qtlottie.clang_64",
                "addons.qtnetworkauth",
                "addons.qtnetworkauth.clang_64",
                "addons.qtscxml",
                "addons.qtscxml.clang_64",
                "addons.qtvirtualkeyboard",
                "addons.qtvirtualkeyboard.clang_64",            
                "qt5compat",
                "qt5compat.clang_64",        
                "qtquick3d",
                "qtquick3d.clang_64",
                "qtquicktimeline",
                "qtquicktimeline.clang_64",                     
                "qtshadertools",
                "qtshadertools.clang_64"
            )
        }                     
        @{
            version    = "5.15.2"
            components = @(
                "clang_64",
                "debug_info",
                "debug_info.clang_64",
                "qtcharts",
                "qtcharts.clang_64",
                "qtdatavis3d",
                "qtdatavis3d.clang_64",
                "qtlottie",
                "qtlottie.clang_64"            
                "qtnetworkauth",
                "qtnetworkauth.clang_64",
                "qtpurchasing",
                "qtpurchasing.clang_64",
                "qtquick3d",
                "qtquick3d.clang_64",
                "qtquicktimeline",
                "qtquicktimeline.clang_64",                     
                "qtscript",
                "qtscript.clang_64",
                "qtvirtualkeyboard",
                "qtvirtualkeyboard.clang_64",        
                "qtwebengine",
                "qtwebengine.clang_64",
                "qtwebglplugin",
                "qtwebglplugin.clang_64"
            )
        }        
    )
}

$component_groups += @(
    @{
        components = @(
            "qt.tools.ifw.44",
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
ln -s "$HOME/Qt/6.4.0" "$HOME/Qt/6.4"
ln -s "$HOME/Qt/6.3.1" "$HOME/Qt/6.3"
ln -s "$HOME/Qt/6.2.4" "$HOME/Qt/6.2"
ln -s "$HOME/Qt/5.15.2" "$HOME/Qt/5.15"

Write-Host "Qt 5.x installed" -ForegroundColor Green
