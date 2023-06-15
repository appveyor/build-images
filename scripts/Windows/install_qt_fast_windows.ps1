Write-Host "Installing Qt 5.x, 6.x ..." -ForegroundColor Cyan

. "$PSScriptRoot\install_qt_module.ps1"

$installDir = "C:\Qt"

$component_groups = @(
    @{
        version    = "6.5.1"
        components = @(
            "win64_mingw",
            "win64_msvc2019_64",
            "win64_msvc2019_arm64",
            "debug_info",
            "debug_info.win64_mingw",
            "debug_info.win64_msvc2019_64",
            "debug_info.win64_msvc2019_arm64",       

            "addons.qt3d",
            "addons.qt3d.win64_mingw",
            "addons.qt3d.win64_msvc2019_64",
            "addons.qt3d.win64_msvc2019_arm64",

            "addons.qtactiveqt",
            "addons.qtactiveqt.win64_mingw",
            "addons.qtactiveqt.win64_msvc2019_64",
            "addons.qtactiveqt.win64_msvc2019_arm64",

            "addons.qtcharts",
            "addons.qtcharts.win64_mingw",
            "addons.qtcharts.win64_msvc2019_64",
            "addons.qtcharts.win64_msvc2019_arm64",

            "addons.qtconnectivity",
            "addons.qtconnectivity.win64_mingw",
            "addons.qtconnectivity.win64_msvc2019_64",
            "addons.qtconnectivity.win64_msvc2019_arm64",

            "addons.qtdatavis3d",
            "addons.qtdatavis3d.win64_mingw",
            "addons.qtdatavis3d.win64_msvc2019_64",
            "addons.qtdatavis3d.win64_msvc2019_arm64",

            "addons.qtgrpc",
            "addons.qtgrpc.win64_mingw",
            "addons.qtgrpc.win64_msvc2019_64",
            "addons.qtgrpc.win64_msvc2019_arm64",

            "addons.qthttpserver",
            "addons.qthttpserver.win64_mingw",
            "addons.qthttpserver.win64_msvc2019_64",
            "addons.qthttpserver.win64_msvc2019_arm64",

            "addons.qtimageformats",
            "addons.qtimageformats.win64_mingw",
            "addons.qtimageformats.win64_msvc2019_64",
            "addons.qtimageformats.win64_msvc2019_arm64",

            "addons.qtlanguageserver",
            "addons.qtlanguageserver.win64_mingw",
            "addons.qtlanguageserver.win64_msvc2019_64",
            "addons.qtlanguageserver.win64_msvc2019_arm64",

            "addons.qtlocation",
            "addons.qtlocation.win64_mingw",
            "addons.qtlocation.win64_msvc2019_64",
            "addons.qtlocation.win64_msvc2019_arm64",

            "addons.qtlottie",
            "addons.qtlottie.win64_mingw",
            "addons.qtlottie.win64_msvc2019_64",
            "addons.qtlottie.win64_msvc2019_arm64",

            "addons.qtmultimedia",
            "addons.qtmultimedia.win64_mingw",
            "addons.qtmultimedia.win64_msvc2019_64",
            "addons.qtmultimedia.win64_msvc2019_arm64",

            "addons.qtnetworkauth",
            "addons.qtnetworkauth.win64_mingw",
            "addons.qtnetworkauth.win64_msvc2019_64",
            "addons.qtnetworkauth.win64_msvc2019_arm64",

            "addons.qtpdf",
            "addons.qtpdf.win64_msvc2019_64",

            "addons.qtpositioning",
            "addons.qtpositioning.win64_mingw",
            "addons.qtpositioning.win64_msvc2019_64",
            "addons.qtpositioning.win64_msvc2019_arm64",

            "addons.qtquick3dphysics",
            "addons.qtquick3dphysics.win64_mingw",
            "addons.qtquick3dphysics.win64_msvc2019_64",
            "addons.qtquick3dphysics.win64_msvc2019_arm64",

            "addons.qtquickeffectmaker",
            "addons.qtquickeffectmaker.win64_mingw",
            "addons.qtquickeffectmaker.win64_msvc2019_64",

            "addons.qtremoteobjects",
            "addons.qtremoteobjects.win64_mingw",
            "addons.qtremoteobjects.win64_msvc2019_64",
            "addons.qtremoteobjects.win64_msvc2019_arm64",

            "addons.qtscxml",
            "addons.qtscxml.win64_mingw",
            "addons.qtscxml.win64_msvc2019_64",
            "addons.qtscxml.win64_msvc2019_arm64",

            "addons.qtsensors",
            "addons.qtsensors.win64_mingw",
            "addons.qtsensors.win64_msvc2019_64",
            "addons.qtsensors.win64_msvc2019_arm64",

            "addons.qtserialbus",
            "addons.qtserialbus.win64_mingw",
            "addons.qtserialbus.win64_msvc2019_64",
            "addons.qtserialbus.win64_msvc2019_arm64",

            "addons.qtserialport",
            "addons.qtserialport.win64_mingw",
            "addons.qtserialport.win64_msvc2019_64",
            "addons.qtserialport.win64_msvc2019_arm64",

            "addons.qtspeech",
            "addons.qtspeech.win64_mingw",
            "addons.qtspeech.win64_msvc2019_64",
            "addons.qtspeech.win64_msvc2019_arm64",

            "addons.qtvirtualkeyboard",
            "addons.qtvirtualkeyboard.win64_mingw",
            "addons.qtvirtualkeyboard.win64_msvc2019_64",
            "addons.qtvirtualkeyboard.win64_msvc2019_arm64",

            "addons.qtwebchannel",
            "addons.qtwebchannel.win64_mingw",
            "addons.qtwebchannel.win64_msvc2019_64",
            "addons.qtwebchannel.win64_msvc2019_arm64",

            "addons.qtwebengine",
            "addons.qtwebengine.win64_msvc2019_64",

            "addons.qtwebsockets",
            "addons.qtwebsockets.win64_mingw",
            "addons.qtwebsockets.win64_msvc2019_64",
            "addons.qtwebsockets.win64_msvc2019_arm64",

            "addons.qtwebview",
            "addons.qtwebview.win64_mingw",
            "addons.qtwebview.win64_msvc2019_64",

            "qt5compat",
            "qt5compat.win64_mingw",
            "qt5compat.win64_msvc2019_64",
            "qt5compat.win64_msvc2019_arm64",

            "qtquick3d",
            "qtquick3d.win64_mingw",
            "qtquick3d.win64_msvc2019_64",
            "qtquick3d.win64_msvc2019_arm64",

            "qtquicktimeline",
            "qtquicktimeline.win64_mingw",
            "qtquicktimeline.win64_msvc2019_64",
            "qtquicktimeline.win64_msvc2019_arm64",

            "qtshadertools",
            "qtshadertools.win64_mingw",
            "qtshadertools.win64_msvc2019_64",
            "qtshadertools.win64_msvc2019_arm64"

        )
    }
)

if (-not $env:INSTALL_LATEST_ONLY) {
    $component_groups += @(
        @{
            version    = "6.4.3"
            components = @(
                "win64_msvc2019_64",
                "win64_mingw",
                "debug_info",
                "debug_info.win64_mingw",
                "debug_info.win64_msvc2019_64",
                "debug_info.win64_msvc2019_arm64",
    
                "addons.qt3d",
                "addons.qt3d.win64_mingw",
                "addons.qt3d.win64_msvc2019_64",
                "addons.qt3d.win64_msvc2019_arm64",
    
                "addons.qtactiveqt",
                "addons.qtactiveqt.win64_mingw",
                "addons.qtactiveqt.win64_msvc2019_64",
                "addons.qtactiveqt.win64_msvc2019_arm64",
    
                "addons.qtcharts",
                "addons.qtcharts.win64_mingw",
                "addons.qtcharts.win64_msvc2019_64",
                "addons.qtcharts.win64_msvc2019_arm64",
    
                "addons.qtconnectivity",
                "addons.qtconnectivity.win64_mingw",
                "addons.qtconnectivity.win64_msvc2019_64",
                "addons.qtconnectivity.win64_msvc2019_arm64",
    
                "addons.qtdatavis3d",
                "addons.qtdatavis3d.win64_mingw",
                "addons.qtdatavis3d.win64_msvc2019_64",
                "addons.qtdatavis3d.win64_msvc2019_arm64",
    
                "addons.qthttpserver",
                "addons.qthttpserver.win64_mingw",
                "addons.qthttpserver.win64_msvc2019_64",
                "addons.qthttpserver.win64_msvc2019_arm64",            
    
                "addons.qtimageformats",
                "addons.qtimageformats.win64_mingw",
                "addons.qtimageformats.win64_msvc2019_64",
                "addons.qtimageformats.win64_msvc2019_arm64",
    
                "addons.qtlanguageserver",
                "addons.qtlanguageserver.win64_mingw",
                "addons.qtlanguageserver.win64_msvc2019_64",
                "addons.qtlanguageserver.win64_msvc2019_arm64",               
    
                "addons.qtlottie",
                "addons.qtlottie.win64_mingw",
                "addons.qtlottie.win64_msvc2019_64",
                "addons.qtlottie.win64_msvc2019_arm64",
    
                "addons.qtmultimedia",
                "addons.qtmultimedia.win64_mingw",
                "addons.qtmultimedia.win64_msvc2019_64",
                "addons.qtmultimedia.win64_msvc2019_arm64",
    
                "addons.qtnetworkauth",
                "addons.qtnetworkauth.win64_mingw",
                "addons.qtnetworkauth.win64_msvc2019_64",
                "addons.qtnetworkauth.win64_msvc2019_arm64",
    
                "addons.qtpdf",
                "addons.qtpdf.win64_msvc2019_64",
    
                "addons.qtpositioning",
                "addons.qtpositioning.win64_mingw",
                "addons.qtpositioning.win64_msvc2019_64",
                "addons.qtpositioning.win64_msvc2019_arm64",
    
                "addons.qtquick3dphysics",
                "addons.qtquick3dphysics.win64_mingw",
                "addons.qtquick3dphysics.win64_msvc2019_64",
                "addons.qtquick3dphysics.win64_msvc2019_arm64",            
    
                "addons.qtremoteobjects",
                "addons.qtremoteobjects.win64_mingw",
                "addons.qtremoteobjects.win64_msvc2019_64",
                "addons.qtremoteobjects.win64_msvc2019_arm64",
                
                "addons.qtscxml",
                "addons.qtscxml.win64_mingw",
                "addons.qtscxml.win64_msvc2019_64",
                "addons.qtscxml.win64_msvc2019_arm64",
    
                "addons.qtsensors",
                "addons.qtsensors.win64_mingw",
                "addons.qtsensors.win64_msvc2019_64",
                "addons.qtsensors.win64_msvc2019_arm64",
    
                "addons.qtserialbus",
                "addons.qtserialbus.win64_mingw",
                "addons.qtserialbus.win64_msvc2019_64",
                "addons.qtserialbus.win64_msvc2019_arm64",
                
                "addons.qtserialport",
                "addons.qtserialport.win64_mingw",
                "addons.qtserialport.win64_msvc2019_64",
                "addons.qtserialport.win64_msvc2019_arm64",
    
                "addons.qtspeech",
                "addons.qtspeech.win64_mingw",
                "addons.qtspeech.win64_msvc2019_64",
                "addons.qtspeech.win64_msvc2019_arm64",                 
    
                "addons.qtvirtualkeyboard",
                "addons.qtvirtualkeyboard.win64_mingw",
                "addons.qtvirtualkeyboard.win64_msvc2019_64",
                "addons.qtvirtualkeyboard.win64_msvc2019_arm64",
    
                "addons.qtwebchannel",
                "addons.qtwebchannel.win64_mingw",
                "addons.qtwebchannel.win64_msvc2019_64",
                "addons.qtwebchannel.win64_msvc2019_arm64",
    
                "addons.qtwebengine",
                "addons.qtwebengine.win64_msvc2019_64",
                
                "addons.qtwebsockets",
                "addons.qtwebsockets.win64_mingw",
                "addons.qtwebsockets.win64_msvc2019_64",
                "addons.qtwebsockets.win64_msvc2019_arm64",
    
                "addons.qtwebview",
                "addons.qtwebview.win64_mingw",
                "addons.qtwebview.win64_msvc2019_64",
    
                "qt5compat",
                "qt5compat.win64_mingw",
                "qt5compat.win64_msvc2019_64",
                "qt5compat.win64_msvc2019_arm64",
    
                "qtquick3d",
                "qtquick3d.win64_mingw",
                "qtquick3d.win64_msvc2019_64",
                "qtquick3d.win64_msvc2019_arm64",
            
                "qtquicktimeline",
                "qtquicktimeline.win64_mingw",
                "qtquicktimeline.win64_msvc2019_64",
                "qtquicktimeline.win64_msvc2019_arm64",
    
                "qtshadertools",
                "qtshadertools.win64_mingw",
                "qtshadertools.win64_msvc2019_64",
                "qtshadertools.win64_msvc2019_arm64"
            )
        }
        @{
            version    = "6.2.8"
            components = @(
                "win64_msvc2019_64",
                "win64_mingw",
                "debug_info",
                "debug_info.win64_mingw",
                "debug_info.win64_msvc2019_64",
                "debug_info.win64_msvc2019_arm64",
    
                "addons.qt3d",
                "addons.qt3d.win64_mingw",
                "addons.qt3d.win64_msvc2019_64",
                "addons.qt3d.win64_msvc2019_arm64",
    
                "addons.qtactiveqt",
                "addons.qtactiveqt.win64_mingw",
                "addons.qtactiveqt.win64_msvc2019_64",
                "addons.qtactiveqt.win64_msvc2019_arm64",
    
                "addons.qtcharts",
                "addons.qtcharts.win64_mingw",
                "addons.qtcharts.win64_msvc2019_64",
                "addons.qtcharts.win64_msvc2019_arm64",
    
                "addons.qtconnectivity",
                "addons.qtconnectivity.win64_mingw",
                "addons.qtconnectivity.win64_msvc2019_64",
                "addons.qtconnectivity.win64_msvc2019_arm64",
    
                "addons.qtdatavis3d",
                "addons.qtdatavis3d.win64_mingw",
                "addons.qtdatavis3d.win64_msvc2019_64",
                "addons.qtdatavis3d.win64_msvc2019_arm64",
                
                "addons.qtimageformats",
                "addons.qtimageformats.win64_mingw",
                "addons.qtimageformats.win64_msvc2019_64",
                "addons.qtimageformats.win64_msvc2019_arm64",
    
                "addons.qtlottie",
                "addons.qtlottie.win64_mingw",
                "addons.qtlottie.win64_msvc2019_64",
                "addons.qtlottie.win64_msvc2019_arm64",
    
                "addons.qtmultimedia",
                "addons.qtmultimedia.win64_mingw",
                "addons.qtmultimedia.win64_msvc2019_64",
                "addons.qtmultimedia.win64_msvc2019_arm64",
    
                "addons.qtnetworkauth",
                "addons.qtnetworkauth.win64_mingw",
                "addons.qtnetworkauth.win64_msvc2019_64",
                "addons.qtnetworkauth.win64_msvc2019_arm64",
    
                "addons.qtpositioning",
                "addons.qtpositioning.win64_mingw",
                "addons.qtpositioning.win64_msvc2019_64",
                "addons.qtpositioning.win64_msvc2019_arm64",
    
                "addons.qtremoteobjects",
                "addons.qtremoteobjects.win64_mingw",
                "addons.qtremoteobjects.win64_msvc2019_64",
                "addons.qtremoteobjects.win64_msvc2019_arm64",
                
                "addons.qtscxml",
                "addons.qtscxml.win64_mingw",
                "addons.qtscxml.win64_msvc2019_64",
                "addons.qtscxml.win64_msvc2019_arm64",
    
                "addons.qtsensors",
                "addons.qtsensors.win64_mingw",
                "addons.qtsensors.win64_msvc2019_64",
                "addons.qtsensors.win64_msvc2019_arm64",
    
                "addons.qtserialbus",
                "addons.qtserialbus.win64_mingw",
                "addons.qtserialbus.win64_msvc2019_64",
                "addons.qtserialbus.win64_msvc2019_arm64",
                
                "addons.qtserialport",
                "addons.qtserialport.win64_mingw",
                "addons.qtserialport.win64_msvc2019_64",
                "addons.qtserialport.win64_msvc2019_arm64",            
    
                "addons.qtvirtualkeyboard",
                "addons.qtvirtualkeyboard.win64_mingw",
                "addons.qtvirtualkeyboard.win64_msvc2019_64",
                "addons.qtvirtualkeyboard.win64_msvc2019_arm64",
    
                "addons.qtwebchannel",
                "addons.qtwebchannel.win64_mingw",
                "addons.qtwebchannel.win64_msvc2019_64",
                "addons.qtwebchannel.win64_msvc2019_arm64",
    
                "addons.qtwebengine",
                "addons.qtwebengine.win64_msvc2019_64",
                
                "addons.qtwebsockets",
                "addons.qtwebsockets.win64_mingw",
                "addons.qtwebsockets.win64_msvc2019_64",
                "addons.qtwebsockets.win64_msvc2019_arm64",
    
                "addons.qtwebview",
                "addons.qtwebview.win64_mingw",
                "addons.qtwebview.win64_msvc2019_64",
    
                "qt5compat",
                "qt5compat.win64_mingw",
                "qt5compat.win64_msvc2019_64",
                "qt5compat.win64_msvc2019_arm64",
    
                "qtquick3d",
                "qtquick3d.win64_mingw",
                "qtquick3d.win64_msvc2019_64",
                "qtquick3d.win64_msvc2019_arm64",
            
                "qtquicktimeline",
                "qtquicktimeline.win64_mingw",
                "qtquicktimeline.win64_msvc2019_64",
                "qtquicktimeline.win64_msvc2019_arm64",
    
                "qtshadertools",
                "qtshadertools.win64_mingw",
                "qtshadertools.win64_msvc2019_64",
                "qtshadertools.win64_msvc2019_arm64"
            )
        }        
        @{
            version    = "5.15.2"
            components = @(
                "win32_msvc2019",
                "win64_msvc2019_64",
                "win32_mingw81",
                "win64_mingw81",
                "debug_info",
                "debug_info.win32_msvc2019",
                "debug_info.win64_msvc2019_64",
                "qtcharts",
                "qtcharts.win32_mingw81",
                "qtcharts.win32_msvc2019",
                "qtcharts.win64_mingw81",
                "qtcharts.win64_msvc2019_64",
            
                "qtquick3d",
                "qtquick3d.win32_mingw81",
                "qtquick3d.win32_msvc2019",
                "qtquick3d.win64_mingw81",
                "qtquick3d.win64_msvc2019_64",
            
                "qtdatavis3d",
                "qtdatavis3d.win32_mingw81",
                "qtdatavis3d.win32_msvc2019",
                "qtdatavis3d.win64_mingw81",
                "qtdatavis3d.win64_msvc2019_64",
                "qtlottie",
                "qtlottie.win32_mingw81",
                "qtlottie.win32_msvc2019",
                "qtlottie.win64_mingw81",
                "qtlottie.win64_msvc2019_64",
                "qtnetworkauth",
                "qtnetworkauth.win32_mingw81",
                "qtnetworkauth.win32_msvc2019",
                "qtnetworkauth.win64_mingw81",
                "qtnetworkauth.win64_msvc2019_64",
                "qtpurchasing",
                "qtpurchasing.win32_mingw81",
                "qtpurchasing.win32_msvc2019",
                "qtpurchasing.win64_mingw81",
                "qtpurchasing.win64_msvc2019_64",
                "qtscript",
                "qtscript.win32_mingw81",
                "qtscript.win32_msvc2019",
                "qtscript.win64_mingw81",
                "qtscript.win64_msvc2019_64",
                "qtvirtualkeyboard",
                "qtvirtualkeyboard.win32_mingw81",
                "qtvirtualkeyboard.win32_msvc2019",
                "qtvirtualkeyboard.win64_mingw81",
                "qtvirtualkeyboard.win64_msvc2019_64",
                "qtwebengine",
                "qtwebengine.win32_msvc2019",
                "qtwebengine.win64_msvc2019_64",
                "qtwebglplugin",
                "qtwebglplugin.win32_mingw81",
                "qtwebglplugin.win32_msvc2019",
                "qtwebglplugin.win64_mingw81",
                "qtwebglplugin.win64_msvc2019_64",
            
                "qtquicktimeline",
                "qtquicktimeline.win32_mingw81",
                "qtquicktimeline.win32_msvc2019",
                "qtquicktimeline.win64_mingw81",
                "qtquicktimeline.win64_msvc2019_64"
            )
        }        
        @{
            version    = "5.9.9"
            components = @(
                "win32_mingw53",
                "win32_msvc2015",
                "win64_msvc2017_64",
                "qtcharts",
                "qtcharts.win32_mingw53",
                "qtcharts.win32_msvc2015",
                "qtcharts.win64_msvc2017_64",
                "qtdatavis3d",
                "qtdatavis3d.win32_mingw53",
                "qtdatavis3d.win32_msvc2015",
                "qtdatavis3d.win64_msvc2017_64",
                "qtnetworkauth",
                "qtnetworkauth.win32_mingw53",
                "qtnetworkauth.win32_msvc2015",
                "qtnetworkauth.win64_msvc2017_64",
                "qtpurchasing",
                "qtpurchasing.win32_mingw53",
                "qtpurchasing.win32_msvc2015",
                "qtpurchasing.win64_msvc2017_64",
                "qtremoteobjects",
                "qtremoteobjects.win32_mingw53",
                "qtremoteobjects.win32_msvc2015",
                "qtremoteobjects.win64_msvc2017_64",
                "qtscript",
                "qtscript.win32_mingw53",
                "qtscript.win32_msvc2015",
                "qtscript.win64_msvc2017_64",
                "qtspeech",
                "qtspeech.win32_mingw53",
                "qtspeech.win32_msvc2015",
                "qtspeech.win64_msvc2017_64",
                "qtvirtualkeyboard",
                "qtvirtualkeyboard.win32_mingw53",
                "qtvirtualkeyboard.win32_msvc2015",
                "qtvirtualkeyboard.win64_msvc2017_64",
                "qtwebengine",
                "qtwebengine.win32_msvc2015",
                "qtwebengine.win64_msvc2017_64"   
            )
        }
    )
}

$component_groups += @(
    @{
        components = @(
            "qt.tools.win32_mingw530",
            "qt.tools.win32_mingw810",
            "qt.tools.win64_mingw810",
            "qt.tools.win64_mingw900",
            "qt.tools.ifw.45",
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

# compressing folder
Write-Host "Compacting C:\Qt..." -NoNewline
compact /c /i /s:C:\Qt | Out-Null
Write-Host "OK" -ForegroundColor Green

# set aliases
$sym_links = @{
    "latest" = "5.15.2"
    "6.5"    = "6.5.0"
    "6.4"    = "6.4.3"    
    "6.2"    = "6.2.4"
    "5.15"   = "5.15.2"
    "5.9"    = "5.9.9"
}

foreach ($link in $sym_links.Keys) {
    $target = $sym_links[$link]
    New-Item -ItemType SymbolicLink -Path "$installDir\$link" -Target "$installDir\$target" -Force | Out-Null
}

Write-Host "Qt 5.x installed" -ForegroundColor Green
