Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

. "$PSScriptRoot\install_qt_module.ps1"

$installDir = "C:\Qt"

$component_groups = @(
    @{
        version = "6.0.1"
        components = @(
            "win64_msvc2019_64",
            "win64_mingw81",
            "debug_info",
            "debug_info.win64_mingw81",
            "debug_info.win64_msvc2019_64",

            "qt5compat",
            "qt5compat.win64_mingw81",
            "qt5compat.win64_msvc2019_64",               

            "qtshadertools",
            "qtshadertools.win64_mingw81",
            "qtshadertools.win64_msvc2019_64",            
        
            "qtquick3d",
            "qtquick3d.win64_mingw81",
            "qtquick3d.win64_msvc2019_64",
        
            "qtquicktimeline",
            "qtquicktimeline.win64_mingw81",
            "qtquicktimeline.win64_msvc2019_64"
        )
    }
)

if (-not $env:INSTALL_LATEST_ONLY) {
    $component_groups += @(
        @{
            version = "5.15.2"
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
            version = "5.14.2"
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
        @{
            version = "5.13.2"
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
                "qtwebglplugin.win64_msvc2017_64"
            )
        }
        @{
            version = "5.12.10"
            components = @(
                "win32_mingw73",
                "win32_msvc2017",
                "win64_mingw73",
                "win64_msvc2017_64",
                "debug_info",
                "debug_info.win32_msvc2017",
                "debug_info.win64_msvc2017_64",
                "qtcharts",
                "qtcharts.win32_mingw73",
                "qtcharts.win32_msvc2017",
                "qtcharts.win64_mingw73",
                "qtcharts.win64_msvc2017_64",
                "qtdatavis3d",
                "qtdatavis3d.win32_mingw73",
                "qtdatavis3d.win32_msvc2017",
                "qtdatavis3d.win64_mingw73",
                "qtdatavis3d.win64_msvc2017_64",
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
                "qtwebglplugin.win64_msvc2017_64"
            )
        }
        @{
            version = "5.9.9"
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
            "qt.tools.win32_mingw730",
            "qt.tools.win64_mingw730",
            "qt.tools.win32_mingw810",
            "qt.tools.win64_mingw810",            
            "qt.tools.ifw.41",
            "qt.license.thirdparty"
        )
    }
)

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

# compressing folder
Write-Host "Compacting C:\Qt..." -NoNewline
compact /c /i /s:C:\Qt | Out-Null
Write-Host "OK" -ForegroundColor Green

# set aliases
cmd /c mklink /J C:\Qt\latest C:\Qt\5.15.2
cmd /c mklink /J C:\Qt\6.0 C:\Qt\6.0.1
cmd /c mklink /J C:\Qt\5.15 C:\Qt\5.15.2
cmd /c mklink /J C:\Qt\5.14 C:\Qt\5.14.2
cmd /c mklink /J C:\Qt\5.13 C:\Qt\5.13.2
cmd /c mklink /J C:\Qt\5.12 C:\Qt\5.12.10
cmd /c mklink /J C:\Qt\5.9 C:\Qt\5.9.9

Write-Host "Qt 5.x installed" -ForegroundColor Green
