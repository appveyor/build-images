$nugetVersion = '5.4.0'
$nugetUrl = "https://dist.nuget.org/win-x86-commandline/v$nugetVersion/nuget.exe"

$nugetDir = "$env:SystemDrive\Tools\NuGet3"

if (-not (Test-Path $nugetDir)) {
    $nugetPath = "$env:SystemDrive\Tools\NuGet"
    if (-not (Test-Path $nugetPath)) {
        Write-Host "Installing NuGet into $nugetDir"
        New-Item $nugetPath -ItemType Directory -Force | Out-Null
    } else {
        Write-Host "Updating NuGet in $nugetDir"
    }
} else {
    Write-Host "Updating NuGet in $nugetDir"
}

(New-Object Net.WebClient).DownloadFile($nugetUrl, "$nugetDir\nuget.exe")

(nuget).split("`n")[0]

Write-Host "NuGet updated" -ForegroundColor Green