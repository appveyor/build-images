function DisplayDiskInfo() {
    Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName, 
    @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } }, 
    @{ Name = "Size (GB)" ; Expression = { "{0:N1}" -f ( $_.Size / 1gb) } }, 
    @{ Name = "FreeSpace (GB)" ; Expression = { "{0:N1}" -f ( $_.Freespace / 1gb ) } }, 
    @{ Name = "PercentFree" ; Expression = { "{0:P1}" -f ( $_.FreeSpace / $_.Size ) } } |
    Format-Table -AutoSize | Out-String
}

function GetProductVersion ($partialName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    $x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
    | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
    | Where-Object { $_.DisplayName -and $_.DisplayName.contains($partialName) } `
    | Sort-Object -Property DisplayName `
    | Select-Object -Property DisplayName, DisplayVersion `
    | Format-Table -AutoSize | Out-String
}

function RunProcess($command) {
    
    $Global:LASTEXITCODE = $null

    $fileName = $command
    $arguments = $null

    $idx = $command.indexOf(' ')
    if ($idx -ne -1) {
        $fileName = $command.substring(0, $idx)
        $arguments = $command.substring($idx + 1)
    }

    # find tool in path
    if (-not (Test-Path $fileName)) {
        foreach ($pathPart in $($env:PATH).Split(';')) {
            $searchPath = [IO.Path]::Combine($pathPart, "$fileName.bat")
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }            
            $searchPath = [IO.Path]::Combine($pathPart, "$fileName.cmd")
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
            $searchPath = [IO.Path]::Combine($pathPart, "$fileName.exe")
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
            $searchPath = [IO.Path]::Combine($pathPart, $fileName)
            if (Test-Path $searchPath) {
                $fileName = $searchPath; break;
            }
        }
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo 
    $psi.FileName = $fileName
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardOutput = $true
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.Arguments = $arguments
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null

    do {
        if (!$process.StandardOutput.EndOfStream) {
            Write-Host "$($process.StandardOutput.ReadLine())"
        }
        if (!$process.StandardError.EndOfStream) {
            Write-Host "STDERR: $($process.StandardError.ReadLine())"
        }
        Start-Sleep -Milliseconds 10
    } while (!$process.HasExited)

    # read remainder
    if (!$process.StandardOutput.EndOfStream) {
        Write-Host "$($process.StandardOutput.ReadLine())"
    }
    if (!$process.StandardError.EndOfStream) {
        Write-Host "STDERR: $($process.StandardError.ReadLine())"
    }

    if ($process.ExitCode -ne 0) {
        "ExitCode _: $($process.ExitCode)"
        exit $process.ExitCode
    }
}