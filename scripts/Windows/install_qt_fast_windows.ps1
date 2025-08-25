Write-Host "Installing Qt 5.x, 6.x ..." -ForegroundColor Cyan

. "$PSScriptRoot\install_qt_module.ps1"

$installDir = "C:\Qt"

$component_groups = @(
    @{
        version    = "6.9.1"
        components = @(
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
    }
)

if (-not $env:INSTALL_LATEST_ONLY) {
    $component_groups += @(
        @{
            version    = "6.8.3"
            components = @(
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
        }
        @{
            version    = "6.5.3"
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
        # @{
        #     version    = "5.15.2"
        #     components = @(
        #         "win32_msvc2019",
        #         "win64_msvc2019_64",
        #         "win32_mingw81",
        #         "win64_mingw81",
        #         "debug_info",
        #         "debug_info.win32_msvc2019",
        #         "debug_info.win64_msvc2019_64",
        #         "qtcharts",
        #         "qtcharts.win32_mingw81",
        #         "qtcharts.win32_msvc2019",
        #         "qtcharts.win64_mingw81",
        #         "qtcharts.win64_msvc2019_64",
            
        #         "qtquick3d",
        #         "qtquick3d.win32_mingw81",
        #         "qtquick3d.win32_msvc2019",
        #         "qtquick3d.win64_mingw81",
        #         "qtquick3d.win64_msvc2019_64",
            
        #         "qtdatavis3d",
        #         "qtdatavis3d.win32_mingw81",
        #         "qtdatavis3d.win32_msvc2019",
        #         "qtdatavis3d.win64_mingw81",
        #         "qtdatavis3d.win64_msvc2019_64",
        #         "qtlottie",
        #         "qtlottie.win32_mingw81",
        #         "qtlottie.win32_msvc2019",
        #         "qtlottie.win64_mingw81",
        #         "qtlottie.win64_msvc2019_64",
        #         "qtnetworkauth",
        #         "qtnetworkauth.win32_mingw81",
        #         "qtnetworkauth.win32_msvc2019",
        #         "qtnetworkauth.win64_mingw81",
        #         "qtnetworkauth.win64_msvc2019_64",
        #         "qtpurchasing",
        #         "qtpurchasing.win32_mingw81",
        #         "qtpurchasing.win32_msvc2019",
        #         "qtpurchasing.win64_mingw81",
        #         "qtpurchasing.win64_msvc2019_64",
        #         "qtscript",
        #         "qtscript.win32_mingw81",
        #         "qtscript.win32_msvc2019",
        #         "qtscript.win64_mingw81",
        #         "qtscript.win64_msvc2019_64",
        #         "qtvirtualkeyboard",
        #         "qtvirtualkeyboard.win32_mingw81",
        #         "qtvirtualkeyboard.win32_msvc2019",
        #         "qtvirtualkeyboard.win64_mingw81",
        #         "qtvirtualkeyboard.win64_msvc2019_64",
        #         "qtwebengine",
        #         "qtwebengine.win32_msvc2019",
        #         "qtwebengine.win64_msvc2019_64",
        #         "qtwebglplugin",
        #         "qtwebglplugin.win32_mingw81",
        #         "qtwebglplugin.win32_msvc2019",
        #         "qtwebglplugin.win64_mingw81",
        #         "qtwebglplugin.win64_msvc2019_64",
            
        #         "qtquicktimeline",
        #         "qtquicktimeline.win32_mingw81",
        #         "qtquicktimeline.win32_msvc2019",
        #         "qtquicktimeline.win64_mingw81",
        #         "qtquicktimeline.win64_msvc2019_64"
        #     )
        # }        
    )
}
$extension_groups = @(
    @{
        version = "6.9.1"
        extensions = @(
            "extension.qtwebengine",
            "extension.qtwebengine.win64_msvc2022_64"

            "extension.qtpdf",
            "extension.qtpdf.win64_msvc2022_64"
        )
    }
    @{
        version = "6.8.3"
        extensions = @(
            "extension.qtwebengine",
            "extension.qtwebengine.win64_msvc2022_64"

            "extension.qtpdf",
            "extension.qtpdf.win64_msvc2022_64"
        )
    }
)

$component_groups += @(
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

# compressing folder
Write-Host "Compacting C:\Qt..." -NoNewline
compact /c /i /s:C:\Qt | Out-Null
Write-Host "OK" -ForegroundColor Green

# set aliases
$sym_links = @{
    #"latest" = "5.15.2"
    "6.9"    = "6.9.1"
    "6.8"    = "6.8.3"
    "6.5"    = "6.5.3"
    #"5.15"   = "5.15.2"
    #"5.9"    = "5.9.9"
}

foreach ($link in $sym_links.Keys) {
    $target = $sym_links[$link]
    New-Item -ItemType SymbolicLink -Path "$installDir\$link" -Target "$installDir\$target" -Force | Out-Null
}

Write-Host "Qt 5.x installed" -ForegroundColor Green
