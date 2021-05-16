$rabbitVersion = '3.7.12'

Write-Host "Installing RabbitMQ $rabbitVersion..." -ForegroundColor Cyan

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Downloading..."
$exePath = "$env:TEMP\rabbitmq-server-$rabbitVersion.exe"
(New-Object Net.WebClient).DownloadFile("https://github.com/rabbitmq/rabbitmq-server/releases/download/v$rabbitVersion/rabbitmq-server-$rabbitVersion.exe", $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /S

$rabbitPath = "${env:ProgramFiles}\RabbitMQ Server\rabbitmq_server-$rabbitVersion"

Write-Host "Installing service..."
Start-Process -Wait "$rabbitPath\sbin\rabbitmq-service.bat" "install"

Write-Host "Starting service..."
Start-Process -Wait "$rabbitPath\sbin\rabbitmq-service.bat" "start"

Get-Service "RabbitMQ"

Write-Host "RabbitMQ installed and started" -ForegroundColor Green

Write-Host "Installing RabbitMQ plugins..." -ForegroundColor Cyan

Write-Host "Downloading..."
$pluginPath = "${env:ProgramFiles}\RabbitMQ Server\rabbitmq_server-$rabbitVersion\plugins\rabbitmq_delayed_message_exchange-3.8.0.ez"
(New-Object Net.WebClient).DownloadFile('https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v3.8.0/rabbitmq_delayed_message_exchange-3.8.0.ez', $pluginPath)

Write-Host "Installing..."
& "${env:ProgramFiles}\RabbitMQ Server\rabbitmq_server-$rabbitVersion\sbin\rabbitmq-plugins.bat" enable rabbitmq_delayed_message_exchange
& "${env:ProgramFiles}\RabbitMQ Server\rabbitmq_server-$rabbitVersion\sbin\rabbitmq-plugins.bat" enable rabbitmq_management

# Management URL: http://127.0.0.1:15672/
# Username/password: guest/guest

Write-Host "RabbitMQ plugins installed and started" -ForegroundColor Green