$n = 'HKLM:\SOFTWARE\AppVeyor\Build Agent'
if (-not (test-path $n)) {
    $n = 'HKLM:\SOFTWARE\AppVeyor\BuildAgent'
    if (-not (test-path $n)) {
        $build_agent_mode = 'Azure'
        $appveyor_user = 'appveyor'
        $appveyor_password = [Guid]::NewGuid().ToString('B')
        iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/appveyor/build-images/053e8069cca8be0d9b5b8c2b06d75ce2b497da4e/scripts/Windows/bootstrap/windows-bootstrap.ps1'))
        return
    }
}
set-itemproperty -path $n -name AppVeyorUrl -value $appveyor_url
set-itemproperty -path $n -name WorkerId -value $appveyor_workerId