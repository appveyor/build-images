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

    .PARAMETER ImageFeatures
        Optional comma-separated list of image products/tools/libraries that should be installed on top of the base image.

    .PARAMETER ImageCustomScriptsUrl
        Optional URL to a repository or gist with custom scripts that should be run during image building.

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
      [string]$ImageTemplate,

      [Parameter(Mandatory=$false)]
      [string]$ImageFeatures,

      [Parameter(Mandatory=$false)]
      [string]$ImageCustomScriptsUrl      
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
        
        Write-Host "Configuring 'Docker' build cloud in AppVeyor" -ForegroundColor Cyan

        # make sure Docker is installed and available in the path
        if (-not (Get-Command docker -ErrorAction Ignore)) {
            Write-Warning "Looks like Docker is not installed. Please install Docker and re-run the command."
            return
        }

        $hostName = $env:COMPUTERNAME # Windows

        if ($isLinux) {
            # Linux
            $hostName = (hostname)
        } elseif ($isMacOS) {
            # macOS
            $hostName = (hostname)
        }

        $build_cloud_name = "$hostName Docker"
        $hostAuthorizationToken = [Guid]::NewGuid().ToString('N')

        $clouds = Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds" -Headers $headers -Method Get
        $cloud = $clouds | Where-Object ({$_.name -eq $build_cloud_name})[0]
        if (-not $cloud) {

            # check if there is a cloud already with the name "$build_cloud_name" and grab $hostAuthorizationToken from there
            $docker_build_cloud_name = "$build_cloud_name"
            $processCloud = $clouds | Where-Object ({$_.name -eq $docker_build_cloud_name})[0]

            if ($processCloud -and $processCloud.CloudType -eq 'Process') {
                Write-Host "There is an existing 'Process' cloud for that computer. Reading Host Agent authorization token from Process cloud." -ForegroundColor DarkGray
                $settings = Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds/$($processCloud.buildCloudId)" -Headers $headers -Method Get
                $hostAuthorizationToken = $settings.hostAuthorizationToken  
            }

            # Add new build cloud
            $body = @{
                cloudType = "Docker"
                name = $build_cloud_name
                hostAuthorizationToken = $hostAuthorizationToken
                workersCapacity = 20
                settings = @{
                    failureStrategy = @{
                        jobStartTimeoutSeconds = 60
                        provisioningAttempts = 2
                    }
                    cloudSettings = @{
                        general = @{
                        }
                        networking = @{
                        }                        
                        images = @(@{
                            name = $ImageName
                            dockerImageName = $ImageTemplate
                        })                        
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
            if ($cloud.CloudType -eq 'Docker') {
                Write-Host "Reading Host Agent authorization token from the existing cloud."
                $settings = Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds/$($cloud.buildCloudId)" -Headers $headers -Method Get
                $hostAuthorizationToken = $settings.hostAuthorizationToken
            } else {
                throw "Existing build cloud '$build_cloud_name' is not of 'Process' type."
            }
        }

        Write-host "`nEnsure build worker image is available for AppVeyor projects" -ForegroundColor Cyan
        $images = Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-worker-images" -Headers $headers -Method Get
        $image = $images | Where-Object ({$_.name -eq $ImageName})[0]
        if (-not $image) {
            $body = @{
                name = $imageName
                osType = $ImageOs
            }
    
            $jsonBody = $body | ConvertTo-Json
            Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-worker-images" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            Write-host "AppVeyor build worker image '$ImageName' has been created."
        } else {
            Write-host "AppVeyor build worker image '$ImageName' already exists." -ForegroundColor DarkGray
        }
    
        # Install Host Agent
        InstallAppVeyorHostAgent $AppVeyorUrl $hostAuthorizationToken

        $StopWatch.Stop()
        $completed = "{0:hh}:{0:mm}:{0:ss}" -f $StopWatch.elapsed
        Write-Host "`nCompleted in $completed."
    }
    catch {
        Write-Error $_
        ExitScript
    }
}