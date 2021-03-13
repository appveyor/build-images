. "$PSScriptRoot\common.ps1"
#
# Upgrading PIP:
# https://stackoverflow.com/questions/30699782/access-is-denied-while-upgrading-pip-exe-on-windows/35580525#35580525
#

$pipVersion = "20.0.2"

function UpdatePythonPath($pythonPath) {
    $env:path = ($env:path -split ';' | Where-Object { -not $_.contains('\Python') }) -join ';'
    $env:path = "$pythonPath;$env:path"
}
function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    $x64userItems = @(Get-ChildItem "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + $x64userItems + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
        | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
        | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
        | Select UninstallString).UninstallString
}

function UninstallPython($pythonName) {
    $uninstallCommand = (GetUninstallString $pythonName)
    if($uninstallCommand) {
        Write-Host "Uninstalling $pythonName..." -NoNewline
        if($uninstallCommand.contains('/modify')) {
            $uninstallCommand = $uninstallCommand.replace('/modify', '')
            cmd /c start /wait "`"$uninstallCommand`"" /quiet /uninstall
        } elseif ($uninstallCommand.contains('/uninstall')) {
            $uninstallCommand = $uninstallCommand.replace('/uninstall', '')
            cmd /c start /wait "`"$uninstallCommand`"" /uninstall
        } else {
            $uninstallCommand = $uninstallCommand.replace('MsiExec.exe /I{', '/x{').replace('MsiExec.exe /X{', '/x{')
            cmd /c start /wait msiexec.exe $uninstallCommand /quiet
        }
        Write-Host "done"
    }
}

function UpdatePip($pythonPath) {
    Write-Host "Installing virtualenv for $pythonPath..." -ForegroundColor Cyan
    UpdatePythonPath "$pythonPath;$pythonPath\scripts"
    Start-ProcessWithOutput "python -m pip install --upgrade pip==$pipVersion" -IgnoreExitCode
    Start-ProcessWithOutput "pip --version" -IgnoreExitCode
    Start-ProcessWithOutput "pip install virtualenv" -IgnoreExitCode
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Write-Host "Downloading get-pip.py..." -ForegroundColor Cyan
# $pipPath = "$env:TEMP\get-pip.py"
# (New-Object Net.WebClient).DownloadFile('https://bootstrap.pypa.io/get-pip.py', $pipPath)

Write-Host "Downloading get-pip.py v2.6..." -ForegroundColor Cyan
$pipPath26 = "$env:TEMP\get-pip-26.py"
(New-Object Net.WebClient).DownloadFile('https://bootstrap.pypa.io/pip/2.6/get-pip.py', $pipPath26)

Write-Host "Downloading get-pip.py v3.3..." -ForegroundColor Cyan
$pipPath33 = "$env:TEMP\get-pip-33.py"
(New-Object Net.WebClient).DownloadFile('https://bootstrap.pypa.io/pip/3.3/get-pip.py', $pipPath33)

Write-Host "Downloading get-pip.py v3.4..." -ForegroundColor Cyan
$pipPath34 = "$env:TEMP\get-pip-34.py"
(New-Object Net.WebClient).DownloadFile('https://bootstrap.pypa.io/pip/3.4/get-pip.py', $pipPath34)

function InstallPythonMSI($version, $platform, $targetPath) {
    $urlPlatform = ""
    if ($platform -eq 'x64') {
        $urlPlatform = ".amd64"
    }

    Write-Host "Installing Python $version $platform to $($targetPath)..." -ForegroundColor Cyan

    $downloadUrl = "https://www.python.org/ftp/python/$version/python-$version$urlPlatform.msi"
    Write-Host "Downloading $($downloadUrl)..."
    $msiPath = "$env:TEMP\python-$version.msi"
    (New-Object Net.WebClient).DownloadFile($downloadUrl, $msiPath)

    Write-Host "Installing..."
    cmd /c start /wait msiexec /i "$msiPath" /passive ALLUSERS=1 TARGETDIR="$targetPath"
    Remove-Item $msiPath

    Start-ProcessWithOutput "$targetPath\python.exe --version"

    Write-Host "Installed Python $version" -ForegroundColor Green
}

function InstallPythonEXE($version, $platform, $targetPath) {
    $urlPlatform = ""
    if ($platform -eq 'x64') {
        $urlPlatform = "-amd64"
    }

    Write-Host "Installing Python $version $platform to $($targetPath)..." -ForegroundColor Cyan

    $downloadUrl = "https://www.python.org/ftp/python/$version/python-$version$urlPlatform.exe"
    Write-Host "Downloading $($downloadUrl)..."
    $exePath = "$env:TEMP\python-$version.exe"
    (New-Object Net.WebClient).DownloadFile($downloadUrl, $exePath)

    Write-Host "Installing..."
    cmd /c start /wait $exePath /quiet TargetDir="$targetPath" Shortcuts=0 Include_launcher=1 InstallLauncherAllUsers=1 Include_debug=1
    Remove-Item $exePath

    Start-ProcessWithOutput "$targetPath\python.exe --version"

    Write-Host "Installed Python $version" -ForegroundColor Green
}

if (-not $env:INSTALL_LATEST_ONLY) {
    # Python 2.6.6
    $python26 = (GetUninstallString 'Python 2.6.6')
    if($python26) {
        Write-Host 'Python 2.6.6 already installed'
    } else {

        InstallPythonMSI "2.6.6" "x64" "$env:SystemDrive\Python26-x64"
        InstallPythonMSI "2.6.6" "x86" "$env:SystemDrive\Python26"

        # install pip for python 2.6
        Write-Host "Installing pip for 2.6..." -ForegroundColor Cyan

        # Python 2.6
        UpdatePythonPath "$env:SystemDrive\Python26"
        Start-ProcessWithOutput "python $pipPath26" -IgnoreExitCode

        # Python 2.6 x64
        UpdatePythonPath "$env:SystemDrive\Python26-x64"
        Start-ProcessWithOutput "python $pipPath26" -IgnoreExitCode        
    }
}

# Python 2.7.18
$python27 = (GetUninstallString 'Python 2.7.18')
if($python27) {
    Write-Host 'Python 2.7.18 already installed'
} else {
    UninstallPython "Python 2.7.14"
    UninstallPython "Python 2.7.14 (64-bit)"
    UninstallPython "Python 2.7.15"
    UninstallPython "Python 2.7.15 (64-bit)"    
    UninstallPython "Python 2.7.16"
    UninstallPython "Python 2.7.16 (64-bit)"
    UninstallPython "Python 2.7.18"
    UninstallPython "Python 2.7.18 (64-bit)"    

    InstallPythonMSI "2.7.18" "x64" "$env:SystemDrive\Python27-x64"
    InstallPythonMSI "2.7.18" "x86" "$env:SystemDrive\Python27"
}

UpdatePip "$env:SystemDrive\Python27"
UpdatePip "$env:SystemDrive\Python27-x64"

if (-not $env:INSTALL_LATEST_ONLY) {
    # Python 3.3.5
    $python33 = (GetUninstallString 'Python 3.3.5')
    if($python33) {
        Write-Host 'Python 3.3.5 already installed'
    } else {

        InstallPythonMSI "3.3.5" "x64" "$env:SystemDrive\Python33-x64"
        InstallPythonMSI "3.3.5" "x86" "$env:SystemDrive\Python33"

        # install pip for python 3.3
        Write-Host "Installing pip for 3.3.5..." -ForegroundColor Cyan

        # Python 3.3
        UpdatePythonPath "$env:SystemDrive\Python33"
        Start-ProcessWithOutput "python $pipPath33" -IgnoreExitCode

        # Python 3.3 x64
        UpdatePythonPath "$env:SystemDrive\Python33-x64"
        Start-ProcessWithOutput "python $pipPath33" -IgnoreExitCode
    }

    UpdatePip "$env:SystemDrive\Python33"
    UpdatePip "$env:SystemDrive\Python33-x64"
}

if (-not $env:INSTALL_LATEST_ONLY) {
    # Python 3.4.4
    $python34 = (GetUninstallString 'Python 3.4.4')
    if($python34) {
        Write-Host 'Python 3.4.4 already installed'
    } else {

        UninstallPython "Python 3.4.3"
        UninstallPython "Python 3.4.3 (64-bit)"

        InstallPythonMSI "3.4.4" "x64" "$env:SystemDrive\Python34-x64"
        InstallPythonMSI "3.4.4" "x86" "$env:SystemDrive\Python34"

        # install pip for python 3.4
        Write-Host "Installing pip for 3.4..." -ForegroundColor Cyan

        # Python 3.4
        UpdatePythonPath "$env:SystemDrive\Python34"
        Start-ProcessWithOutput "python $pipPath34" -IgnoreExitCode

        # Python 3.4 x64
        UpdatePythonPath "$env:SystemDrive\Python34-x64"
        Start-ProcessWithOutput "python $pipPath34" -IgnoreExitCode        
    }

    UpdatePip "$env:SystemDrive\Python34"
    UpdatePip "$env:SystemDrive\Python34-x64" 
}

if (-not $env:INSTALL_LATEST_ONLY) {
    # Python 3.5.4
    $python35 = (GetUninstallString 'Python 3.5.4 (32-bit)')
    if($python35) {
        Write-Host 'Python 3.5.4 already installed'
    } else {

        UninstallPython "Python 3.5.3 (32-bit)"
        UninstallPython "Python 3.5.3 (64-bit)"

        InstallPythonEXE "3.5.4" "x64" "$env:SystemDrive\Python35-x64"
        InstallPythonEXE "3.5.4" "x86" "$env:SystemDrive\Python35"
    }

    UpdatePip "$env:SystemDrive\Python35"
    UpdatePip "$env:SystemDrive\Python35-x64"
}

if (-not $env:INSTALL_LATEST_ONLY) {

    # Python 3.6.8 x64
    $python36_x64 = (GetUninstallString 'Python 3.6.8 (64-bit)')
    if($python36_x64) {
        Write-Host 'Python 3.6.8 x64 already installed'
    } else {

        UninstallPython "Python 3.6.6 (64-bit)"
        UninstallPython "Python 3.6.7 (64-bit)"

        InstallPythonEXE "3.6.8" "x64" "$env:SystemDrive\Python36-x64"
    }

    # Python 3.6.8
    $python36 = (GetUninstallString 'Python 3.6.8 (32-bit)')
    if($python36) {
        Write-Host 'Python 3.6.8 already installed'
    } else {

        UninstallPython "Python 3.6.6 (32-bit)"
        UninstallPython "Python 3.6.7 (32-bit)"

        InstallPythonEXE "3.6.8" "x86" "$env:SystemDrive\Python36"
    }

    UpdatePip "$env:SystemDrive\Python36"
    UpdatePip "$env:SystemDrive\Python36-x64"
}

if (-not $env:INSTALL_LATEST_ONLY) {

    # Python 3.7.9 x64
    $python37_x64 = (GetUninstallString 'Python 3.7.9 (64-bit)')
    if($python37_x64) {
        Write-Host 'Python 3.7.9 x64 already installed'
    } else {

        UninstallPython "Python 3.7.0 (64-bit)"
        UninstallPython "Python 3.7.5 (64-bit)"
        UninstallPython "Python 3.7.7 (64-bit)"
        UninstallPython "Python 3.7.8 (64-bit)"

        InstallPythonEXE "3.7.9" "x64" "$env:SystemDrive\Python37-x64"
    }


    # Python 3.7.9
    $python37 = (GetUninstallString 'Python 3.7.9 (32-bit)')
    if($python37) {
        Write-Host 'Python 3.7.9 already installed'
    } else {
        UninstallPython "Python 3.7.0 (32-bit)"
        UninstallPython "Python 3.7.5 (32-bit)"
        UninstallPython "Python 3.7.7 (32-bit)"
        UninstallPython "Python 3.7.8 (32-bit)"

        InstallPythonEXE "3.7.9" "x86" "$env:SystemDrive\Python37"
    }

    UpdatePip "$env:SystemDrive\Python37"
    UpdatePip "$env:SystemDrive\Python37-x64"
}

# Python 3.8.7 x64
$python38_x64 = (GetUninstallString 'Python 3.8.7 (64-bit)')
if($python38_x64) {
    Write-Host 'Python 3.8.7 x64 already installed'
} else {

    UninstallPython "Python 3.8.0 (64-bit)"
    UninstallPython "Python 3.8.2 (64-bit)"
    UninstallPython "Python 3.8.5 (64-bit)"

    InstallPythonEXE "3.8.7" "x64" "$env:SystemDrive\Python38-x64"
}

# Python 3.8.7
$python38 = (GetUninstallString 'Python 3.8.7 (32-bit)')
if($python38) {
    Write-Host 'Python 3.8.7 already installed'
} else {

    UninstallPython "Python 3.8.0 (32-bit)"
    UninstallPython "Python 3.8.2 (32-bit)"
    UninstallPython "Python 3.8.5 (32-bit)"

    InstallPythonEXE "3.8.7" "x86" "$env:SystemDrive\Python38"
}

UpdatePip "$env:SystemDrive\Python38"
UpdatePip "$env:SystemDrive\Python38-x64"

# Python 3.9.1 x64
$python39_x64 = (GetUninstallString 'Python 3.9.1 (64-bit)')
if($python39_x64) {
    Write-Host 'Python 3.9.1 x64 already installed'
} else {

    #UninstallPython "Python 3.8.5 (64-bit)"

    InstallPythonEXE "3.9.1" "x64" "$env:SystemDrive\Python39-x64"
}

# Python 3.9.1
$python39 = (GetUninstallString 'Python 3.9.1 (32-bit)')
if($python39) {
    Write-Host 'Python 3.9.1 already installed'
} else {

    #UninstallPython "Python 3.8.5 (32-bit)"

    InstallPythonEXE "3.9.1" "x86" "$env:SystemDrive\Python39"
}

UpdatePip "$env:SystemDrive\Python39"
UpdatePip "$env:SystemDrive\Python39-x64"

if (-not $env:INSTALL_LATEST_ONLY) {
    Add-Path C:\Python27
    Add-Path C:\Python27\Scripts
} else {
    Add-Path C:\Python39
    Add-Path C:\Python39\Scripts
}

# restore .py file mapping
# https://github.com/appveyor/ci/issues/575
cmd /c ftype Python.File="C:\Windows\py.exe" "`"%1`"" %*

# check default python
Write-Host "Default Python installed:" -ForegroundColor Cyan
$r = (cmd /c python.exe --version 2>&1)
$r.Exception

# py.exe
Write-Host "Py.exe installed:" -ForegroundColor Cyan
$r = (py.exe --version)
$r

function CheckPython($path) {
    if (Test-Path "$path\python.exe") {
        Start-ProcessWithOutput "$path\python.exe --version"
    } else {
        throw "python.exe is missing in $path"
    }

    if (Test-Path "$path\Scripts\pip.exe") {
        Start-ProcessWithOutput "$path\Scripts\pip.exe --version"
        Start-ProcessWithOutput "$path\Scripts\virtualenv.exe --version"
    } else {
        Write-Host "pip.exe is missing in $path" -ForegroundColor Red
    }
}

if (-not $env:INSTALL_LATEST_ONLY) {
    CheckPython 'C:\Python26'
    CheckPython 'C:\Python26-x64'
}

CheckPython 'C:\Python27'
CheckPython 'C:\Python27-x64'

if (-not $env:INSTALL_LATEST_ONLY) {
    CheckPython 'C:\Python33'
    CheckPython 'C:\Python33-x64'
    CheckPython 'C:\Python34'
    CheckPython 'C:\Python34-x64'
    CheckPython 'C:\Python35'
    CheckPython 'C:\Python35-x64'
    CheckPython 'C:\Python36'
    CheckPython 'C:\Python36-x64'
    CheckPython 'C:\Python37'
    CheckPython 'C:\Python37-x64'
    CheckPython 'C:\Python38'
    CheckPython 'C:\Python38-x64'
}
CheckPython 'C:\Python39'
CheckPython 'C:\Python39-x64'