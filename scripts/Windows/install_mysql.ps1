$mySqlPath = 'C:\MySQL57'

Write-Host "Downloading MySQL..."
$zipPath = "$env:USERPROFILE\mysql-5.7.9-win32.zip"
(New-Object Net.WebClient).DownloadFile('https://cdn.mysql.com/Downloads/MySQL-5.7/mysql-5.7.9-win32.zip', $zipPath)

Write-Host "Unpacking MySQL..."
7z x $zipPath -o"$mySqlPath" | Out-Null
del $zipPath

Write-Host "Installing MySQL..."
cmd /c start /wait "$mySqlPath\mysql-5.7.9-win32\bin\mysqld" --install
Start-Service "MySQL"