Function Connect-AppVeyorToComputer {
    <#
    .SYNOPSIS
        Command to enable AppVeyor builds running on a host directly. Works with both hosted AppVeyor and AppVeyor Server.

    .DESCRIPTION
        You can connect your AppVeyor account (on both hosted AppVeyor and on-premise AppVeyor Server) to computer running Windows, Linux or Mac for AppVeyor to instantiate builds directly on it.

    .PARAMETER AppVeyorUrl
        AppVeyor URL. For hosted AppVeyor it is https://ci.appveyor.com. For Appveyor Server users it is URL of on-premise AppVeyor Server installation

    .PARAMETER ApiToken
        API key for specific account (not 'All accounts'). Hosted AppVeyor users can find it at https://ci.appveyor.com/api-keys. Appveyor Server users can find it at <appveyor_server_url>/api-keys.

        .EXAMPLE
        Connect-AppVeyorToComputer
        Let command collect all required information

        .EXAMPLE
        Connect-AppVeyorToComputer -ApiToken XXXXXXXXXXXXXXXXXXXXX -AppVeyorUrl "https://ci.appveyor.com"
        Run command with all required parameters so command will ask no questions. It will install AppVeyor Host Agent and configure "Process" build cloud in AppVeyor.
    #>

    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory=$true,HelpMessage="AppVeyor URL`nFor hosted AppVeyor it is https://ci.appveyor.com`nFor Appveyor Server users it is URL of on-premise AppVeyor Server installation")]
      [string]$AppVeyorUrl,

      [Parameter(Mandatory=$true,HelpMessage="API key for specific account (not 'All accounts')`nHosted AppVeyor users can find it at https://ci.appveyor.com/api-keys`nAppveyor Server users can find it at <appveyor_server_url>/api-keys")]
      [string]$ApiToken
    )

    function exitScript {
        # some cleanup?
        exit 1
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
        
        Write-Host "Connecting to a host...done!"
    }

    catch {
        Write-Warning "Command exited with error: $($_.Exception)"
        exitScript
    }
}




