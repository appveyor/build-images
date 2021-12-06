[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Install-SDK($sdkVersion) {
    
    if (Test-Path "$env:ProgramFiles\dotnet\sdk\$sdkVersion") {
        Write-Host ".NET Core SDK $sdkVersion is already installed" -ForegroundColor Yellow
    } else {
        Write-Host "Installing .NET Core SDK $sdkVersion"
        Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -UseBasicParsing -OutFile "$env:temp\dotnet-install.ps1"
        & $env:temp\dotnet-install.ps1 -Architecture x64 -Version $sdkVersion -InstallDir "$env:ProgramFiles\dotnet"
    }

    Write-Host "Warming up .NET Core SDK $sdkVersion..."
    $projectPath = "$env:temp\TestApp"
    New-Item -Path $projectPath -Force -ItemType Directory | Out-Null
    Set-Content -Path "$projectPath\global.json" -Value "{`"sdk`": {`"version`": `"$sdkVersion`"}}"
    Push-Location -Path $projectPath
    & $env:ProgramFiles\dotnet\dotnet.exe new console
    Pop-Location
    Remove-Item $projectPath -Force -Recurse
    Write-Host "Installed .NET Core SDK $sdkVersion" -ForegroundColor Green
}

if (-not $env:INSTALL_LATEST_ONLY) {
    Install-SDK "1.1.14"
    Install-SDK "2.1.202"
    Install-SDK "2.1.806"
}
Install-SDK "2.2.402"

$vs2019 = (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019")
$vs2022 = (Test-Path "${env:ProgramFiles}\Microsoft Visual Studio\2022")

# VS 2019 and 2022 images only
if ($vs2019 -or $vs2022) {
    Install-SDK "3.0.103"
    Install-SDK "3.1.202"
    Install-SDK "3.1.415"
}

# VS 2022 images only
if ($vs2022) {
    Install-SDK "5.0.403"
}

# VS 2019 Preview
if ($env:install_vs2019_preview) {
	Install-SDK "6.0.100-preview.5.21302.13"
}