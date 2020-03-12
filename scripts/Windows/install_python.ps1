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

Write-Host "Downloading get-pip.py..." -ForegroundColor Cyan
$pipPath = "$env:TEMP\get-pip.py"
(New-Object Net.WebClient).DownloadFile('https://bootstrap.pypa.io/get-pip.py', $pipPath)

Write-Host "Downloading get-pip.py v2.6..." -ForegroundColor Cyan
$pipPath26 = "$env:TEMP\get-pip-26.py"
(New-Object Net.WebClient).DownloadFile('https://bootstrap.pypa.io/2.6/get-pip.py', $pipPath26)

Write-Host "Downloading get-pip.py v3.3..." -ForegroundColor Cyan
$pipPath33 = "$env:TEMP\get-pip-33.py"
(New-Object Net.WebClient).DownloadFile('https://bootstrap.pypa.io/3.3/get-pip.py', $pipPath33)

if (-not $env:INSTALL_LATEST_ONLY) {
    # Python 2.6.6
    $python26 = (GetUninstallString 'Python 2.6.6')
    if($python26) {
        Write-Host 'Python 2.6.6 already installed'
    } else {
        Write-Host "Installing Python 2.6.6..." -ForegroundColor Cyan
        Write-Host "Downloading..."
        $msiPath = "$env:TEMP\python-2.6.6.msi"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/2.6.6/python-2.6.6.msi', $msiPath)
        Write-Host "Installing..."
        cmd /c start /wait msiexec /i "$msiPath" /passive ALLUSERS=1 TARGETDIR=C:\Python26
        del $msiPath

        C:\Python26\python --version

        # Python 2.6.6 (64-bit)
        Write-Host "Downloading..."
        $msiPath = "$env:TEMP\python-2.6.6.amd64.msi"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/2.6.6/python-2.6.6.amd64.msi', $msiPath)
        Write-Host "Installing..."
        cmd /c start /wait msiexec /i "$msiPath" /passive ALLUSERS=1 TARGETDIR=C:\Python26-x64
        del $msiPath

        C:\Python26-x64\python --version

        # install pip for python 3.3
        Write-Host "Installing pip for Python 2.6..." -ForegroundColor Cyan

        # Python 2.6
        UpdatePythonPath "C:\Python26"
        python --version
        python $pipPath26

        # Python 2.6 x64
        UpdatePythonPath "C:\Python26-x64"
        python --version
        python $pipPath26
    }

    UpdatePip 'C:\Python26'
    UpdatePip 'C:\Python26-x64'
}

# Python 2.7.17
$python27 = (GetUninstallString 'Python 2.7.17')
if($python27) {
    Write-Host 'Python 2.7.17 already installed'
} else {
    UninstallPython "Python 2.7.14"
    UninstallPython "Python 2.7.14 (64-bit)"
    UninstallPython "Python 2.7.15"
    UninstallPython "Python 2.7.15 (64-bit)"    
    UninstallPython "Python 2.7.16"
    UninstallPython "Python 2.7.16 (64-bit)"   

    Write-Host "Installing Python 2.7.17..." -ForegroundColor Cyan
    Write-Host "Downloading..."
    $msiPath = "$env:TEMP\python-2.7.17.msi"
    (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/2.7.17/python-2.7.17.msi', $msiPath)
    Write-Host "Installing..."
    cmd /c start /wait msiexec /i "$msiPath" /passive ALLUSERS=1 TARGETDIR=C:\Python27
    del $msiPath

    C:\Python27\python --version

    # Python 2.7.17 (64-bit)
    Write-Host "Downloading..."
    $msiPath = "$env:TEMP\python-2.7.17.amd64.msi"
    (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/2.7.17/python-2.7.17.amd64.msi', $msiPath)
    Write-Host "Installing..."
    cmd /c start /wait msiexec /i "$msiPath" /passive ALLUSERS=1 TARGETDIR=C:\Python27-x64
    del $msiPath

    C:\Python27-x64\python --version
}

UpdatePip 'C:\Python27'
UpdatePip 'C:\Python27-x64'

if (-not $env:INSTALL_LATEST_ONLY) {
    # Python 3.3.5
    $python33 = (GetUninstallString 'Python 3.3.5')
    if($python33) {
        Write-Host 'Python 3.3.5 already installed'
    } else {
        Write-Host "Installing Python 3.3.5..." -ForegroundColor Cyan
        Write-Host "Downloading..."
        $msiPath = "$env:TEMP\python-3.3.5.msi"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.3.5/python-3.3.5.msi', $msiPath)
        Write-Host "Installing..."
        cmd /c start /wait msiexec /i "$msiPath" /passive ALLUSERS=1 TARGETDIR=C:\Python33
        del $msiPath

        C:\Python33\python --version

        # Python 3.3.5 (64-bit)
        Write-Host "Downloading..."
        $msiPath = "$env:TEMP\python-3.3.5.amd64.msi"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.3.5/python-3.3.5.amd64.msi', $msiPath)
        Write-Host "Installing..."
        cmd /c start /wait msiexec /i "$msiPath" /passive ALLUSERS=1 TARGETDIR=C:\Python33-x64
        del $msiPath

        C:\Python33-x64\python --version

        # install pip for python 3.3
        Write-Host "Installing pip for 3.3.5..." -ForegroundColor Cyan

        # Python 3.3
        UpdatePythonPath "C:\Python33"
        python --version
        python $pipPath33

        # Python 3.3 x64
        UpdatePythonPath "C:\Python33-x64"
        python --version
        python $pipPath33
    }

    UpdatePip 'C:\Python33'
    UpdatePip 'C:\Python33-x64'
}

if (-not $env:INSTALL_LATEST_ONLY) {
    # Python 3.4.4
    $python34 = (GetUninstallString 'Python 3.4.4')
    if($python34) {
        Write-Host 'Python 3.4.4 already installed'
    } else {

        UninstallPython "Python 3.4.3"
        UninstallPython "Python 3.4.3 (64-bit)"

        # Python 3.4.4
        Write-Host "Installing Python 3.4.4..." -ForegroundColor Cyan

        # Python 3.4.4 (64-bit)
        Write-Host "Downloading..."
        $msiPath = "$env:TEMP\python-3.4.4.amd64.msi"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.4.4/python-3.4.4.amd64.msi', $msiPath)
        Write-Host "Installing..."
        cmd /c start /wait msiexec /i "$msiPath" /passive ALLUSERS=1 TARGETDIR=C:\Python34-x64
        del $msiPath

        C:\Python34-x64\python --version

        Write-Host "Downloading..."
        $msiPath = "$env:TEMP\python-3.4.4.msi"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.4.4/python-3.4.4.msi', $msiPath)
        Write-Host "Installing..."
        cmd /c start /wait msiexec /i "$msiPath" /passive ALLUSERS=1 TARGETDIR=C:\Python34
        del $msiPath

        C:\Python34\python --version     
    }

    UpdatePip 'C:\Python34'
    UpdatePip 'C:\Python34-x64' 
}

if (-not $env:INSTALL_LATEST_ONLY) {
    # Python 3.5.4
    $python35 = (GetUninstallString 'Python 3.5.4 (32-bit)')
    if($python35) {
        Write-Host 'Python 3.5.4 already installed'
    } else {

        UninstallPython "Python 3.5.3 (32-bit)"
        UninstallPython "Python 3.5.3 (64-bit)"

        # Python 3.5.4
        Write-Host "Installing Python 3.5.4..." -ForegroundColor Cyan
        Write-Host "Downloading..."
        $exePath = "$env:TEMP\python-3.5.4.exe"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.5.4/python-3.5.4.exe', $exePath)
        Write-Host "Installing..."
        cmd /c start /wait $exePath /quiet TargetDir=C:\Python35 Shortcuts=0 Include_launcher=0 InstallLauncherAllUsers=0
        del $exePath
        Write-Host "Python 3.5.4 x86 installed"

        C:\Python35\python --version

        # Python 3.5.4 x64
        Write-Host "Downloading..."
        $exePath = "$env:TEMP\python-3.5.4-amd64.exe"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.5.4/python-3.5.4-amd64.exe', $exePath)
        Write-Host "Installing..."
        cmd /c start /wait $exePath /quiet TargetDir=C:\Python35-x64 Shortcuts=0 Include_launcher=0 InstallLauncherAllUsers=0
        Start-sleep -s 10
        del $exePath
        C:\Python35-x64\python --version

        Write-Host "Python 3.5.4 x64 installed"
    }

    UpdatePip 'C:\Python35'
    UpdatePip 'C:\Python35-x64'
}

if (-not $env:INSTALL_LATEST_ONLY) {
    # Python 3.6.8
    $python36 = (GetUninstallString 'Python 3.6.8 (32-bit)')
    if($python36) {
        Write-Host 'Python 3.6.8 already installed'
    } else {

        UninstallPython "Python 3.6.6 (32-bit)"
        UninstallPython "Python 3.6.7 (32-bit)"

        # Python 3.6.8
        Write-Host "Installing Python 3.6.8..." -ForegroundColor Cyan
        Write-Host "Downloading..."
        $exePath = "$env:TEMP\python-3.6.8.exe"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.6.8/python-3.6.8.exe', $exePath)
        Write-Host "Installing..."
        cmd /c start /wait $exePath /quiet TargetDir=C:\Python36 Shortcuts=0 Include_launcher=0 InstallLauncherAllUsers=0
        del $exePath
        Write-Host "Python 3.6.8 x86 installed"

        C:\Python36\python --version
    }

    $python36_x64 = (GetUninstallString 'Python 3.6.8 (64-bit)')
    if($python36_x64) {
        Write-Host 'Python 3.6.8 x64 already installed'
    } else {

        UninstallPython "Python 3.6.6 (64-bit)"
        UninstallPython "Python 3.6.7 (64-bit)"

        # Python 3.6.8
        Write-Host "Installing Python 3.6.8 x64..." -ForegroundColor Cyan
        Write-Host "Downloading..."
        $exePath = "$env:TEMP\python-3.6.8-amd64.exe"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.6.8/python-3.6.8-amd64.exe', $exePath)
        Write-Host "Installing..."
        cmd /c start /wait $exePath /quiet TargetDir=C:\Python36-x64 Shortcuts=0 Include_launcher=1 InstallLauncherAllUsers=1
        Start-sleep -s 10
        del $exePath
        C:\Python36-x64\python --version

        Write-Host "Python 3.6.8 x64 installed"
    }

    UpdatePip 'C:\Python36'
    UpdatePip 'C:\Python36-x64'
}

if (-not $env:INSTALL_LATEST_ONLY) {
    # Python 3.7.5
    $python37 = (GetUninstallString 'Python 3.7.7 (32-bit)')
    if($python37) {
        Write-Host 'Python 3.7.7 already installed'
    } else {
        UninstallPython "Python 3.7.5 (32-bit)"

        # Python 3.7.5
        Write-Host "Installing Python 3.7.7..." -ForegroundColor Cyan
        Write-Host "Downloading..."
        $exePath = "$env:TEMP\python-3.7.7.exe"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.7.7/python-3.7.7.exe', $exePath)
        Write-Host "Installing..."
        cmd /c start /wait $exePath /quiet TargetDir=C:\Python37 Shortcuts=0 Include_launcher=0 InstallLauncherAllUsers=0 Include_debug=1
        del $exePath
        Write-Host "Python 3.7.7 x86 installed"

        C:\Python37\python --version
    }

    $python37_x64 = (GetUninstallString 'Python 3.7.7 (64-bit)')
    if($python37_x64) {
        Write-Host 'Python 3.7.7 x64 already installed'
    } else {

        UninstallPython "Python 3.7.5 (64-bit)"

        # Python 3.7.5
        Write-Host "Installing Python 3.7.7 x64..." -ForegroundColor Cyan
        Write-Host "Downloading..."
        $exePath = "$env:TEMP\python-3.7.7-amd64.exe"
        (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.7.7/python-3.7.7-amd64.exe', $exePath)
        Write-Host "Installing..."
        cmd /c start /wait $exePath /quiet TargetDir=C:\Python37-x64 Shortcuts=0 Include_launcher=1 InstallLauncherAllUsers=1 Include_debug=1
        Start-sleep -s 10
        del $exePath
        C:\Python37-x64\python --version

        Write-Host "Python 3.7.7 x64 installed"
    }

    UpdatePip 'C:\Python37'
    UpdatePip 'C:\Python37-x64'
}

# Python 3.8.0
$python38 = (GetUninstallString 'Python 3.8.2 (32-bit)')
if($python38) {
    Write-Host 'Python 3.8.2 already installed'
} else {

    UninstallPython "Python 3.8.0 (32-bit)"

    # Python 3.8.0
    Write-Host "Installing Python 3.8.2..." -ForegroundColor Cyan
    Write-Host "Downloading..."
    $exePath = "$env:TEMP\python-3.8.2.exe"
    (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.8.2/python-3.8.2.exe', $exePath)
    Write-Host "Installing..."
    cmd /c start /wait $exePath /quiet TargetDir=C:\Python38 Shortcuts=0 Include_launcher=0 InstallLauncherAllUsers=0 Include_debug=1
    del $exePath
    Write-Host "Python 3.8.2 x86 installed"

    C:\Python38\python --version
}

$python38_x64 = (GetUninstallString 'Python 3.8.2 (64-bit)')
if($python38_x64) {
    Write-Host 'Python 3.8.2 x64 already installed'
} else {

    UninstallPython "Python 3.8.0 (64-bit)"

    # Python 3.8.0
    Write-Host "Installing Python 3.8.2 x64..." -ForegroundColor Cyan
    Write-Host "Downloading..."
    $exePath = "$env:TEMP\python-3.8.2-amd64.exe"
    (New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.8.2/python-3.8.2-amd64.exe', $exePath)
    Write-Host "Installing..."
    cmd /c start /wait $exePath /quiet TargetDir=C:\Python38-x64 Shortcuts=0 Include_launcher=1 InstallLauncherAllUsers=1 Include_debug=1
    Start-sleep -s 10
    del $exePath
    C:\Python38-x64\python --version

    Write-Host "Python 3.8.2 x64 installed"
}

UpdatePip 'C:\Python38'
UpdatePip 'C:\Python38-x64'

del $pipPath

if (-not $env:INSTALL_LATEST_ONLY) {
    Add-Path C:\Python27
    Add-Path C:\Python27\Scripts
} else {
    Add-Path C:\Python38
    Add-Path C:\Python38\Scripts
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
    if (-not (Test-Path "$path\python.exe")) { throw "python.exe is missing in $path"; }
    elseif (-not (Test-Path "$path\Scripts\pip.exe")) { Write-Host "pip.exe is missing in $path" -ForegroundColor Red; }
    else { Write-Host "$path is OK" -ForegroundColor Green; }

    Start-ProcessWithOutput "$path\python.exe --version"
    Start-ProcessWithOutput "$path\Scripts\pip.exe --version"
    Start-ProcessWithOutput "$path\Scripts\virtualenv.exe --version"
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
}
CheckPython 'C:\Python38'
CheckPython 'C:\Python38-x64'