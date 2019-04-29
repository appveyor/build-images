Write-Host "Installing AppVeyor logger for VSTest.Console..." -ForegroundColor Cyan

$vs2013TestWindowPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow"
$vs2015TestWindowPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow"
$vs2017TestWindowPath1 = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\Common7\IDE\CommonExtensions\Microsoft\TestWindow"
$vs2017TestWindowPath2 = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\Common7\IDE\Extensions\TestPlatform"

$vs2013Path = "$vs2013TestWindowPath\Extensions"
$vs2015Path = "$vs2015TestWindowPath\Extensions"
$vs2017Path1 = "$vs2017TestWindowPath1\Extensions"
$vs2017Path2 = "$vs2017TestWindowPath2\Extensions"

Remove-Path $vs2013TestWindowPath
Remove-Path $vs2015TestWindowPath
Remove-Path $vs2017TestWindowPath1
Remove-Path $vs2017TestWindowPath2

# VS 2013
Remove-Item "$vs2013Path\appveyor.*" -Force
$zipPath = "$($env:TEMP)\Appveyor.MSTestLogger.zip"
(New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/Appveyor.MSTestLogger.zip', $zipPath)
7z x $zipPath -y -o"$vs2013Path" | Out-Null

if(Test-Path $vs2015Path) {
    # VS 2015
    Remove-Item "$vs2015Path\appveyor.*" -Force
    7z x $zipPath -y -o"$vs2015Path" | Out-Null
}

if(Test-Path $vs2017Path1) {
    # VS 2017
    Remove-Item "$vs2017Path1\appveyor.*" -Force
    $zipPath2 = "$($env:TEMP)\Appveyor.MSTestLogger.VS2017.zip"
    (New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/Appveyor.MSTestLogger.VS2017.zip', $zipPath2)
    7z x $zipPath2 -y -o"$vs2017Path1" | Out-Null
    del $zipPath2

    # MSTest Adapter
    #$tempPath = "$env:TEMP\MSTestAdapter"
    #nuget install MSTest.TestAdapter -version 1.1.4-preview -prerelease -excludeversion -outputdirectory $tempPath

    #copy "$tempPath\MSTest.TestAdapter\build\_common\*" $vs2017Path -Force
    #del $tempPath -Recurse -Force
}

if(Test-Path $vs2017Path2) {
    # VS 2017
    Remove-Item "$vs2017Path2\appveyor.*" -Force
    $zipPath2 = "$($env:TEMP)\Appveyor.MSTestLogger.VS2017.zip"
    (New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/Appveyor.MSTestLogger.VS2017.zip', $zipPath2)
    7z x $zipPath2 -y -o"$vs2017Path2" | Out-Null
    del $zipPath2
}

del $zipPath

# modify PATH
if(Test-Path $vs2017Path2) {
    Add-Path $vs2017TestWindowPath2
} elseif (Test-Path $vs2015Path) {
    Add-Path $vs2015TestWindowPath
} else {
    Add-Path $vs2013TestWindowPath
}

Write-Host "AppVeyor VSTest.Console logger installed" -ForegroundColor Green