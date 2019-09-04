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

    function exitScript {
        # some cleanup?
        #exit 1
    }

    $ErrorActionPreference = "Stop"

    $StopWatch = New-Object System.Diagnostics.Stopwatch
    $StopWatch.Start()

    #Sanitize input
    $AppVeyorUrl = $AppVeyorUrl.TrimEnd("/")

    #Validate input
    if ($ApiToken -like "v2.*") {
        Write-Warning "Please select the API Key for specific account (not 'All Accounts') at '$($AppVeyorUrl)/api-keys'"
        exitScript
    }

    try {
        $responce = Invoke-WebRequest -Uri $AppVeyorUrl -ErrorAction SilentlyContinue
        if ($responce.StatusCode -ne 200) {
            Write-warning "AppVeyor URL '$($AppVeyorUrl)' responded with code $($responce.StatusCode)"
            exitScript
        }
    }
    catch {
        Write-warning "Unable to connect to AppVeyor URL '$($AppVeyorUrl)'. Error: $($error[0].Exception.Message)"
        exitScript
    }

    $headers = @{
      "Authorization" = "Bearer $ApiToken"
      "Content-type" = "application/json"
    }
    try {
        Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/projects" -Headers $headers -Method Get | Out-Null
    }
    catch {
        Write-warning "Unable to call AppVeyor REST API, please verify 'ApiToken' and ensure '-AppVeyorUrl' parameter is set if you are using on-premise AppVeyor Server."
        exitScript
    }

    if ($AppVeyorUrl -eq "https://ci.appveyor.com") {
          try {
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds" -Headers $headers -Method Get | Out-Null
        }
        catch {
            Write-warning "Please contact support@appveyor.com and request enabling of 'Private build clouds' feature."
            exitScript
        }
    }

    try {
        
        Write-Host "Connecting to Docker...done!"
    }

    catch {
        Write-Warning "Command exited with error: $($_.Exception)"
        exitScript
    }
}




