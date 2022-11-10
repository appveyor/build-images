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

function Start-ProcessWithOutput {
    param(
        $command,
        [switch]$ignoreExitCode,
        [switch]$ignoreStdOut
    )
    $fileName = $command
    $arguments = $null

    if ($command.startsWith('"')) {
        $idx = $command.indexOf('"', 1)
        $fileName = $command.substring(1, $idx - 1)
        if ($idx -lt ($command.length - 2)) {
            $arguments = $command.substring($idx + 2)
        }
    }
    else {
        $idx = $command.indexOf(' ')
        if ($idx -ne -1) {
            $fileName = $command.substring(0, $idx)
            $arguments = $command.substring($idx + 1)
        }
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
    $psi.WorkingDirectory = (pwd).Path
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    # Adding event handers for stdout and stderr.
    $outScripBlock = {
        if (![String]::IsNullOrEmpty($EventArgs.Data)) {
            Write-Host "$($EventArgs.Data)"
        }
    }
    $errScripBlock = {
        if (![String]::IsNullOrEmpty($EventArgs.Data)) {
            Write-Host "$($EventArgs.Data)" -ForegroundColor Red
        }
    }

    if ($ignoreStdOut -eq $false) {
        $stdOutEvent = Register-ObjectEvent -InputObject $process -Action $outScripBlock -EventName 'OutputDataReceived'
    }
    $stdErrEvent = Register-ObjectEvent -InputObject $process -Action $errScripBlock -EventName 'ErrorDataReceived'

    try {
        $process.Start() | Out-Null

        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        [Void]$process.WaitForExit()
    
        # Unregistering events to retrieve process output.
        if ($ignoreStdOut -eq $false) {
            Unregister-Event -SourceIdentifier $stdOutEvent.Name
        }
        Unregister-Event -SourceIdentifier $stdErrEvent.Name    
    
        if ($ignoreExitCode -eq $false -and $process.ExitCode -ne 0) {
            exit $process.ExitCode
        }
    }
    catch {
        Write-Host "Error running '$($psi.FileName) $($psi.Arguments)' command: $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
}