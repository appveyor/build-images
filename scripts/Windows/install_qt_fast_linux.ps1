Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

. "$PSScriptRoot/install_qt_module.ps1"

$installDir = "$env:HOME/Qt"

$component_groups = @(
    @{
        version = "6.0.1"
        components = @(
            "gcc_64",
            "debug_info",
            "debug_info.gcc_64",
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
)

if (-not $env:INSTALL_LATEST_ONLY) {
    $component_groups += @(
        @{
            version = "5.15.2"
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
        @{
            version = "5.14.2"
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
        @{
            version = "5.12.10"
            components = @(
                "gcc_64",
                "debug_info",
                "debug_info.gcc_64",
                "qtcharts",
                "qtcharts.gcc_64",
                "qtdatavis3d",
                "qtdatavis3d.gcc_64",
                "qtnetworkauth",
                "qtnetworkauth.gcc_64",
                "qtpurchasing",
                "qtpurchasing.gcc_64",
                "qtscript",
                "qtscript.gcc_64",
                "qtvirtualkeyboard",
                "qtvirtualkeyboard.gcc_64",
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
