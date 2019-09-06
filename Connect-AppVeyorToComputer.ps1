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

    $APPVEYOR_HOST_AGENT_MSI_URL = "https://www.appveyor.com/downloads/appveyor/appveyor-host-agent.msi"
    $APPVEYOR_HOST_AGENT_DEB_URL = "https://www.appveyor.com/downloads/appveyor/appveyor-host-agent.deb"

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
        Write-Warning "Please select the API Key for specific account (not 'All Accounts') at '$AppVeyorUrl/api-keys'"
        exitScript
    }

    try {
        $responce = Invoke-WebRequest -Uri $AppVeyorUrl -ErrorAction SilentlyContinue
        if ($responce.StatusCode -ne 200) {
            Write-warning "AppVeyor URL '$AppVeyorUrl' responded with code $($responce.StatusCode)"
            exitScript
        }
    }
    catch {
        Write-warning "Unable to connect to AppVeyor URL '$AppVeyorUrl'. Error: $($error[0].Exception.Message)"
        exitScript
    }

    $headers = @{
      "Authorization" = "Bearer $ApiToken"
      "Content-type" = "application/json"
    }
    try {
        Invoke-RestMethod -Uri "$AppVeyorUrl/api/projects" -Headers $headers -Method Get | Out-Null
    }
    catch {
        Write-warning "Unable to call AppVeyor REST API, please verify 'ApiToken' and ensure '-AppVeyorUrl' parameter is set if you are using on-premise AppVeyor Server."
        exitScript
    }

    if ($AppVeyorUrl -eq "https://ci.appveyor.com") {
          try {
            Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds" -Headers $headers -Method Get | Out-Null
        }
        catch {
            Write-warning "Please contact support@appveyor.com and request enabling of 'Private build clouds' feature."
            exitScript
        }
    }

    try {
        
        Write-Host "Configuring 'Process' build cloud into AppVeyor" -ForegroundColor Cyan

        $hostName = $env:COMPUTERNAME # Windows
        $imageName = "Windows"
        $osType = "Windows"

        if ($isLinux) {
            # Linux
            $hostName = (hostname)
            $imageName = "Linux"
            $osType = "Linux"
        } elseif ($isMacOS) {
            # macOS
            $hostName = (hostname)
            $imageName = "macOS"
            $osType = "MacOS"
        }

        $build_cloud_name = "$hostName"
        $hostAuthorizationToken = [Guid]::NewGuid().ToString('N')

        $clouds = Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds" -Headers $headers -Method Get
        $cloud = $clouds | Where-Object ({$_.name -eq $build_cloud_name})[0]
        if (-not $cloud) {

            # check if there is a cloud already with the name "$build_cloud_name Docker" and grab $hostAuthorizationToken from there
            $docker_build_cloud_name = "$build_cloud_name Docker"
            $dockerCloud = $clouds | Where-Object ({$_.name -eq $docker_build_cloud_name})[0]

            if ($dockerCloud -and $dockerCloud.CloudType -eq 'Docker') {
                Write-Host "There is an existing 'Docker' cloud for that computer. Reading Host Agent authorization token from Docker cloud." -ForegroundColor DarkGray
                $settings = Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds/$($dockerCloud.buildCloudId)" -Headers $headers -Method Get
                $hostAuthorizationToken = $settings.hostAuthorizationToken  
            }

            # Add new build cloud
            $body = @{
                cloudType = "Process"
                name = $build_cloud_name
                hostAuthorizationToken = $hostAuthorizationToken
                workersCapacity = 20
                settings = @{
                    artifactStorageName = $azure_artifact_storage_name
                    buildCacheName = $azure_cache_storage_name
                    failureStrategy = @{
                        jobStartTimeoutSeconds = 60
                        provisioningAttempts = 2
                    }
                    cloudSettings = @{
                        general =@{
                        }
                    }
                }
            }
    
            $jsonBody = $body | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            $clouds = Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds" -Headers $headers -Method Get
            $cloud = $clouds | Where-Object ({$_.name -eq $build_cloud_name})[0]
            Write-Host "A new AppVeyor build cloud '$build_cloud_name' has been added."
        } else {
            Write-Host "AppVeyor cloud '$build_cloud_name' already exists." -ForegroundColor DarkGray
            if ($cloud.CloudType -eq 'Process') {
                Write-Host "Reading Host Agent authorization token from the existing cloud."
                $settings = Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds/$($cloud.buildCloudId)" -Headers $headers -Method Get
                $hostAuthorizationToken = $settings.hostAuthorizationToken
            } else {
                throw "Existing build cloud '$build_cloud_name' is not of 'Process' type."
            }
        }

        Write-host "`nProvisioning build worker image is available for AppVeyor projects" -ForegroundColor Cyan
        $images = Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-worker-images" -Headers $headers -Method Get
        $image = $images | Where-Object ({$_.name -eq $ImageName})[0]
        if (-not $image) {
            $body = @{
                name = $imageName
                osType = $osType
            }
    
            $jsonBody = $body | ConvertTo-Json
            Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-worker-images" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            Write-host "AppVeyor build worker image '$ImageName' has been created."
        } else {
            Write-host "AppVeyor build worker image '$ImageName' already exists." -ForegroundColor DarkGray
        }
    
        Write-Host "Installing AppVeyor Host Agent"

        if ($isLinux) {

            # Linux
            $hostName = (hostname)
            $imageName = "Linux"
            $osType = "Linux"
        } elseif ($isMacOS) {

            # macOS
            $hostName = (hostname)
            $imageName = "macOS"
            $osType = "MacOS"
        } else {

            # Windows
            $hostAgentService = Get-Service "Appveyor.HostAgent" -ErrorAction SilentlyContinue
            if (!$hostAgentService) {

                if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
                    throw "The script should be run in elevated mode to install Host Agent. Run PowerShell in elevated mode (Run as Administrator) and re-run original 'Connect-AppVeyorToComputer' command."
                }

                Write-Host "Downloading appveyor-host-agent.msi..." -ForegroundColor Gray
                $msiPath = "$env:temp\appveyor-host-agent.msi"
                (New-Object Net.WebClient).DownloadFile($APPVEYOR_HOST_AGENT_MSI_URL, $msiPath)
    
                Write-Host "Installing Host Agent..." -ForegroundColor Gray
                cmd /c msiexec /i $msiPath /quiet APPVEYOR_URL="$AppVeyorUrl" HOST_AUTHORIZATION_TOKEN="$hostAuthorizationToken"
    
                Remove-Item $msiPath
                $hostAgentService = Get-Service "Appveyor.HostAgent" -ErrorAction SilentlyContinue
                if ($hostAgentService) {
                    Write-Host "Host Agent has been installed"
                } else {
                    Write-Host "Something went wrong and Host Agent was not installed" -ForegroundColor Red
                    throw "Error installing Host Agent"
                }                
            } else {
                Write-Host "Host Agent is already installed"
            }
        }

        $StopWatch.Stop()
        $completed = "{0:hh}:{0:mm}:{0:ss}" -f $StopWatch.elapsed
        Write-Host "`nCompleted in $completed."
    }
    catch {
        Write-Error $_
        exitScript
    }
}




