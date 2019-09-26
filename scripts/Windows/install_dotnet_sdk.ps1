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

Install-SDK "1.1.14"
Install-SDK "2.1.503"
Install-SDK "2.1.507"
Install-SDK "2.1.603"
Install-SDK "2.1.604"
Install-SDK "2.1.701"
Install-SDK "2.2.103"
Install-SDK "2.2.107"
Install-SDK "2.2.108"
Install-SDK "2.2.203"
Install-SDK "2.2.204"
Install-SDK "2.2.301"
Install-SDK "3.0.100"