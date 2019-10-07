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

    .PARAMETER SkipDisclaimer
        Skip warning related to computer configration changes. It is recommended to read the warning at least once, but it can come handy if you need to re-run the command.

    .PARAMETER CpuCores
        Number of CPU cores for build VMs.

    .PARAMETER RamMb
        Memory (in megabytes) for build VMs.

    .PARAMETER DiskSize
        Disk Size (in gigabytes) for build VMs.

    .PARAMETER ImagesDirectory
        Directory to keep build VM images.

    .PARAMETER VmsDirectory
        Directory to create build VMs.

    .PARAMETER PackerTempDirectory
        Temp directory for Packer VMs.

    .PARAMETER SubnetId
        AppVeyor will create Virtual switch and subnet to use with build VMs and manage build VMs IP configuration in that subnet. Default value is 10.118.232.0.

    .PARAMETER SubnetMask
        Subnet mask to be used with build VMs. Default value is 255.255.255.0.

    .PARAMETER MasterIPAddress
        IP address to be assigned to master VM created by Packer. Default value is 10.118.232.2.
        
    .PARAMETER DefaultGateway
        IP address to assign to Virtual Switch NIC, which will be default gateway for VMs. Default value is 10.118.232.1.
        
    .PARAMETER StartIPAddress
        Address from which AppVeyor will start assigning IPs to VMs. It is importand to ensure it is not conflicting with MasterIPAddress and DefaultGateway, but still in the same subnet (check SubnetMask parameter) and them.

    .PARAMETER DnsServers
        DNS server to assign to build VMs NIC.

    .PARAMETER VhdPath
        Path existing build VM VHD (in case you prefer to skip Packer build and use existing VHD).

    .PARAMETER CommonPrefix
        Command will prepend all created resources (like Hyper-V virtual swith or firewall rule) it creates and with it.

    .PARAMETER ImageOs
        Operating system of build VM image. Valid values: 'Windows', 'Linux'. Default value is 'Windows'.

    .PARAMETER UpdateWindows
        Update Windows before creating a master VHD.

    .PARAMETER IsoUrl
        ISO from which to install master VM. Can be URK, local and UNC path. Default it Windows Server 2019 Evaluation.

    .PARAMETER IsoChecksum
        SHA256 checksum of installation ISO file. Needed only if IsoUrl parameter specified.

    .PARAMETER ProductKey
        Enter your product key if you are using retail or volume license ISOs.

    .PARAMETER AVMAKey
        To benefit from Automatic virtual machine activation enter respective AVMA Key which can be found at https://docs.microsoft.com/en-us/windows-server/get-started-19/vm-activation-19#avma-keys. You still need retail or volume license ISO and ProductKey for initial installation to use AVMA.

    .PARAMETER ImageName
        Description to be passed to Packer and name to be used for AppVeyor image.  Default value generated is based on the value of 'ImageOs' parameter.

    .PARAMETER ImageTemplate
        If you are familiar with the Hashicorp Packer, you can replace template used by this command with another one. Default value is '.\minimal-windows-server.json'.

    .PARAMETER ImageFeatures
        Comma-separated list of feature IDs to be installed on the image. Available IDs can be found at https://github.com/appveyor/build-images/blob/master/byoc/image-builder-metadata.json under 'installedFeatures'.

    .PARAMETER ImageCustomScript
        Base-64 encoded text of custom sript to execute during image creation. It should not contain reboot instructions.

    .PARAMETER ImageCustomScriptAfterReboot
        Base-64 encoded text of custom sript to execute during image creation, after reboot. It is usefull for cases when custom software being installed with 'ImageCustomScript' required some additional action after computer restarted.

        .EXAMPLE
        Connect-AppVeyorToHyperV
        Let command collect all required information

        .EXAMPLE
        Connect-AppVeyorToHyperV -ApiToken XXXXXXXXXXXXXXXXXXXXX -AppVeyorUrl "https://ci.appveyor.com" -CpuCores 2 -RamMb 2048 -ImageOs "Windows"
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
      [switch]$SkipDisclaimer,

      [Parameter(Mandatory=$false)]
      [int]$CpuCores = 2,

      [Parameter(Mandatory=$false)]
      [int]$RamMb = 4096,

      [Parameter(Mandatory=$false)]
      [int]$DiskSize = 60,

      [Parameter(Mandatory=$false)]
      [string]$ImagesDirectory,

      [Parameter(Mandatory=$false)]
      [string]$VmsDirectory,

      [Parameter(Mandatory=$false)]
      [string]$PackerTempDirectory,      

      [Parameter(Mandatory=$false)]
      [string]$SubnetId = "10.118.232.0",

      [Parameter(Mandatory=$false)]
      [string]$SubnetMask = "255.255.255.0",

      [Parameter(Mandatory=$false)]
      [string]$MasterIPAddress = "10.118.232.2",

      [Parameter(Mandatory=$false)]
      [string]$DefaultGateway = "10.118.232.1",
      
      [Parameter(Mandatory=$false)]
      [string]$StartIPAddress = "10.118.232.100",

      [Parameter(Mandatory=$false)]
      [string]$DnsServers = "8.8.8.8; 8.8.4.4",

      [Parameter(Mandatory=$false)]
      [string]$PreheatedVMs = 2,

      [Parameter(Mandatory=$false)]
      [string]$VhdPath,

      [Parameter(Mandatory=$false)]
      [string]$CommonPrefix = "appveyor",

      [Parameter(Mandatory=$false)]
      [ValidateSet('Windows','Linux')]
      [string]$ImageOs = "Windows",

      [Parameter(Mandatory=$false)]
      [switch]$UpdateWindows,

      [Parameter(Mandatory=$false)]
      [string]$IsoUrl,

      [Parameter(Mandatory=$false)]
      [string]$IsoChecksum,

      [Parameter(Mandatory=$false)]
      [string]$ProductKey,

      [Parameter(Mandatory=$false)]
      [string]$AVMAKey,

      [Parameter(Mandatory=$false)]
      [string]$ImageName,

      [Parameter(Mandatory=$false)]
      [string]$ImageTemplate,

      [Parameter(Mandatory=$false)]
      [string]$ImageFeatures,

      [Parameter(Mandatory=$false)]
      [string]$ImageCustomScript,

      [Parameter(Mandatory=$false)]
      [string]$ImageCustomScriptAfterReboot
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

    if (-not $SkipDisclaimer) {
         Write-Warning "`nThis command will create Hyper-V resources such as virtual switch and related subnet and NAT. For Linux VMs it will also create a new firewall rule. Also, it will run Hashicorp Packer which will create its own temporary Hyper-V resources and leave VHD for future use by AppVeyor build VMs.`n`nIf this server contains production resources you might consider using separate one.`n`nPress Enter to continue or Ctrl-C to exit the command. Use '-SkipDisclaimer' switch parameter to skip this message next time."
         $disclaimer = Read-Host
    }

    $ImageName = if ($ImageName) {$ImageName} else {$ImageOs}
    $ImageTemplate = GetImageTemplatePath $imageTemplate
    $ImageTemplate = ParseImageFeaturesAndCustomScripts $ImageFeatures $ImageTemplate $ImageCustomScript $ImageCustomScriptAfterReboot $ImageOs

    $install_user = "appveyor"
    $install_password = CreatePassword

    #Temporary template parent folder
    $ParentFolder = Split-Path $ImageTemplate -Parent

    $MaskCidr = Convert-IpAddressToMaskLength $SubnetMask

    if ($imageOs -eq "Windows") {
        $autounattendPath = Join-Path $ParentFolder "hyper-v\Windows\answer_files\2019\Autounattend.xml"
        if ($UpdateWindows)
        {
            $autounattendWithUpdatePath = Join-Path $ParentFolder "hyper-v\Windows\answer_files\2019\Autounattend-withupdate.xml"
            Remove-Item $autounattendPath -force
            Copy $autounattendWithUpdatePath $autounattendPath
        }
        [xml]$autounattend = Get-Content $autounattendPath
        $MicrosoftWindowsShellSetup = $autounattend.unattend.settings.component | ? {$_.name -eq "Microsoft-Windows-Shell-Setup"}
        # set password to randomly generated
        $MicrosoftWindowsShellSetup.Autologon.password.Value = $install_password
        $MicrosoftWindowsShellSetup.UserAccounts.AdministratorPassword.Value = $install_password
        $MicrosoftWindowsShellSetup.UserAccounts.LocalAccounts.LocalAccount.Password.Value = $install_password

        # set up IP configuration
        ($MicrosoftWindowsShellSetup.FirstLogonCommands.SynchronousCommand | ? {$_.Description -eq "Assign IP behind NAT"}).CommandLine = `
        "cmd.exe /c powershell -Command `"New-NetIPAddress -InterfaceAlias Ethernet -IPAddress $MasterIPAddress -AddressFamily IPv4 -PrefixLength $MaskCidr -DefaultGateway $DefaultGateway`""
        $DnsFormatted =""; $DnsServers.Split(@(',', ';')) | % {$DnsFormatted += "'$($_.Trim())', "}; $DnsFormatted = $DnsFormatted.Trim(@(',', ' ')); $DnsFormatted = "@($DnsFormatted)"
        ($MicrosoftWindowsShellSetup.FirstLogonCommands.SynchronousCommand | ? {$_.Description -eq "Set DNS"}).CommandLine = `
        "cmd.exe /c powershell -Command `"Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses $DnsFormatted`""

        # custom license key
        if ($ProductKey) {
            $key = $autounattend.CreateNode([System.Xml.XmlNodeType]::Element , "Key", "urn:schemas-microsoft-com:unattend")
            $MicrosoftWindowsSetup = $autounattend.unattend.settings.component | ? {$_.name -eq "Microsoft-Windows-Setup"}
            $MicrosoftWindowsSetup.UserData.ProductKey.AppendChild($key) | out-null
            $MicrosoftWindowsSetup.UserData.ProductKey.Key = $ProductKey
        }

        $autounattend.Save($autounattendPath)

        #bake iso
        $FileName="$ParentFolder/iso/minimal-windows-server.iso";
        $Files=@(
            "$ParentFolder/hyper-v/Windows/answer_files/2019/Autounattend.xml",
            "$ParentFolder/hyper-v/Windows/scripts/disable-screensaver.ps1",
            "$ParentFolder/hyper-v/Windows/scripts/disable-winrm.ps1",
            "$ParentFolder/hyper-v/Windows/scripts/enable-winrm.ps1",
            "$ParentFolder/hyper-v/Windows/scripts/microsoft-updates.bat",
            "$ParentFolder/hyper-v/Windows/scripts/unattend.xml",
            "$ParentFolder/hyper-v/Windows/scripts/shutdown_vm.bat",
            "$ParentFolder/hyper-v/Windows/scripts/win-updates.ps1"
        )
        New-IsoFile -Path $FileName -Source $Files -Force -Media "CDR"
    }
    elseif ($imageOs -eq "Linux")
    {
        $createAccountDirective = "`n
# Create appveyor user account.
d-i passwd/user-fullname string appveyor
d-i passwd/username string appveyor
d-i passwd/user-password password $install_password
d-i passwd/user-password-again password $install_password
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false
d-i passwd/user-default-groups appveyor sudo
"
[System.IO.File]::AppendAllText("$ParentFolder/http/preseed18.cfg", $createAccountDirective)
    }

    # sanitize ISO URL if needed (more reliable than escape backslashes in local/unc paths).
    if ($IsoUrl) {
        $PathInfo = [System.Uri]($IsoUrl)
        if ($PathInfo.IsFile -or $PathInfo.IsUnc)
        {
            $IsoUrl = $PathInfo.AbsoluteUri
        }
    }

    if ($IsoUrl -and $IsoChecksum) {
        $iso_checksum_type = 'sha256'
    } elseif ($IsoUrl) {
        $iso_checksum_type = 'none'
    }

    if (-not $ImagesDirectory) {
        $ImagesDirectory = Join-Path $env:SystemDrive "$CommonPrefix-Images"
    }
    $output_directory = Join-Path $ImagesDirectory $(New-Guid)
    
    if (-not $VmsDirectory) {
        $VmsDirectory = Join-Path $env:SystemDrive "$CommonPrefix-VMs"
    }

    if ($PackerTempDirectory -and -not (Test-Path $PackerTempDirectory)) {
        New-Item $PackerTempDirectory -ItemType Directory -Force | Out-Null
    }

    #TODO scenario if subnet is occuped (to get existing subnets: gwmi -computer .  -class "win32_networkadapterconfiguration" | % {$_.ipsubnet})
    $natSwitch = "$CommonPrefix-NAT-Switch"
    $natNetwork = "$CommonPrefix-NAT-Network"
    $HttpPortMin = "9990"
    $HttpPortMax = "9999"
    $FirewalRuleName = "$CommonPrefix-packer-inbound"
    Write-host "`nGetting or creating virtual switch $natSwitch..." -ForegroundColor Cyan
    if (-not (Get-VMSwitch $natSwitch -ErrorAction Ignore)) {
        New-VMSwitch -SwitchName $natSwitch -SwitchType Internal | out-null
        New-NetIPAddress -IPAddress $DefaultGateway -PrefixLength $MaskCidr -InterfaceAlias "vEthernet ($natSwitch)" | out-null
        New-NetNAT -Name $natNetwork -InternalIPInterfaceAddressPrefix $SubnetId/$MaskCidr | out-null
    }
    if ($imageOs -eq "Linux") {
        Write-host "`nGetting or creating inbound firewall rule '$FirewalRuleName' to allow access to Packer HTTP server on ports $HttpPortMin-$HttpPortMax..." -ForegroundColor Cyan
        if (-not (Get-NetFirewallRule -Name $FirewalRuleName -ErrorAction Ignore)) {
            New-NetFirewallRule -Name $FirewalRuleName -DisplayName $FirewalRuleName -Enabled True -Direction Inbound -Action Allow -LocalAddress $DefaultGateway -RemoteAddress $MasterIPAddress -LocalPort "$HttpPortMin-$HttpPortMax" -Protocol TCP | out-null
            Write-host "`Firewall rule '$FirewalRuleName' created." -ForegroundColor DarkGray
        }
        else {
            Write-host "`Using existing firewall rule '$FirewalRuleName'." -ForegroundColor DarkGray
        }
    }

    try {

        #Run Packer to create an VHD
        if (-not $VhdPath) {
            $packerPath = if ($imageOs -eq "Windows") {$(GetPackerPath -prerelease)} else {$(GetPackerPath)}
            $packerManifest = "$(CreateTempFolder)/packer-manifest.json"
            Write-host "`nRunning Packer to create a basic build VM VHD..." -ForegroundColor Cyan
            Write-Warning "Add '-VhdPath' parameter with if you want to to skip Packer build and and reuse existing VHD."
            Write-Host "`n`nPacker progress:`n"
            $date_mark=Get-Date -UFormat "%Y%m%d%H%M%S"
            & $packerPath build '--only=hyperv-iso' `
            -var "install_password=$install_password" `
            -var "install_user=$install_user" `
            -var "build_agent_mode=HyperV" `
            -var "disk_size=$($DiskSize * 1024)" `
            -var "hyperv_switchname=$natSwitch" `
            -var "iso_checksum=$IsoChecksum" `
            -var "iso_checksum_type=$iso_checksum_type" `
            -var "iso_url=$IsoUrl" `
            -var "output_directory=$output_directory" `
            -var "datemark=$date_mark" `
            -var "packer_manifest=$packerManifest" `
            -var "OPT_FEATURES=$ImageFeatures" `
            -var "host_ip_addr=$MasterIPAddress" `
            -var "host_ip_mask=$SubnetMask" `
            -var "host_ip_gw=$DefaultGateway" `
            -var "http_port_min=$HttpPortMin" `
            -var "http_port_max=$HttpPortMax" `
            -var "avma_key=$AVMAKey" `
            -var "cpus=$CpuCores" `
            -var "memory=$RamMb" `
            -var "packer_temp_dir=$PackerTempDirectory" `
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
                            generation = "2"
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




