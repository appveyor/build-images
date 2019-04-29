$msbuild_12_path = "${env:ProgramFiles(x86)}\MSBuild\12.0\Bin"
$msbuild_14_path = "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin"
$msbuild_15_path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin"
$msbuild_15_preview_path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Preview\Community\MSBuild\15.0\Bin"

Remove-Path $msbuild_12_path
Remove-Path $msbuild_14_path
Remove-Path $msbuild_15_path
Remove-Path $msbuild_15_preview_path


if(Test-Path $msbuild_15_preview_path) {

    Write-Host "Adding MSBuild 15.0 Preview to PATH..." -ForegroundColor Cyan
    Add-Path $msbuild_15_preview_path
    Add-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130"

} elseif(Test-Path $msbuild_15_path) {

    Write-Host "Adding MSBuild 15.0 to PATH..." -ForegroundColor Cyan
    Add-Path $msbuild_15_path
    Add-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130"

} elseif (Test-Path $msbuild_14_path) {

    Write-Host "Adding MSBuild 14.0 to PATH..." -ForegroundColor Cyan
    Add-Path $msbuild_14_path
    Add-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\120"
    Remove-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\120"

} else {

    Write-Host "Adding MSBuild 12.0 to PATH..." -ForegroundColor Cyan
    Add-Path $msbuild_12_path
    Add-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\120"
}

# Add SqlPackage.exe
#Add-Path 'C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\120'