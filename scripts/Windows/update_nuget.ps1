$nugetDir = 'C:\Tools\NuGet'
if(Test-Path 'C:\Tools\NuGet3') {
    $nugetDir = 'C:\Tools\NuGet3'
}

(New-Object Net.WebClient).DownloadFile('https://dist.nuget.org/win-x86-commandline/v4.9.2/nuget.exe', "$nugetDir\NuGet.exe")

(nuget).split("`n")[0]

Write-Host "NuGet 4.9.2 installed"