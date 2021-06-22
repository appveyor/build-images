Write-Host "Creating AppVeyor user"
Write-Host "======================"

function CreateUser {
    if ($env:appveyor_password) {
        # password specified
        cmd /c net user $env:appveyor_user $env:appveyor_password /add /passwordchg:no /passwordreq:yes /active:yes /Y
    } else {
        # random password
        cmd /c net user $env:appveyor_user /add /active:yes /Y
    }
}

CreateUser
$count = 0; 
while (-not (Get-LocalUser -Name $env:appveyor_user -ErrorAction Ignore) -and $count -lt 3) {
    CreateUser
    sleep 1; 
    $count++
}
if (-not (Get-LocalUser -Name $env:appveyor_user -ErrorAction Ignore)) {throw "unable to create user '$env:appveyor_user'"}

cmd /c net localgroup Administrators $env:appveyor_user /add
cmd /c 'winrm set winrm/config/service/auth @{Basic="true"}'

Set-LocalUser -Name $env:appveyor_user -PasswordNeverExpires:$false

Write-Host "User created"
