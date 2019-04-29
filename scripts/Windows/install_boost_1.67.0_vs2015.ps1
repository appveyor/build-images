Write-Host "Installing boost 1.67.0..." -ForegroundColor Cyan

New-Item 'C:\Libraries' -ItemType Directory -Force

# 1.67
Measure-Command {
    Write-Host "Installing boost 1.67.0..." -ForegroundColor Cyan

    Write-Host "Downloading x86..."
    $exePath = "$env:TEMP\boost_1_67_0-msvc-14.0-32.exe"
    (New-Object Net.WebClient).DownloadFile('https://bintray.com/boostorg/release/download_file?file_path=1.67.0%2Fbinaries%2Fboost_1_67_0-msvc-14.0-32.exe', $exePath)

    Write-Host "Installing x86..."
    cmd /c start /wait "$exePath" /verysilent
    del $exePath
    
    Write-Host "Downloading x64..."
    $exePath = "$env:TEMP\boost_1_67_0-msvc-14.0-64.exe"
    (New-Object Net.WebClient).DownloadFile('https://bintray.com/boostorg/release/download_file?file_path=1.67.0%2Fbinaries%2Fboost_1_67_0-msvc-14.0-64.exe', $exePath)

    Write-Host "Installing x64..."
    cmd /c start /wait "$exePath" /verysilent
    del $exePath

    [IO.Directory]::Move('C:\local\boost_1_67_0', 'C:\Libraries\boost_1_67_0')

    Remove-Item 'C:\local' -Force -Recurse

    Write-Host "Compressing..."

    compact /c /i /s:C:\Libraries\boost_1_67_0 | Out-Null
}

Write-Host "Boost libraries installed!" -ForegroundColor Green