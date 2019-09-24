Function Connect-AppVeyorToHyperV {
    <#
    .SYNOPSIS
        Command to enable Hyper-V builds. Works with both hosted AppVeyor and AppVeyor Server.

    .DESCRIPTION
        You can connect your AppVeyor account (on both hosted AppVeyor and on-premise AppVeyor Server) to Hyper-V host for AppVeyor to instantiate build VMs on it.

    .PARAMETER AppVeyorUrl
        AppVeyor URL. For hosted AppVeyor it is https://ci.appveyor.com. For Appveyor Server users it is URL of on-premise AppVeyor Server installation

    .PARAMETER ApiToken
        API key for specific account (not 'All accounts'). Hosted AppVeyor users can find it at https://ci.appveyor.com/api-keys. Appveyor Server users can find it at <appveyor_server_url>/api-keys.

    .PARAMETER ImageOs
        Operating system of build VM image. Valid values: 'Windows', 'Linux'. Default value is 'Windows'.

    .PARAMETER ImageName
        Description to be passed to Packer and name to be used for AppVeyor image.  Default value generated is based on the value of 'ImageOs' parameter.

    .PARAMETER ImageTemplate
        If you are familiar with the Hashicorp Packer, you can replace template used by this command with another one. Default value is '.\minimal-windows-server.json'.

        .EXAMPLE
        Connect-AppVeyorToHyperV
        Let command collect all required information

        .EXAMPLE
        Connect-AppVeyorToHyperV -ApiToken XXXXXXXXXXXXXXXXXXXXX -AppVeyorUrl "https://ci.appveyor.com"
        Run command with all required parameters so command will ask no questions. It will create build VM image and configure Hyper-V build cloud in AppVeyor.
    #>

    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory=$true,HelpMessage="AppVeyor URL`nFor hosted AppVeyor it is https://ci.appveyor.com`nFor Appveyor Server users it is URL of on-premise AppVeyor Server installation")]
      [string]$AppVeyorUrl,

      [Parameter(Mandatory=$true,HelpMessage="API key for specific account (not 'All accounts')`nHosted AppVeyor users can find it at https://ci.appveyor.com/api-keys`nAppveyor Server users can find it at <appveyor_server_url>/api-keys")]
      [string]$ApiToken,

      [Parameter(Mandatory=$false)]
      [string]$CpuCores = 2,

      [Parameter(Mandatory=$false)]
      [string]$RamMb = 4096,

      [Parameter(Mandatory=$false)]
      [string]$CommonPrefix = "appveyor",

      [Parameter(Mandatory=$false)]
      [ValidateSet('Windows','Linux')]
      [string]$ImageOs = "Windows",

      [Parameter(Mandatory=$false)]
      [string]$ImageName,

      [Parameter(Mandatory=$false)]
      [string]$ImageTemplate,

      [Parameter(Mandatory=$false)]
      [string]$ImageFeatures,

      [Parameter(Mandatory=$false)]
      [string]$ImageCustomScript,

      [Parameter(Mandatory=$false)]
      [string]$ImageCustomScriptAfterReboot,

      [Parameter(Mandatory=$false)]
      [string]$ImagesDirectory,

      [Parameter(Mandatory=$false)]
      [string]$VmsDirectory,

      [Parameter(Mandatory=$false)]
      [string]$DnsServers = "8.8.8.8; 8.8.4.4",

      [Parameter(Mandatory=$false)]
      [string]$SubnetMask = "255.255.255.0",

      [Parameter(Mandatory=$false)]
      [string]$PreheatedVMs = 2,

      [Parameter(Mandatory=$false)]
      [string]$VhdPath
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

    #Ensure required tools installed
    ValidateDependencies -cloudType HyperV

    $regex =[regex] "^([A-Za-z0-9]+)$"
    if (-not $regex.Match($CommonPrefix).Success) {
        Write-Warning "'CommonPrefix' can contain only letters and numbers"
        ExitScript
    }

    $ImageName = if ($ImageName) {$ImageName} else {$ImageOs}
    $ImageTemplate = GetImageTemplatePath $imageTemplate
    $ImageTemplate = ParseImageFeaturesAndCustomScripts $ImageFeatures $ImageTemplate $ImageCustomScript $ImageCustomScriptAfterReboot $ImageOs

    $install_user = "appveyor"
    $install_password = "appveyor" #CreatePassword

    $autounattendPath = Join-Path (Split-Path $ImageTemplate -Parent) "hyper-v\Windows\answer_files\2019\Autounattend.xml"
    [xml]$autounattend = Get-Content $autounattendPath
    $MicrosoftWindowsShellSetup = $autounattend.unattend.settings.component | ? {$_.name -eq "Microsoft-Windows-Shell-Setup"}
    $MicrosoftWindowsShellSetup.Autologon.password.Value = $install_password
    $MicrosoftWindowsShellSetup.UserAccounts.AdministratorPassword.Value = $install_password
    $MicrosoftWindowsShellSetup.UserAccounts.LocalAccounts.LocalAccount.Password.Value = $install_password
    $autounattend.Save($autounattendPath)

    #bake iso
    .\make_unattend_iso.ps1 -ParentFolder (Split-Path $ImageTemplate -Parent)

    $iso_checksum = if ($imageOs -eq "Windows") {"221F9ACBC727297A56674A0F1722B8AC7B6E840B4E1FFBDD538A9ED0DA823562"} elseif ($imageOs -eq "Linux") {"7d8e0055d663bffa27c1718685085626cb59346e7626ba3d3f476322271f573e"}
    $iso_checksum_type = "sha256"
    $iso_url = "https://software-download.microsoft.com/download/sg/17763.379.190312-0539.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
    $manually_download_iso_from = "https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019"

    if (-not $ImagesDirectory) {
        $ImagesDirectory = Join-Path $env:SystemDrive "$CommonPrefix-Images"
    }
    $output_directory = Join-Path $ImagesDirectory $(New-Guid)
    
    if (-not $VmsDirectory) {
        $VmsDirectory = Join-Path $env:SystemDrive "$CommonPrefix-VMs"
    }
    

    #TODO test IP and NAT
    #TODO scenario if subnet is occuped (to get existing subnets: gwmi -computer .  -class "win32_networkadapterconfiguration" | % {$_.ipsubnet})
    $natSwitch = "$CommonPrefix-NAT-Switch"
    $natNetwork = "$CommonPrefix-NAT-Network"
    $MasterIPAddress = "10.118.232.2"
    $SubnetMask = "255.255.255.0"
    $StartIPAddress = "10.118.232.100"
    $DefaultGateway = "10.118.232.1"
    $HttpPortMin = "9990"
    $HttpPortMax = "9999"
    $FirewalRuleName = "$CommonPrefix-packer-inbound"
    Write-host "`nGetting or creating virtual switch $natSwitch..." -ForegroundColor Cyan
    if (-not (Get-VMSwitch $natSwitch -ErrorAction Ignore)) {
        New-VMSwitch -SwitchName $natSwitch -SwitchType Internal
        New-NetIPAddress -IPAddress 10.118.232.1 -PrefixLength 24 -InterfaceAlias "vEthernet ($natSwitch)"
        New-NetNAT -Name $natNetwork -InternalIPInterfaceAddressPrefix 10.118.232.0/24
    }
    if ($imageOs -eq "Linux" -and (-not (Get-NetFirewallRule -Name $FirewalRuleName -ErrorAction Ignore))) {
         New-NetFirewallRule -Name $FirewalRuleName -DisplayName $FirewalRuleName -Enabled True -Direction Inbound -Action Allow -LocalAddress $DefaultGateway -RemoteAddress $MasterIPAddress -LocalPort "$HttpPortMin-$HttpPortMax" -Protocol TCP
    }

    try {

        #Run Packer to create an VHD
        if (-not $VhdPath) {
            $packerPath = GetPackerPath
            $packerManifest = "$(CreateTempFolder)/packer-manifest.json"
            Write-host "`nRunning Packer to create a basic build VM VHD..." -ForegroundColor Cyan
            Write-Warning "Add '-VhdPath' parameter with if you want to to skip Packer build and and reuse existing VHD."
            Write-Host "`n`nPacker progress:`n"
            $date_mark=Get-Date -UFormat "%Y%m%d%H%M%S"
            & $packerPath build '--only=hyperv-iso' `
            -var "install_password=$install_password" `
            -var "install_user=$install_user" `
            -var "build_agent_mode=HyperV" `
            -var "disk_size=61440" `
            -var "hyperv_switchname=$natSwitch" `
            -var "iso_checksum=$iso_checksum" `
            -var "iso_checksum_type=$iso_checksum_type" `
            -var "iso_url=$iso_url" `
            -var "output_directory=$output_directory" `
            -var "datemark=$date_mark" `
            -var "packer_manifest=$packerManifest" `
            -var "OPT_FEATURES=$ImageFeatures" `
            -var "host_ip_addr=$MasterIPAddress" `
            -var "host_ip_mask=$SubnetMask" `
            -var "host_ip_gw=$DefaultGateway" `
            -var "http_port_min=$HttpPortMin" `
            -var "http_port_max=$HttpPortMax" `
            $ImageTemplate

            #Get VHD path
            if (-not (test-path $packerManifest)) {
                Write-Warning "Packer build failed."
                ExitScript
            }
            Write-host "`nGetting VHD path..." -ForegroundColor Cyan
            $manifest = Get-Content -Path $packerManifest | ConvertFrom-Json
            $VhdPath = Join-Path (Join-Path $output_directory "Virtual Hard Disks") $(($manifest.builds[0].files | ? {$_.name -like "*.vhdx"}).name)
            Write-host "Build image VHD created by Packer. VHD path: '$($VhdPath)'" -ForegroundColor DarkGray
            Write-Host "Default build VM credentials: User: 'appveyor', Password: '$($install_password)'. Normally you do not need this password as it will be reset to a random string when the build starts. However you can use it if you need to create and update a VM from the Packer-created VHD manually"  -ForegroundColor DarkGray
        }
        else {
            Write-host "`nSkipping VHD creation with Packer..." -ForegroundColor Cyan
            Write-host "Using exiting VHD path '$($VhdPath)'" -ForegroundColor DarkGray
        }

        #Create or update cloud
        $build_cloud_name = $env:COMPUTERNAME
        $hostAuthorizationToken = [Guid]::NewGuid().ToString('N')

        $clouds = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds" -Headers $headers -Method Get
        $cloud = $clouds | ? ({$_.name -eq $build_cloud_name})[0]
        if (-not $cloud) {
            Write-host "`nCreating build environment on AppVeyor..." -ForegroundColor Cyan
            $body = @{
                name = $build_cloud_name
                cloudType = "HyperV"
                workersCapacity = 20
                hostAuthorizationToken = $hostAuthorizationToken
                settings = @{
                    artifactStorageName = $null
                    buildCacheName = $null
                    failureStrategy = @{
                        jobStartTimeoutSeconds = 300
                        provisioningAttempts = 3
                    }
                    cloudSettings = @{
                        vmConfiguration =@{
                            generation = "1"
                            cpuCores = [int]$($CpuCores)
                            ramMb = [int]$RamMb
                            directory = $VmsDirectory
                        }
                        networking = @{
                            useDHCP = $false
                            virtualSwitchName = $natSwitch
                            dnsServers = $DnsServers
                            subnetMask = $SubnetMask
                            startIPAddress = $StartIPAddress
                            defaultGateway = $DefaultGateway
                        }
                        provisioning = @{
                            preheatedVMs = $PreheatedVMs
                        }
                        images = @{
                            list = @(@{
                            isDefault = $true
                            name = $ImageName
                            vhdPath = $VhdPath
                            osType = $ImageOs
                            })
                        }
                    }
                }
            }

            $jsonBody = $body | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            $clouds = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds" -Headers $headers -Method Get
            $cloud = $clouds | ? ({$_.name -eq $build_cloud_name})[0]
            Write-host "AppVeyor build environment '$($build_cloud_name)' has been created." -ForegroundColor DarkGray
        }
        else {
            Write-Host "AppVeyor cloud '$build_cloud_name' already exists." -ForegroundColor DarkGray
            if ($cloud.CloudType -eq 'HyperV') {
                Write-Host "Updating image in the existing cloud..."
                $settings = Invoke-RestMethod -Uri "$AppVeyorUrl/api/build-clouds/$($cloud.buildCloudId)" -Headers $headers -Method Get
                if ($settings.settings.cloudSettings.images.list | ? {$_.name -eq $ImageName}) {
                    ($settings.settings.cloudSettings.images.list | ? {$_.name -eq $ImageName}).vhdPath = $VhdPath
                }
                else {
                    $new_image = @{
                        isDefault = $false
                        name = $ImageName
                        vhdPath = $VhdPath
                        osType = $ImageOs
                    }
                }
                $new_image = $new_image | ConvertTo-Json | ConvertFrom-Json
                $settings.settings.cloudSettings.images.list += $new_image

                $jsonBody = $settings | ConvertTo-Json -Depth 10
                Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds"-Headers $headers -Body $jsonBody -Method Put | Out-Null
                Write-host "AppVeyor build environment '$($build_cloud_name)' has been updated." -ForegroundColor DarkGray

                Write-Host "Using Host Agent authorization token from the existing cloud."
                $hostAuthorizationToken = $settings.hostAuthorizationToken
            }
            else {
                throw "Existing build cloud '$build_cloud_name' is not of 'HyperV' type."
            }
        }

        SetBuildWorkerImage $headers $ImageName $ImageOs

        # Install Host Agent
        InstallAppVeyorHostAgent $AppVeyorUrl $hostAuthorizationToken

        $StopWatch.Stop()
        $completed = "{0:hh}:{0:mm}:{0:ss}" -f $StopWatch.elapsed
        Write-Host "`nThe script successfully completed in $completed." -ForegroundColor Green

        #Report results and next steps
        PrintSummary 'this Hyper-V machine VMs' $AppVeyorUrl $cloud.buildCloudId $build_cloud_name $imageName
    }

    catch {
        Write-Warning "Command exited with error: $($_.Exception)"
        ExitScript
    }
}




