Write-Host "Extending system volume"

function DiskInfo() {
    foreach($disk in (Get-WmiObject -Class Win32_logicaldisk))
    {
        Write-Host "$($disk.DeviceID), $([int]($disk.Size/1024/1024/1024)) GB total, $([int]($disk.FreeSpace/1024/1024/1024)) GB free"
    }
}

DiskInfo

# find volume to extend
$diskPartScriptPath = [IO.Path]::GetTempFileName()
[IO.File]::WriteAllText($diskPartScriptPath, @"
list volume
"@)

$startLine = 8
$volumes = (diskpart /s $diskPartScriptPath)

$volumeIndex = 0;
for($i = $startLine; $i -lt $volumes.Length; $i++) {
    Write-Host $volumes[$i]
    if ($volumes[$i].contains('Boot')) {
        $volumeIndex = $i - $startLine
    }
}

# extend volume
$diskPartScriptPath = [IO.Path]::GetTempFileName()
[IO.File]::WriteAllText($diskPartScriptPath, @"
select volume $volumeIndex
extend
"@)

diskpart /s $diskPartScriptPath

DiskInfo

Remove-Item -Path $diskPartScriptPath -ErrorAction Ignore

Write-Host "System volume extended`n" -ForegroundColor Green