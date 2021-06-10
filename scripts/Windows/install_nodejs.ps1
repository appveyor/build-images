function Install-Nodejs {

    $avvmRoot = "$env:SYSTEMDRIVE\avvm\node"

    $nodeVersions = @(
        #"0.10.26",
        #"0.10.27",
        #"0.10.28",
        #"0.10.29",
        #"0.10.30",
        #"0.10.31",
        #"0.10.32",
        #"0.10.33",
        #"0.10.34",
        #"0.10.35",
        #"0.10.36",
        #"0.10.37",
        #"0.10.38",
        #"0.10.39",
        #"0.10.40",
        #"0.10.41",
        #"0.10.42",
        #"0.10.43",
        #"0.10.44",
        #"0.10.45",
        #"0.10.46",
        "0.10.47",
        "0.10.48",
        #"0.11.12",
        #"0.11.13",
        "0.11.15",
        "0.11.16",
        #"0.12.0",
        #"0.12.1",
        #"0.12.2",
        #"0.12.3",
        #"0.12.4",
        #"0.12.5",
        #"0.12.6",
        #"0.12.7",
        #"0.12.8",
        #"0.12.9",
        #"0.12.10",
        #"0.12.11",
        #"0.12.12",
        #"0.12.13",
        #"0.12.14",
        #"0.12.15",
        #"0.12.16",
        "0.12.17",
        "0.12.18",
        #"0.8.25",
        #"0.8.26",
        "0.8.27",
        "0.8.28",
        "1.0.0",
        "1.0.1",
        "1.0.2",
        "1.0.3",
        "1.0.4",
        #"1.1.0",
        #"1.2.0",
        #"1.3.0",
        #"1.4.1",
        #"1.4.2",
        #"1.4.3",
        #"1.5.0",
        #"1.5.1",
        #"1.6.0",
        #"1.6.1",
        #"1.6.2",
        #"1.6.3",
        #"1.6.4",
        "1.7.1",
        "1.8.1",
        #"2.0.0",
        #"2.0.1",
        #"2.0.2",
        #"2.1.0",
        #"2.2.1",
        #"2.3.0",
        #"2.3.1",
        #"2.3.2",
        #"2.3.3",
        #"2.3.4",
        "2.4.0",
        "2.5.0",
        #"3.0.0",
        #"3.1.0",
        #"3.2.0",
        "3.3.0",
        "4.0.0",
        "4.1.0",
        "4.1.1",
        "4.1.2",
        "4.2.0",
        "4.2.1",
        "4.2.1",
        "4.2.2",
        "4.2.3",
        "4.2.4",
        "4.2.5",
        "4.2.6",
        "4.3.0",
        "4.3.1",
        "4.3.2",
        "4.4.0",
        "5.0.0",
        "5.1.0",
        "5.1.1",
        "5.2.0",
        "5.3.0",
        "5.4.0",
        "5.4.1",
        "5.5.0",
        "5.6.0",
        "5.7.0",
        "5.7.1",
        "5.8.0",
        "5.9.0",
        "5.9.1",
        "5.10.0",
        "5.10.1",
        "5.11.0",
        "5.12.0",
        "6.0.0",
        "6.1.0",
        "6.2.0",
        "6.2.1",
        "4.4.1",
        "4.4.2",
        "4.4.3",
        "4.4.4",
        "4.4.5",
        "4.4.6",
        "4.4.7",
        "4.5.0",
        "4.6.0",
        "4.6.1",
        "4.6.2",
        "4.7.0",
        "4.7.1",
        "4.7.2",
        "4.7.3",
        "4.8.0",
        "4.8.1",
        "4.8.2",
        "4.8.3",
        "4.8.4",
        "4.8.5",
        "4.8.6",
        "4.8.7",
        "4.9.1",
        "6.2.2",
        "6.3.0",
        "6.3.1",
        "6.4.0",
        "6.5.0",
        "6.6.0",
        "6.7.0",
        "6.8.0",
        "6.8.1",
        "6.9.0",
        "6.9.1",
        "6.9.2",
        "6.9.3",
        "6.9.4",
        "6.9.5",
        "6.10.0",
        "6.10.1",
        "6.10.2",
        "6.10.3",
        "6.11.0",
        "6.11.1",
        "6.11.2",
        "6.11.3",
        "6.11.4",
        "6.11.5",
        "6.12.0",
        "6.12.1",
        "6.12.2",
        "6.12.3",
        "6.13.0",
        "6.13.1",
        "6.14.1",
        "6.14.2",
        "6.14.3",
        "6.14.4",
        "6.15.0",
        "6.15.1",
        "6.16.0",
        "6.17.0",
        "6.17.1",
        "7.0.0",
        "7.1.0",
        "7.2.0",
        "7.2.1",
        "7.3.0",
        "7.4.0",
        "7.5.0",
        "7.6.0",
        "7.7.0",
        "7.7.1",
        "7.7.2",
        "7.7.3",
        "7.7.4",
        "7.8.0",
        "7.9.0",
        "7.10.0",
        "7.10.1",
        "8.0.0",
        "8.1.0",
        "8.1.1",
        "8.1.2",
        "8.1.3",
        "8.1.4",
        "8.2.0",
        "8.2.1",
        "8.3.0",
        "8.4.0",
        "8.5.0",
        "8.6.0",
        "8.7.0",
        "8.8.0",
        "8.8.1",
        "8.9.0",
        "8.9.1",
        "8.9.2",
        "8.9.3",
        "8.9.4",
        "8.10.0",
        "9.0.0",
        "9.1.0",
        "9.2.0",
        "9.2.1",
        "9.3.0",
        "9.4.0",
        "9.5.0",
        "9.6.0",
        "9.6.1",
        "9.7.0",
        "9.7.1",
        "9.8.0",
        "9.9.0",
        "9.10.1",
        "9.11.1",
        "9.11.2",
        "10.0.0",
        "10.1.0",
        "10.2.0",
        "10.2.1",
        "10.3.0",
        "10.4.0",
        "10.4.1",
        "10.5.0",
        "10.6.0",
        "10.7.0",
        "10.8.0",
        "10.9.0",
        "10.10.0",
        "10.11.0",
        "10.12.0",
        "10.13.0",
        "10.14.0",
        "10.14.1",
        "10.14.2",
        "10.15.0",
        "10.15.1",
        "10.15.2",
        "10.15.3",
        "10.16.0",
        "10.17.0",
        "10.18.0",
        "10.18.1",
        "10.19.0",
        "10.20.1",
        "10.21.0",
        "10.22.0",
        "10.23.0",
        "10.23.1",
        "10.24.1",
        "11.0.0",
        "11.1.0",
        "11.2.0",
        "11.3.0",
        "11.4.0",
        "11.5.0",
        "11.6.0",
        "11.7.0",
        "11.8.0",
        "11.9.0",
        "11.10.0",
        "11.10.1",
        "11.11.0",
        "11.12.0",
        "11.13.0",
        "11.14.0",
        "11.15.0",
        "12.0.0",
        "12.1.0",
        "12.4.0",
        "12.5.0",
        "12.6.0",
        "12.8.1",
        "12.12.0",
        "12.13.0",
        "12.13.1",
        "12.14.0",
        "12.14.1",
        "12.15.0",
        "12.16.0",
        "12.16.1",
        "12.16.2",
        "12.16.3",
        "12.17.0",
        "12.18.2",
        "12.18.3",
        "12.19.0",
        "12.20.0",
        "12.20.1",
        "12.22.1",
        "13.0.0",
        "13.0.1",
        "13.1.0",
        "13.2.0",
        "13.3.0",
        "13.4.0",
        "13.5.0",
        "13.6.0",
        "13.7.0",
        "13.8.0",
        "13.9.0",
        "13.10.0",
        "13.10.1",
        "13.11.0",
        "13.12.0",
        "13.13.0",
        "13.14.0",
        "14.0.0",
        "14.1.0",
        "14.2.0",
        "14.3.0",
        "14.4.0",
        "14.5.0",
        "14.6.0",
        "14.7.0",
        "14.8.0",
        "14.9.0",
        "14.15.0",
        "14.15.1",
        "14.15.4",
        "14.17.0",
        "15.0.0",
        "15.2.0",
        "15.4.0",
        "15.5.1",
        "15.6.0",
        "15.14.0",
        "16.3.0",
        "8.11.1",
        "8.11.2",
        "8.11.3",
        "8.11.4",
        "8.12.0",
        "8.13.0",
        "8.14.0",
        "8.14.1",
        "8.15.0",
        "8.15.1",
        "8.16.0",
        "8.16.2",
        "8.17.0"
        )

    $nodePlatforms = @(
        "x64",
        "x86"
    )

    $fileTemplates = @{
        "nodejs_x64" = @{
            "files_ps1" = '$files = @{ "nodejs" = "$env:ProgramFiles\nodejs" }'
            "install_ps1" = 'reg import "$PSScriptRoot\install.reg" 2> $null'
            "uninstall_ps1" = 'Remove-Item -Path ''HKCU:\Software\Node.js'' -Recurse -Force'
            "install_reg" = 'Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Node.js]
"InstallPath"="C:\\Program Files\\nodejs\\"
"Version"="{version}"

[HKEY_CURRENT_USER\Software\Node.js\Components]
"DocumentationShortcuts"=dword:00000001
"EnvironmentPathNpmModules"=dword:00000001'
        }
        "nodejs_x86" = @{
            "files_ps1" = '$files = @{ "nodejs" = "${env:ProgramFiles(x86)}\nodejs" }'
            "install_ps1" = 'reg import "$PSScriptRoot\install.reg" 2> $null'
            "uninstall_ps1" = 'Remove-Item -Path ''HKCU:\Software\Node.js'' -Recurse -Force'
            "install_reg" = 'Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Node.js]
"InstallPath"="C:\\Program Files (x86)\\nodejs\\"
"Version"="{version}"

[HKEY_CURRENT_USER\Software\Node.js\Components]
"DocumentationShortcuts"=dword:00000001
"EnvironmentPathNpmModules"=dword:00000001'
        }
        "iojs_x64" = @{
            "files_ps1" = '$files = @{ "iojs" = "$env:ProgramFiles\iojs" }'
            "install_ps1" = 'reg import "$PSScriptRoot\install.reg" 2> $null'
            "uninstall_ps1" = 'Remove-Item -Path ''HKCU:\Software\io.js'' -Recurse -Force'
            "install_reg" = 'Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\io.js]
"InstallPath"="C:\\Program Files\\iojs\\"
"Version"="{version}"

[HKEY_CURRENT_USER\Software\io.js\Components]
"DocumentationShortcuts"=dword:00000001
"EnvironmentPathNpmModules"=dword:00000001'
        }
        "iojs_x86" = @{
            "files_ps1" = '$files = @{ "iojs" = "${env:ProgramFiles(x86)}\iojs" }'
            "install_ps1" = 'reg import "$PSScriptRoot\install.reg" 2> $null'
            "uninstall_ps1" = 'Remove-Item -Path ''HKCU:\Software\io.js'' -Recurse -Force'
            "install_reg" = 'Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\io.js]
"InstallPath"="C:\\Program Files (x86)\\iojs\\"
"Version"="{version}"

[HKEY_CURRENT_USER\Software\io.js\Components]
"DocumentationShortcuts"=dword:00000001
"EnvironmentPathNpmModules"=dword:00000001'
        }
    }

    function Get-Version([string]$str) {
        $versionDigits = $str.Split('.')
        $version = @{
            major = -1
            minor = -1
            build = -1
            revision = -1
            number = 0
        }

        if($versionDigits.Length -gt 0) {
            $version.major = [int]$versionDigits[0]
        }
        if($versionDigits.Length -gt 1) {
            $version.minor = [int]$versionDigits[1]
        }
        if($versionDigits.Length -gt 2) {
            $version.build = [int]$versionDigits[2]
        }
        if($versionDigits.Length -gt 3) {
            $version.revision = [int]$versionDigits[3]
        }

        for($i = 0; $i -lt $versionDigits.Length; $i++) {
            $version.number += [long]$versionDigits[$i] -shl 16 * (3 - $i)
        }

        return $version
    }

    function ProductName($version) {
        $v = Get-Version $version
        if ($v.Major -eq 0 -or $v.Major -ge 4) {
            return 'Node.js'
        } else {
            return 'io.js'
        }
    }

    function ProductInstallDirectory($version, $platform) {
        $v = Get-Version $version
        if(($v.Major -eq 0 -or $v.Major -ge 4) -and $platform -eq 'x86') {
            return "${env:ProgramFiles(x86)}\nodejs"
        } elseif ($v.Major -ge 1 -and $platform -eq 'x86') {
            return "${env:ProgramFiles(x86)}\iojs"
        } elseif ($v.Major -eq 0 -or $v.Major -ge 4) {
            return "$env:ProgramFiles\nodejs"
        } elseif ($v.Major -ge 1) {
            return "$env:ProgramFiles\iojs"
        }
    }

    function Get-NodeJsInstallPackage {
        param
        (
	        [Parameter(Mandatory=$true)]
            [string]$version,

            [Parameter(Mandatory=$false)]
            [string]$bitness = 'x86'
        )

        $v = Get-Version $version
    
        if ($v.Major -ge 4 -and $bitness -eq 'x86') {
            $packageUrl = "http://nodejs.org/dist/v$version/node-v$version-x86.msi"
        } elseif ($v.Major -ge 4 -and $bitness -eq 'x64') {
            $packageUrl = "http://nodejs.org/dist/v$version/node-v$version-x64.msi"
        } elseif ($v.Major -eq 0 -and $v.Minor -gt 6 -and $bitness -eq 'x86') {
            $packageUrl = "http://nodejs.org/dist/v$version/node-v$version-x86.msi"
        } elseif ($v.Major -eq 0 -and $v.Minor -le 6 -and $bitness -eq 'x86') {
            $packageUrl = "http://nodejs.org/dist/v$version/node.msi"
        } elseif ($v.Major -ge 1 -and $bitness -eq 'x86') {
            $packageUrl = "https://iojs.org/dist/v$version/iojs-v$version-x86.msi"
        } elseif ($v.Major -eq 0 -and $v.Minor -gt 6) {
            $packageUrl = "http://nodejs.org/dist/v$version/x64/node-v$version-x64.msi"
        } elseif ($v.Major -eq 0 -and $v.Minor -le 6) {
            $packageUrl = "http://nodejs.org/dist/v$version/x64/node.msi"
        } elseif ($v.Major -ge 1) {
            $packageUrl = "https://iojs.org/dist/v$version/iojs-v$version-x64.msi"
        }

        Write-Host "Downloading package from $packageUrl"
    
        $packageFileName = Join-Path ([IO.Path]::GetTempPath()) $packageUrl.Substring($packageUrl.LastIndexOf('/') + 1)
        (New-Object Net.WebClient).DownloadFile($packageUrl, $packageFileName)
        return $packageFileName
    }

    function Start-NodeJsInstallation {
        param
        (
	        [Parameter(Mandatory=$true)]
            [string]$version,

            [Parameter(Mandatory=$false)]
            [string]$bitness = 'x86'
        )

        $v = Get-Version $version

        Write-Host "Installing $(ProductName($version)) v$version ($bitness)..."
        $packageFileName = Get-NodeJsInstallPackage $version $bitness
        cmd /c start /wait msiexec /i "$packageFileName" /q
        del $packageFileName
    }

    function GetUninstallString($productName) {
        $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
        $uninstallString = ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
           | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
           | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
           | Select UninstallString).UninstallString

        if($uninstallString) {
            return $uninstallString.replace('MsiExec.exe /I{', '/x{').replace('MsiExec.exe /X{', '/x{')
        } else {
            return $uninstallString
        }
    }

    for($i = 0; $i -lt $nodeVersions.Length; $i++) {
        for($j = 0; $j -lt $nodePlatforms.Length; $j++) {
            $nodeVersion = $nodeVersions[$i]
            $nodePlatform = $nodePlatforms[$j]
            $nodeName = ProductName $nodeVersion

            # is it the last install?
            $lastOne = ($i -eq ($nodeVersions.Length - 1) -and $j -eq ($nodePlatforms.Length - 1))

            Write-Host "Installing $nodeName $nodeVersion $nodePlatform..." -ForegroundColor Cyan

            $avvmDir = "$avvmRoot\$nodeVersion\$nodePlatform"
            $installDir = ProductInstallDirectory $nodeVersion $nodePlatform
            $dirName = [IO.Path]::GetFileName($installDir)

            if(Test-Path "$avvmDir\$dirName") {
                Write-Host "$nodeName $nodeVersion $nodePlatform already installed" -ForegroundColor Gray
                continue
            }

            # create avvm dir
            Write-Host "Creating directory $avvmDir..."
            New-Item $avvmDir -ItemType Directory -Force | Out-Null

            # uninstall current node.js or io.js
            $uninstallCommand = (GetUninstallString $nodeName)
            if($uninstallCommand) {
                Write-Host "Uninstalling $nodeName..."
                cmd /c start /wait msiexec.exe $uninstallCommand /quiet   
            }

            # download required package
            Start-NodeJsInstallation $nodeVersion $nodePlatform

            if(-not $lastOne) {
                # copy
                Write-Host "Copying $installDir to $avvmDir\$dirName..."
                Copy-Item $installDir -Destination "$avvmDir\$dirName" -Recurse
            } else {
                # mark last version as active
                $registryKey = "HKLM:\SOFTWARE\Appveyor\VersionManager\node"
                New-Item $registryKey -Force | Out-Null
                Set-ItemProperty -Path $registryKey -Name "Version" -Value $nodeVersion
                Set-ItemProperty -Path $registryKey -Name "Platform" -Value $nodePlatform
            }

            # adding helper files
            [IO.File]::WriteAllText("$avvmDir\files.ps1", $fileTemplates["$($dirName)_$($nodePlatform)"]["files_ps1"])
            [IO.File]::WriteAllText("$avvmDir\install.ps1", $fileTemplates["$($dirName)_$($nodePlatform)"]["install_ps1"])
            [IO.File]::WriteAllText("$avvmDir\uninstall.ps1", $fileTemplates["$($dirName)_$($nodePlatform)"]["uninstall_ps1"])
            [IO.File]::WriteAllText("$avvmDir\install.reg", $fileTemplates["$($dirName)_$($nodePlatform)"]["install_reg"].replace('{version}', $nodeVersion))

            # fix node.exe alias for io.js
            $avvmIoJsPath = Join-Path $avvmDir "iojs"

            if(Test-Path $avvmIoJsPath) {
                    
                Remove-Item "$avvmIoJsPath\node.exe" -Force

'@IF EXIST "%~dp0\iojs.exe" ( 
    "%~dp0\iojs.exe" %* 
) ELSE ( 
    iojs %* 
)' | Out-File "$avvmIoJsPath\node.cmd" -Encoding ascii
            }

            Write-Host "$nodeName $nodeVersion $nodePlatform installed" -ForegroundColor Green
        }
    }
}

Install-Nodejs

Add-Path "${env:ProgramFiles(x86)}\nodejs"
Add-Path "$env:ProgramFiles\nodejs"
Add-Path "${env:ProgramFiles(x86)}\iojs"
Add-Path "$env:ProgramFiles\iojs"
Add-Path "$env:APPDATA\npm"

# set AVVM URL
[System.Environment]::SetEnvironmentVariable("AVVM_DOWNLOAD_URL", "https://appveyordownloads.blob.core.windows.net/avvm", "Machine")