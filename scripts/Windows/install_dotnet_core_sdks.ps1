. "$PSScriptRoot\common.ps1"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls13

function Install-SDK($sdkVersion) {
    
    if (Test-Path "$env:ProgramFiles\dotnet\sdk\$sdkVersion") {
        Write-Host ".NET Core SDK $sdkVersion is already installed" -ForegroundColor Yellow
    }
    else {
        Write-Host "Installing .NET Core SDK $sdkVersion"
        Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -UseBasicParsing -OutFile "$env:temp\dotnet-install.ps1"
        & $env:temp\dotnet-install.ps1 -Architecture x64 -Version $sdkVersion -InstallDir "$env:ProgramFiles\dotnet"
    }
    #install location for 1.1.14 is "https://dotnetcli.azureedge.net/dotnet/Sdk/1.1.14/dotnet-dev-win-x64.1.1.14.zip"
    Write-Host "Warming up .NET Core SDK $sdkVersion..."
    $projectPath = "$env:temp\TestApp"
    New-Item -Path $projectPath -Force -ItemType Directory | Out-Null
    Set-Content -Path "$projectPath\global.json" -Value "{`"sdk`": {`"version`": `"$sdkVersion`"}}"
    Push-Location -Path $projectPath
    Start-ProcessWithOutput "dotnet new console"
    Pop-Location
    Remove-Item $projectPath -Force -Recurse
    Write-Host "Installed .NET Core SDK $sdkVersion" -ForegroundColor Green
}

if (-not $env:INSTALL_LATEST_ONLY) {
    #Install-SDK "1.1.14"
    #Install-SDK "2.1.202"
    #Install-SDK "2.1.806"
}
#Install-SDK "2.2.402"

$vs2019 = (Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019")
$vs2022 = (Test-Path "${env:ProgramFiles}\Microsoft Visual Studio\2022")

# VS 2019 and 2022 images only
if ($vs2019 -or $vs2022) {
    #Install-SDK "3.0.103"
    #Install-SDK "3.1.202"
    Install-SDK "3.1.426"
    #Install-SDK "5.0.408"
    Install-SDK "7.0.410"
    Install-SDK "8.0.401"
    Install-SDK "9.0.101"
}

# VS 2022 image only
if ($vs2022) {
    Install-SDK "6.0.425"
    #Install-SDK "7.0.410"
    #Install-SDK "8.0.202"
}

# VS 2019 Preview
if ($env:install_vs2019_preview) {
    Install-SDK "6.0.100-preview.5.21302.13"
}