$rabbitVersion = '3.7.12'

Write-Host "Installing RabbitMQ $rabbitVersion..." -ForegroundColor Cyan

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Downloading..."
$exePath = "$env:TEMP\rabbitmq-server-$rabbitVersion.exe"
(New-Object Net.WebClient).DownloadFile("https://github.com/rabbitmq/rabbitmq-server/releases/download/v$rabbitVersion/rabbitmq-server-$rabbitVersion.exe", $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /S

$rabbitPath = "C:\Program Files\RabbitMQ Server\rabbitmq_server-$rabbitVersion"

Write-Host "Installing service..."
Start-Process -Wait "$rabbitPath\sbin\rabbitmq-service.bat" "install"

Write-Host "Starting service..."
Start-Process -Wait "$rabbitPath\sbin\rabbitmq-service.bat" "start"

Get-Service "RabbitMQ"

Write-Host "RabbitMQ installed and started" -ForegroundColor Green

Write-Host "Installing RabbitMQ plugins..." -ForegroundColor Cyan

Write-Host "Downloading..."
$zipPath = "$env:TEMP\rabbitmq_delayed_message_exchange-20171201-3.7.x.zip"
$pluginPath = "C:\Program Files\RabbitMQ Server\rabbitmq_server-$rabbitVersion\plugins"
(New-Object Net.WebClient).DownloadFile('https://bintray.com/rabbitmq/community-plugins/download_file?file_path=3.7.x%2Frabbitmq_delayed_message_exchange%2Frabbitmq_delayed_message_exchange-20171201-3.7.x.zip', $zipPath)
7z x $zipPath -y -o"$pluginPath" | Out-Null

Write-Host "Installing..."
& "C:\Program Files\RabbitMQ Server\rabbitmq_server-$rabbitVersion\sbin\rabbitmq-plugins.bat" enable rabbitmq_delayed_message_exchange
& "C:\Program Files\RabbitMQ Server\rabbitmq_server-$rabbitVersion\sbin\rabbitmq-plugins.bat" enable rabbitmq_management

# Management URL: http://127.0.0.1:15672/
# Username/password: guest/guest

Write-Host "RabbitMQ plugins installed and started" -ForegroundColor Green