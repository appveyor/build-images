. "$PSScriptRoot\common.ps1"

Write-Host "Installing boost 1.83.0..." -ForegroundColor Cyan

$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()

New-Item 'C:\Libraries' -ItemType Directory -Force

# 1.83.0
Measure-Command {
    Write-Host "Installing boost 1.83.0..." -ForegroundColor Cyan

    Write-Host "Downloading x86..."
    $exePath = "$env:TEMP\boost_1_83_0-msvc-14.3-32.exe"
    (New-Object Net.WebClient).DownloadFile('https://boostorg.jfrog.io/artifactory/main/release/1.83.0/binaries/boost_1_83_0-msvc-14.3-32.exe', $exePath)

    Write-Host "Installing x86..."
    cmd /c start /wait "$exePath" /verysilent
    del $exePath
    
    Write-Host "Downloading x64..."
    $exePath = "$env:TEMP\boost_1_83_0-msvc-14.3-64.exe"
    (New-Object Net.WebClient).DownloadFile('https://boostorg.jfrog.io/artifactory/main/release/1.83.0/binaries/boost_1_83_0-msvc-14.3-64.exe', $exePath)

    Write-Host "Installing x64..."
    cmd /c start /wait "$exePath" /verysilent
    del $exePath

    [IO.Directory]::Move('C:\local\boost_1_83_0', 'C:\Libraries\boost_1_83_0')

    Remove-Item 'C:\local' -Force -Recurse

    Write-Host "Compressing..."

    Start-ProcessWithOutput "compact /c /i /q /s:C:\Libraries\boost_1_83_0" -IgnoreStdOut
}

$StopWatch.Stop()
Write-Host "Boost libraries installed in $("{0:hh}:{0:mm}:{0:ss}" -f $StopWatch.elapsed)" -ForegroundColor Green