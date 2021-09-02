. "$PSScriptRoot\common.ps1"

Write-Host "Installing boost 1.77.0..." -ForegroundColor Cyan

$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()

New-Item 'C:\Libraries' -ItemType Directory -Force

# 1.77.0
Measure-Command {
    Write-Host "Installing boost 1.77.0..." -ForegroundColor Cyan

    Write-Host "Downloading..."
    $zipPath = "$env:TEMP\boost_1_77_0.7z"
    (New-Object Net.WebClient).DownloadFile("https://appveyordownloads.blob.core.windows.net/misc/boost_1_77_0.7z", $zipPath)
    
    Write-Host "Unpacking..."
    7z x $zipPath -o"C:\Libraries" | Out-Null
    Remove-Item $zipPath

    Write-Host "Compressing..."
    Start-ProcessWithOutput "compact /c /i /q /s:C:\Libraries\boost_1_77_0" -IgnoreStdOut
}

$StopWatch.Stop()
Write-Host "Boost libraries installed in $("{0:hh}:{0:mm}:{0:ss}" -f $StopWatch.elapsed)" -ForegroundColor Green