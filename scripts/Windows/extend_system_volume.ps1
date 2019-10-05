Write-Host "Extending system volume"

function DiskInfo() {
    foreach($disk in (Get-WmiObject -Class Win32_logicaldisk))
    {
        Write-Host "$($disk.DeviceID), $([int]($disk.Size/1024/1024/1024)) GB total, $([int]($disk.FreeSpace/1024/1024/1024)) GB free"
    }
}

DiskInfo

# extend system volume

$diskPartScript = @"
list disk
select disk 0
list volume
select disk 1
list volume
select disk 0
select volume 1 
extend
"@

$diskPartScriptPath = [IO.Path]::GetTempFileName()
[IO.File]::WriteAllText($diskPartScriptPath, $diskPartScript)

diskpart /s $diskPartScriptPath
Remove-Item -Path $diskPartScriptPath -ErrorAction Ignore

DiskInfo

Write-Host "System volume extended`n" -ForegroundColor Green