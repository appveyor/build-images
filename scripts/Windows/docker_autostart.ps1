# Specify the path to your JSON file
$dockerSettings = "C:\Users\appveyor\AppData\Roaming\Docker\settings.json"
$jsonContent = Get-Content -Path $dockerSettings | ConvertFrom-Json

$autoStart = "autoStart"
$jsonContent.$autoStart = $true

$jsonContent | ConvertTo-Json | Set-Content -Path $dockerSettings
