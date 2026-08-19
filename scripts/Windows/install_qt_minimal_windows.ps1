Write-Host "Installing minimal Qt 6.x set ..." -ForegroundColor Cyan

. "$PSScriptRoot\install_qt_module.ps1"

$installDir = "C:\Qt"

$modernCommonComponents = @(
    "debug_info",
    "addons.qt3d",
    "addons.qtactiveqt",
    "addons.qtcharts",
    "addons.qtconnectivity",
    "addons.qtdatavis3d",
    "addons.qtgraphs",
    "addons.qtgrpc",
    "addons.qthttpserver",
    "addons.qtimageformats",
    "addons.qtlanguageserver",
    "addons.qtlocation",
    "addons.qtlottie",
    "addons.qtmultimedia",
    "addons.qtnetworkauth",
    "addons.qtpositioning",
    "addons.qtquick3dphysics",
    "addons.qtremoteobjects",
    "addons.qtscxml",
    "addons.qtsensors",
    "addons.qtserialbus",
    "addons.qtserialport",
    "addons.qtspeech",
    "addons.qtvirtualkeyboard",
    "addons.qtwebchannel",
    "addons.qtwebsockets",
    "addons.qt5compat",
    "addons.qtquick3d",
    "addons.qtquicktimeline",
    "addons.qtshadertools"
)

$toolchainComponentGroups = @(
    @{
        name = "win64_mingw"
        components = $modernCommonComponents + @(
            "addons.qtquickeffectmaker",
            "addons.qtwebview"
        )
    }
    @{
        name = "win64_msvc2022_64"
        components = $modernCommonComponents + @(
            "addons.qtquickeffectmaker",
            "addons.qtwebview"
        )
    }
    @{
        name = "win64_msvc2022_arm64_cross_compiled"
        components = $modernCommonComponents
    }
)

$component_groups = @(
    @{
        version = "6.11.1"
    }
    @{
        version = "6.10.3"
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
            "extensions.qtpdf.6111.win64_msvc2022_64"
        )
    }
    @{
        version = "6.10.3"
        extensions = @(
            "extensions.qtwebengine.6103.win64_msvc2022_64"
            "extensions.qtpdf.6103.win64_msvc2022_64"
        )
    }
)

foreach ($componentGroup in $component_groups) {
    if ($componentGroup.version) {
        $newPath = [IO.Path]::Combine($installDir, $componentGroup.version)
        foreach ($toolchainGroup in $toolchainComponentGroups) {
            Install-QtComponent -Version $componentGroup.version -Name $toolchainGroup.name -Path $newPath -ToolchainName $toolchainGroup.name -excludeDocs -excludeExamples
            foreach ($component in $toolchainGroup.components) {
                Install-QtComponent -Version $componentGroup.version -Name "$component.$($toolchainGroup.name)" -Path $newPath -ToolchainName $toolchainGroup.name -excludeDocs -excludeExamples
            }
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
        Install-QtExtension -Version $extensionGroup.version -Name $extension -Path $newPath -excludeDocs -excludeExamples
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
