function Switch-DockerLinux
{
    $deUsername = 'DockerExchange'
    $dePsw = "ABC" + [guid]::NewGuid().ToString() + "!"
    $secDePsw = ConvertTo-SecureString $dePsw -AsPlainText -Force
    Get-LocalUser -Name $deUsername | Set-LocalUser -Password $secDePsw
    & $env:ProgramFiles\Docker\Docker\DockerCli.exe -Mount="$env:systemdrive\" -Username="$env:computername\$deUsername" -Password="$dePsw" --testftw!928374kasljf039 >$null 2>&1
    & "$env:ProgramFiles\Docker\Docker\DockerCli.exe" -SwitchLinuxEngine
    WaitForServer "linux"
}

function Switch-DockerWindows
{
    & "$env:ProgramFiles\Docker\Docker\DockerCli.exe" -SwitchWindowsEngine
    WaitForServer "windows"
}

function WaitForServer($expOs)
{
    for ($i = 0; $i -lt 50; $i++) {
        $os = (docker version --format "{{.Server.Os}}" 2>&1)
        if ($LASTEXITCODE -eq 0 -and $os -eq $expOs) {
            return
        } else {
            Start-Sleep -Seconds 5
        }
    }
}

# export module members
Export-ModuleMember -Function Switch-DockerLinux,Switch-DockerWindows