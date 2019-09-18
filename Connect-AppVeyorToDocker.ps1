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
      [string]$ImageCustomScript
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
        
        $hostName = $env:COMPUTERNAME # Windows

        if ($isLinux) {
            # Linux
            $hostName = (hostname)
        } elseif ($isMacOS) {
            # macOS
            $hostName = (hostname)
        }

        # make sure Docker is installed and available in the path
        Write-Host "`nEnsure Docker engine is installed and available in PATH" -ForegroundColor Cyan
        if (-not (Get-Command docker -ErrorAction Ignore)) {
            Write-Warning "Looks like Docker is not installed. Please install Docker and re-run the command."
            return
        } else {
            Write-Host "Docker is installed"
        }

        $isWindowsOs = (-not $isLinux -and -not $isMacOS)

        # ensure Docker experimental mode is enabled or Docker is in Linux mode if Linux image on Windows is selected
        if ($isWindowsOs -and $ImageOs -eq 'Linux') {
            Write-Host "`nChecking if Docker engine is in experimental or Linux mode to run Linux images on Windows" -ForegroundColor Cyan

            $dockerVersion = (docker version -f "{{json .}}") | ConvertFrom-Json
            if ($dockerVersion.Server.Os -ne 'linux' -and -not $dockerVersion.Server.Experimental) {
                Write-Warning "To configure Linux-based image on Windows platform the Docker should be either in experimental mode (with LCOW enabled) or switched into Linux mode (if it's Docker CE)."
                return
            } else {
                Write-Host "Docker engine is configured to run Linux images"
            }
        }        

        Write-Host "`nConfiguring 'Docker' build cloud in AppVeyor" -ForegroundColor Cyan

        $build_cloud_name = "$hostName Docker"
        $hostAuthorizationToken = [Guid]::NewGuid().ToString('N')

        $dockerImageTag = CreateSlug "appveyor-byoc-$ImageName"

        # base image name
        $baseImageName = $ImageTemplate
        $idx = $baseImageName.IndexOf(':')
        if ($idx -ne -1) {
            $baseImageName = $ImageTemplate.Substring(0, $idx)
        }

        $dockerImageName = "$dockerImageTag"

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
                            dockerImageName = $dockerImageName
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

                # check if the image already added
                $image = $settings.settings.cloudSettings.images | Where-Object ({$_.name -eq $ImageName})[0]

                if ($image) {
                    Write-host "Image '$ImageName' is already configured on cloud settings." -ForegroundColor DarkGray
                    $image.dockerImageName = $dockerImageName
                    Write-Host "Updating Docker image name to $dockerImageName"
                } else {
                    Write-host "Adding new '$ImageName' image to the cloud settings."
                    Write-Host "Docker image name is $dockerImageName"
                    $image = @{
                        'name' = $ImageName
                        'dockerImageName' = $dockerImageName
                    }
                    $image = $image | ConvertTo-Json | ConvertFrom-Json
                    $settings.settings.cloudSettings.images += $image
                }

                $jsonBody = $settings | ConvertTo-Json -Depth 10
                Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds"-Headers $headers -Body $jsonBody -Method Put | Out-Null
                Write-Host "Cloud settings updated."

            } else {
                throw "Existing build cloud '$build_cloud_name' is not of 'Process' type."
            }
        }

        # pull base Docker image and then build a new (optionally) and tag
        Write-Host "`nPulling base Docker image $ImageTemplate" -ForegroundColor Cyan
        docker pull $ImageTemplate

        # tag image
        if ($ImageFeatures -or $ImageCustomScript) {
            # build new image
            Write-Host "`nBuilding a new Docker image with custom features and/or script" -ForegroundColor Cyan
            $tmp = $env:TEMP
            if ($isMacOS -or $isLinux) {
                $tmp = "/tmp"
            }

            # create temp dir for Dockerfile
            $dockerTempPath = Join-Path -Path $tmp -ChildPath ([Guid]::NewGuid().ToString('N'))
            New-Item $dockerTempPath -Type Directory | Out-Null
            $dockerfilePath = Join-Path -Path $dockerTempPath -ChildPath 'Dockerfile'

            $dockerfile = @()
            $dockerfile += "FROM $ImageTemplate"
            
            if ($ImageOs -eq 'Linux') {

                # build Linux image
                if (-not $ImageTemplate.StartsWith('appveyor/build-image')) {
                    # full image
                    $scriptsPath = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'scripts') -ChildPath 'Ubuntu'
                    $destPath = Join-Path -Path (Join-Path -Path $dockerTempPath -ChildPath 'scripts') -ChildPath 'Ubuntu'

                    Copy-Item $scriptsPath $destPath -Recurse

                    if ($ImageFeatures) {
                        $dockerfile += "ENV OPT_FEATURES=$ImageFeatures"
                    }
                    $dockerfile += "ENV IS_DOCKER=true"
                    $dockerfile += "COPY ./scripts/Ubuntu ./scripts"
                    $dockerfile += "RUN chmod +x ./scripts/minimalconfig.sh && ./scripts/minimalconfig.sh"
                    $dockerfile += "USER appveyor"
                }

                if ($ImageCustomScript) {
                    $customScriptPath = Join-Path -Path $dockerTempPath -ChildPath 'script.sh'
                    $decodedScript = [Text.Encoding]::UTF8.GetString(([Convert]::FromBase64String($ImageCustomScript)))
                    [IO.File]::WriteAllText($customScriptPath, $decodedScript.Replace("`r`n", "`n"))
                    $dockerfile += "COPY ./script.sh ."
                    $dockerfile += "RUN chmod +x ./script.sh && ./script.sh"
                }

                $dockerfile += "ENTRYPOINT [ `"/opt/appveyor/build-agent/appveyor-build-agent`" ]"

            } else {

                # build Windows image
                if ($ImageCustomScript) {
                    $customScriptPath = Join-Path -Path $dockerTempPath -ChildPath 'script.ps1'
                    $decodedScript = [Text.Encoding]::UTF8.GetString(([Convert]::FromBase64String($ImageCustomScript)))
                    [IO.File]::WriteAllText($customScriptPath, "`$ErrorActionPreference = `"Stop`"`n$decodedScript")                    
                    $dockerfile += "COPY script.ps1 ."
                    $dockerfile += "RUN pwsh -noni -ep unrestricted .\script.ps1"
                }
            }

            # write and build Dockerfile
            [IO.File]::WriteAllLines($dockerfilePath, $dockerfile)

            docker build -t $dockerImageName -f $dockerfilePath $dockerTempPath

            Remove-Item $dockerTempPath -Force -Recurse

        } else {
            # just tag existing one
            Write-host "No custom image has been built - just tagging '$ImageTemplate' image as '$dockerImageName'" -ForegroundColor DarkGray
            docker tag $ImageTemplate $dockerImageName
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
        Write-Host "`nThe script successfully completed in $completed." -ForegroundColor Green

        #Report results and next steps
        PrintSummary 'Docker' $AppVeyorUrl $cloud.buildCloudId $build_cloud_name $imageName
    }
    catch {
        Write-Error $_
        ExitScript
    }
}