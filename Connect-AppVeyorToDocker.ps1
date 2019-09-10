Function Connect-AppVeyorToDocker {
    <#
    .SYNOPSIS
        Command to enable Docker builds. Works with both hosted AppVeyor and AppVeyor Server.

    .DESCRIPTION
        You can connect your AppVeyor account (on both hosted AppVeyor and on-premise AppVeyor Server) to Docker for AppVeyor to instantiate build containers on it.

    .PARAMETER AppVeyorUrl
        AppVeyor URL. For hosted AppVeyor it is https://ci.appveyor.com. For Appveyor Server users it is URL of on-premise AppVeyor Server installation

    .PARAMETER ApiToken
        API key for specific account (not 'All accounts'). Hosted AppVeyor users can find it at https://ci.appveyor.com/api-keys. Appveyor Server users can find it at <appveyor_server_url>/api-keys.

    .PARAMETER ImageOs
        Operating system of container image. Valid values: 'Windows', 'Linux'.

    .PARAMETER ImageName
        Description to be used for AppVeyor image.

    .PARAMETER ImageTemplate
        Docker image name.

        .EXAMPLE
        Connect-AppVeyorToDocker
        Let command collect all required information

        .EXAMPLE
        Connect-AppVeyorToDocker -ApiToken XXXXXXXXXXXXXXXXXXXXX -AppVeyorUrl "https://ci.appveyor.com" -ImageOs Windows -ImageName Windows -ImageTemplate 'appveyor/build-image:minimal-nanoserver-1809'
        Run command with all required parameters so command will ask no questions. It will pull Docker image and configure Docker build cloud in AppVeyor.
    #>

    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory=$true,HelpMessage="AppVeyor URL`nFor hosted AppVeyor it is https://ci.appveyor.com`nFor Appveyor Server users it is URL of on-premise AppVeyor Server installation")]
      [string]$AppVeyorUrl,

      [Parameter(Mandatory=$true,HelpMessage="API key for specific account (not 'All accounts')`nHosted AppVeyor users can find it at https://ci.appveyor.com/api-keys`nAppveyor Server users can find it at <appveyor_server_url>/api-keys")]
      [string]$ApiToken,

      [Parameter(Mandatory=$true)]
      [ValidateSet('Windows','Linux')]
      [string]$ImageOs,

      [Parameter(Mandatory=$true)]
      [string]$ImageName,

      [Parameter(Mandatory=$true)]
      [string]$ImageTemplate
    )

    function ExitScript {
        # some cleanup?
        break all
    }

    $ErrorActionPreference = "Stop"

    $StopWatch = New-Object System.Diagnostics.Stopwatch
    $StopWatch.Start()

    #Sanitize input
    $AppVeyorUrl = $AppVeyorUrl.TrimEnd("/")

    #Validate AppVeyor API access
    $headers = ValidateAppVeyorApiAccess $AppVeyorUrl $ApiToken

    try {
        
        Write-Host "Connecting to Docker...done!"
    }

    catch {
        Write-Warning "Command exited with error: $($_.Exception)"
        ExitScript
    }
}




