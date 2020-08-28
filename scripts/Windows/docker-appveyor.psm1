function Switch-DockerLinux
{
    Remove-SmbShare -Name C -ErrorAction SilentlyContinue -Force
    $deUsername = 'DockerExchange'
    $dePsw = "ABC" + [guid]::NewGuid().ToString() + "!"
    $secDePsw = ConvertTo-SecureString $dePsw -AsPlainText -Force
    Get-LocalUser -Name $deUsername | Set-LocalUser -Password $secDePsw
    & $env:ProgramFiles\Docker\Docker\DockerCli.exe -Start --testftw!928374kasljf039 >$null 2>&1
    & $env:ProgramFiles\Docker\Docker\DockerCli.exe -Mount=C -Username="$env:computername\$deUsername" -Password="$dePsw" --testftw!928374kasljf039 >$null 2>&1
    Disable-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Direction Inbound
    New-SmbShare -Name C -Path "$env:systemdrive\" -ChangeAccess "$env:computername\$deUsername" | Out-Null
    & "$env:ProgramFiles\Docker\Docker\DockerCli.exe" -SwitchLinuxEngine
}

function Switch-DockerWindows
{
    & "$env:ProgramFiles\Docker\Docker\DockerCli.exe" -SwitchWindowsEngine
}

# export module members
Export-ModuleMember -Function Switch-DockerLinux,Switch-DockerWindows