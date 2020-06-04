Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

. "$PSScriptRoot/install_qt_module.ps1"

$installDir = "$env:HOME/Qt"

$component_groups = @(
    @{
        version = "5.15.0"
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

if (-not $env:INSTALL_LATEST_ONLY) {
    $component_groups += @(
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
            version = "5.12.8"
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
            "qt.tools.ifw.32",
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
ln -s "$HOME/Qt/5.15.0" "$HOME/Qt/latest"
ln -s "$HOME/Qt/5.15.0" "$HOME/Qt/5.15"
ln -s "$HOME/Qt/5.14.2" "$HOME/Qt/5.14"
ln -s "$HOME/Qt/5.12.8" "$HOME/Qt/5.12"

Write-Host "Qt 5.x installed" -ForegroundColor Green
