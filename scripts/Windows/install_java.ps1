function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
        | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
        | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
        | Select UninstallString).UninstallString
}

function UninstallJava ($name) {
    $uninstallCommand = (GetUninstallString $name)
    if($uninstallCommand) {
        Write-Host "Uninstalling $name"

        $uninstallCommand = $uninstallCommand.replace('MsiExec.exe /I{', '/x{').replace('MsiExec.exe /X{', '/x{')
        cmd /c start /wait msiexec.exe $uninstallCommand /quiet

        Write-Host "Uninstalled $name" -ForegroundColor Green
    }
}

function InstallJDKVersion($javaVersion, $jdkVersion, $url, $fileName, $jdkPath, $jrePath) {
    Write-Host "Installing $javaVersion..." -ForegroundColor Cyan

    # download
    Write-Host "Downloading installer"
    $exePath = "$env:TEMP\$fileName"
    $logPath = "$env:TEMP\$fileName-install.log"
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    $client = New-Object Net.WebClient
    $client.Headers.Add('Cookie', 'gpw_e24=http://www.oracle.com; oraclelicense=accept-securebackup-cookie')
    $client.DownloadFile($url, $exePath)

    # install
    Write-Host "Installing JDK to $jdkPath"
    Write-Host "Installing JRE to $jrePath"

    if($jdkVersion -eq 6) {
        $arguments = "/c start /wait $exePath /s ADDLOCAL=`"ToolsFeature,PublicjreFeature`" INSTALLDIR=`"\`"$jdkPath\`"`""
    } elseif ($jdkVersion -eq 7) {
        $arguments = "/c start /wait $exePath /s ADDLOCAL=`"ToolsFeature,PublicjreFeature`" /INSTALLDIR=`"$jdkPath`" /INSTALLDIRPUBJRE=`"\`"$jrePath\`"`""
    } else {
        $arguments = "/c start /wait $exePath /s ADDLOCAL=`"ToolsFeature,PublicjreFeature`" INSTALLDIR=`"$jdkPath`" /INSTALLDIRPUBJRE=`"$jrePath`""
    }
    $proc = [Diagnostics.Process]::Start("cmd.exe", $arguments)
    $proc.WaitForExit()

    # cleanup
    Remove-Item $exePath -ErrorAction SilentlyContinue
    Write-Host "$javaVersion installed" -ForegroundColor Green
}

$java6 = (GetUninstallString 'Java(TM) 6 Update 45')
if($java6) {
    Write-Host "Latest Java 6 already installed" -ForegroundColor Green
} else {
    InstallJDKVersion "JDK 1.6 x86" 6 "http://download.oracle.com/otn-pub/java/jdk/6u45-b06/jdk-6u45-windows-i586.exe" "jdk-6u45-windows-i586.exe" "${env:ProgramFiles(x86)}\Java\jdk1.6.0" "${env:ProgramFiles(x86)}\Java\jre6"
    InstallJDKVersion "JDK 1.6 x64" 6 "http://download.oracle.com/otn-pub/java/jdk/6u45-b06/jdk-6u45-windows-x64.exe" "jdk-6u45-windows-x64.exe" "$env:ProgramFiles\Java\jdk1.6.0" "$env:ProgramFiles\Java\jre6"
}

$java7 = (GetUninstallString 'Java SE Development Kit 7 Update 80')
if($java7) {
    Write-Host "Latest Java 7 already installed" -ForegroundColor Green
} else {
    UninstallJava 'Java 7 Update 79 (64-bit)'
    UninstallJava 'Java 7 Update 79'
    UninstallJava 'Java SE Development Kit 7 Update 79'
    UninstallJava 'Java SE Development Kit 7 Update 79 (64-bit)'

    InstallJDKVersion "JDK 1.7 x86" 7 "https://storage.googleapis.com/appveyor-download-cache/jdk/jdk-7u80-windows-i586.exe" "jdk-7u80-windows-i586.exe" "${env:ProgramFiles(x86)}\Java\jdk1.7.0" "${env:ProgramFiles(x86)}\Java\jre7"
    InstallJDKVersion "JDK 1.7 x64" 7 "https://storage.googleapis.com/appveyor-download-cache/jdk/jdk-7u80-windows-x64.exe" "jdk-7u80-windows-x64.exe" "$env:ProgramFiles\Java\jdk1.7.0" "$env:ProgramFiles\Java\jre7"
}

$java8 = (GetUninstallString 'Java SE Development Kit 8 Update 162')
if($java8) {
    Write-Host "Latest Java 8 already installed" -ForegroundColor Green
} else {

    # uninstall current Java versions
    UninstallJava 'Java SE Development Kit 8 Update 152'
    UninstallJava 'Java SE Development Kit 8 Update 152 (64-bit)'
    UninstallJava 'Java 8 Update 152'
    UninstallJava 'Java 8 Update 152 (64-bit)'

    InstallJDKVersion "JDK 1.8 x86" 8 "http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-windows-i586.exe" "jdk-8u162-windows-i586.exe" "${env:ProgramFiles(x86)}\Java\jdk1.8.0" "${env:ProgramFiles(x86)}\Java\jre8"
    InstallJDKVersion "JDK 1.8 x64" 8 "http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-windows-x64.exe" "jdk-8u162-windows-x64.exe" "$env:ProgramFiles\Java\jdk1.8.0" "$env:ProgramFiles\Java\jre8"
}

$java9 = (GetUninstallString 'Java 9.0.4 (64-bit)')
if($java9) {
    Write-Host "Latest Java 9 already installed" -ForegroundColor Green
} else {

    # uninstall current Java versions
    UninstallJava 'Java 9.0.1 (64-bit)'
    UninstallJava 'Java(TM) SE Development Kit 9.0.1 (64-bit)'

    InstallJDKVersion "JDK 1.9 x64" 9 "http://download.oracle.com/otn-pub/java/jdk/9.0.4+11/c2514751926b4512b076cc82f959763f/jdk-9.0.4_windows-x64_bin.exe" "jdk-9.0.4_windows-x64_bin.exe" "$env:ProgramFiles\Java\jdk9" "$env:ProgramFiles\Java\jre9"
}

$java10 = (GetUninstallString 'Java 10.0.1 (64-bit)')
if($java10) {
    Write-Host "Latest Java 10 already installed" -ForegroundColor Green
} else {

    # uninstall current Java versions
    UninstallJava 'Java 10.0.1 (64-bit)'
    UninstallJava 'Java(TM) SE Development Kit 10.0.1 (64-bit)'

    InstallJDKVersion "JDK 1.10 x64" 10 "http://download.oracle.com/otn-pub/java/jdk/10.0.1+10/fb4372174a714e6b8c52526dc134031e/jdk-10.0.1_windows-x64_bin.exe" "jdk-10.0.1_windows-x64_bin.exe" "$env:ProgramFiles\Java\jdk10" "$env:ProgramFiles\Java\jre10"
}

# Disable Java updater
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run' -Name 'SunJavaUpdateSched'
Disable-ScheduledTask -TaskPath '\' -TaskName 'JavaUpdateSched'

# Set Java home
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Progra~1\Java\jdk1.8.0", "machine")
$env:JAVA_HOME="C:\Progra~1\Java\jdk1.8.0"

# Fix Java installs
Remove-Path "C:\ProgramData\Oracle\Java\javapath" -ErrorAction Ignore
Remove-Path "${env:ProgramFiles(x86)}\Common Files\Oracle\Java\javapath" -ErrorAction Ignore
Remove-Path "${env:ProgramFiles}\Java\jdk1.7.0\bin" -ErrorAction Ignore
Add-Path "${env:ProgramFiles}\Java\jdk1.8.0\bin"
Remove-Item "C:\Windows\System32\java.exe" -ErrorAction Ignore
Remove-Item "C:\Windows\System32\javaw.exe" -ErrorAction Ignore
Remove-Item "C:\Windows\SysWOW64\java.exe" -ErrorAction Ignore
Remove-Item "C:\Windows\SysWOW64\javaw.exe" -ErrorAction Ignore

# Remove Java 6 from Registry (to get rid of Xamarin/Android warning)
Remove-Item -Path 'hklm:\Software\JavaSoft\Java Development Kit\1.6' -Force
Remove-Item -Path 'hklm:\Software\Wow6432Node\JavaSoft\Java Development Kit\1.6' -Force