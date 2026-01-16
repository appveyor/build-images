. "$PSScriptRoot\common.ps1"

$mySqlRoot = "$($env:ProgramFiles)\MySQL"
$mySqlPath = "$mySqlRoot\MySQL Server 8.0"
$mySqlIniPath = "$mySqlPath\my.ini"
$mySqlDataPath = "$mySqlPath\data"
$mySqlTemp = "$($env:temp)\mysql_temp"
$mySqlServiceName = "MySQL80"
$mySqlRootPassword = 'Password12!'

Write-Host "Installing MySQL Server 8.0" -ForegroundColor Cyan

Write-Host "Downloading MySQL..."
$zipPath = "$($env:temp)\mysql-8.0.44-winx64.zip"
(New-Object Net.WebClient).DownloadFile('https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.44-winx64.zip', $zipPath)

Write-Host "Unpacking..."
New-Item $mySqlRoot -ItemType Directory -Force | Out-Null
7z x $zipPath -o"$mySqlTemp" | Out-Null
[IO.Directory]::Move("$mySqlTemp\mysql-8.0.44-winx64", $mySqlPath)
Remove-Item $mySqlTemp -Recurse -Force
Remove-Item $zipPath

Write-Host "Installing MySQL..."
New-Item $mySqlDataPath -ItemType Directory -Force | Out-Null

@"
[mysqld]
basedir=$($mySqlPath.Replace("\","\\"))
datadir=$($mySqlDataPath.Replace("\","\\"))
"@ | Out-File $mySqlIniPath -Force -Encoding ASCII

Write-Host "Initializing MySQL..."
Start-ProcessWithOutput "`"$mySqlPath\bin\mysqld`" --defaults-file=`"$mySqlIniPath`" --initialize-insecure"

Write-Host "Installing MySQL as a service..."
Start-ProcessWithOutput "`"$mySqlPath\bin\mysqld`" --install $mySqlServiceName"
Start-Service $mySqlServiceName
Set-Service -Name $mySqlServiceName -StartupType Manual

Write-Host "Setting root password..."
Start-ProcessWithOutput "`"$mySqlPath\bin\mysql`" -u root --skip-password -e `"ALTER USER 'root'@'localhost' IDENTIFIED BY '$mySqlRootPassword';`""

Write-Host "Verifying connection..."
Start-ProcessWithOutput "`"$mySqlPath\bin\mysql`" -u root --password=`"$mySqlRootPassword`" -e `"SHOW DATABASES;`""

Write-Host "MySQL Server installed" -ForegroundColor Green