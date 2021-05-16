Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

. "$PSScriptRoot/install_qt_module.ps1"

$installDir = "$env:HOME/Qt"

$component_groups = @(
    @{
        version = "6.0.1"
        components = @(
            "clang_64",
            "debug_info",
            "debug_info.clang_64",
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
            version = "5.15.2"
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
        @{
            version = "5.14.2"
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
        },
        @{
            version = "5.12.10"
            components = @(
                "clang_64",
                "debug_info",
                "debug_info.clang_64",
                "qtcharts",
                "qtcharts.clang_64",
                "qtdatavis3d",
                "qtdatavis3d.clang_64",
                "qtnetworkauth",
                "qtnetworkauth.clang_64",
                "qtpurchasing",
                "qtpurchasing.clang_64",
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

# set aliases
ln -s "$HOME/Qt/5.15.2" "$HOME/Qt/latest"
ln -s "$HOME/Qt/6.0.1" "$HOME/Qt/6.0"
ln -s "$HOME/Qt/5.15.2" "$HOME/Qt/5.15"
ln -s "$HOME/Qt/5.14.2" "$HOME/Qt/5.14"
ln -s "$HOME/Qt/5.12.10" "$HOME/Qt/5.12"

Write-Host "Qt 5.x installed" -ForegroundColor Green
