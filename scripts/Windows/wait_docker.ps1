Write-Host "Checking if docker peparation finished..." 
$i = 0
$finished = $false

while ($i -lt (300)) {
  $i +=1  
  $finished = Test-Path $env:SystemDrive\prepare-docker-finished.txt
  if ($finished) {
    Remove-Item -Path $env:SystemDrive\prepare-docker-finished.txt
    Remove-Item -Path "$env:ProgramFiles\AppVeyor\prepare-docker.ps1"
    Write-Host "`nDocker peparation finished OK"
    break
  }
  Write-warning "Retrying in 30 seconds..."
  sleep 30;
}

if (-not $finished) {
	Throw "Docker peparation was not finished"    
}