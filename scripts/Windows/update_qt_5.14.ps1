. "$PSScriptRoot\install_qt_module.ps1"

$installDir = "$env:SystemDrive\Qt"

Write-Host "Installing Qt 5.14.1 ..." -ForegroundColor Cyan

$component_groups = @(
    @{
        version = "5.14.1"
        components = @(
            "win32_mingw73",
            "debug_info"
        )
    }
)

$component_groups += @(
    @{
        components = @(
            "qt.tools.win32_mingw730",
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

Write-Host "Qt 5.14.1 installed" -ForegroundColor Green