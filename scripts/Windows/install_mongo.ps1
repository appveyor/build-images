$installDir = "C:\MongoDB"

function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    $x64userItems = @(Get-ChildItem "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + $x64userItems + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
        | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
        | Where-Object { $_.DisplayName -and $_.DisplayName.contains($productName) } `
        | Select UninstallString).UninstallString
}

function UninstallMongo ($name){
    $uninstallCommand = (GetUninstallString $name)
    if($uninstallCommand) {
        Write-Host "Uninstalling $name"

        $uninstallCommand = $uninstallCommand.replace('MsiExec.exe /I{', '/x{').replace('MsiExec.exe /X{', '/x{')
        cmd /c start /wait msiexec.exe $uninstallCommand /quiet

        Write-Host "Uninstalled $name" -ForegroundColor Green
    }
}

function UninstallMongoCompass {
    $uninstallCommand = (GetUninstallString "MongoDB Compass")
    if($uninstallCommand) {
        Write-Host "Uninstalling Mongo Compass"

            $uninstallCommand = $uninstallCommand.replace('--uninstall', '').replace('"', '')
            & $uninstallCommand --uninstall

        Write-Host "Uninstalled Mongo Compass" -ForegroundColor Green
    }
}

if (Test-Path $installDir) {
    Write-Host "Removing existing installation"
    cmd /c start /wait sc delete MongoDB
    UninstallMongo "MongoDB"
    Remove-Item $installDir -Recurse -Force
}

Write-Host "Installing MongoDB..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\mongodb.msi"
(New-Object Net.WebClient).DownloadFile('https://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus-ssl-4.0.1-signed.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /q /i $msiPath INSTALLLOCATION=$installDir ADDLOCAL="all"
del $msiPath

Write-Host "Creating Mongo data and log dirs"
mkdir c:\mongodb\data\db -Force | Out-Null
mkdir c:\mongodb\log -Force | Out-Null

@(
    "systemLog:",
    "  destination: file",
    "  path: $installDir\log\mongod.log",
    "storage:",
    "  dbPath: $installDir\data\db"
) | Out-File "$installDir\mongod.cfg"

Write-Host "Removing Mongo service"
cmd /c start /wait sc delete MongoDB

Write-Host "Creating Mongo service"
cmd /c start /wait sc create MongoDB binPath= "$installDir\bin\mongod.exe --service --config=$installDir\mongod.cfg" DisplayName= "MongoDB" start= "demand"

& $installDir\bin\mongod --version

Get-Process "MongoDBCompassCommunity" | Stop-Process
UninstallMongoCompass

# remove SSL libs from System32
Remove-Item 'C:\Windows\System32\libcrypto-1_1-x64.dll' -Force
Remove-Item 'C:\Windows\System32\libeay32.dll' -Force
Remove-Item 'C:\Windows\System32\libssl-1_1-x64.dll' -Force
Remove-Item 'C:\Windows\System32\libssl32.dll' -Force

Write-Host "MongoDB installed" -ForegroundColor Green