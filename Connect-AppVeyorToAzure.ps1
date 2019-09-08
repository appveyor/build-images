Function Connect-AppVeyorToAzure {
    <#
    .SYNOPSIS
        Command to enable Azure builds. Works with both hosted AppVeyor and AppVeyor Server.

    .DESCRIPTION
        You can connect your AppVeyor account (on both hosted AppVeyor and on-premise AppVeyor Server) to your own Azure subscription for AppVeyor to instantiate build VMs in it. It has a lot of benefits like having ability to customize your build image, select desired VM size, set custom build timeout and much more. To simplify setup process for you, this command provisions necessary Azure resources, runs Hashicorp Packer to create a basic build image (based on Windows Server 2019), and puts all AppVeyor configuration together. After running this command, you should be able to start builds on Azure immediately (and optionally customize your Azure build environment later).

    .PARAMETER AppVeyorUrl
        AppVeyor URL. For hosted AppVeyor it is https://ci.appveyor.com. For Appveyor Server users it is URL of on-premise AppVeyor Server installation

    .PARAMETER ApiToken
        API key for specific account (not 'All accounts'). Hosted AppVeyor users can find it at https://ci.appveyor.com/api-keys. Appveyor Server users can find it at <appveyor_server_url>/api-keys.

    .PARAMETER UseCurrentAzureLogin
        Use Azure user currently logged in PowerShell and its selected subscription. If this parameter is not set or no Azure user is already logged in PowerShell, command will ask to login to Azure and (if user has multiple subscriptions) select the subscription. It is not recommended to use this switch parameter for the first command run, and select Azure user and subscription carefully. But it can come handy if you need to re-run the command.

    .PARAMETER SkipDisclaimer
        Skip warning related to Azure resources creation and potential Azure charges. It is recommended to read the warning at least once, but it can come handy if you need to re-run the command.

    .PARAMETER Location
        Azure location (or region) where you want command to create build worker image and all additional required resources. Also AppVeyor will create build VMs in this location. Use short notation (not display name) e.g. 'westus', not 'West US'.

    .PARAMETER VmSize
        Size of Azure build VM. Use short notation (not display name) e.g. 'Standard_D2s_v3', not 'Standard D2s v3'.

    .PARAMETER VhdFullPath
        It can happen that you run the command, and it created a valid VHD, but some AppVeyor settings were not set correctly (or just you want to change them without doing it in the AppVeyor build environments UI). In this case you want to skip the most time consuming step (creating a VHD) and pass already created VHD path to this parameter.

    .PARAMETER CommonPrefix
        Command will prepend all created Azure resources and AppVeyor build environment name with it. Because of storage account names restrictions, is must contain only letters and numbers and be shorter than 16 symbols. Default value is 'appveyor'.

    .PARAMETER ImageOs
        Operating system of build VM image. Valid values: 'Windows', 'Linux'. Default value is 'Windows'.

    .PARAMETER ImageName
        Description to be passed to the Packer and name to be used for AppVeyor image. Default value generated is based on the value of 'ImageOs' parameter.

    .PARAMETER ImageTemplate
        If you are familiar with the Hashicorp Packer, you can replace template used by this command with another one.  Default value generated is based on the value of 'ImageOs' parameter.

        .EXAMPLE
        Connect-AppVeyorToAzure
        Let command collect all required information

        .EXAMPLE
        Connect-AppVeyorToAzure -ApiToken XXXXXXXXXXXXXXXXXXXXX -AppVeyorUrl "https://ci.appveyor.com" -Location westus -VmSize Standard_D2s_v3 -SkipDisclaimer -UseCurrentAzureLogin
        Run command with all required parameters so command will ask now questions. It will create resources in Azure West US region will connect it to the hosted AppVeyor.
    #>

    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory=$true,HelpMessage="AppVeyor URL`nFor hosted AppVeyor it is https://ci.appveyor.com`nFor Appveyor Server users it is URL of on-premise AppVeyor Server installation")]
      [string]$AppVeyorUrl,

      [Parameter(Mandatory=$true,HelpMessage="API key for specific account (not 'All accounts')`nHosted AppVeyor users can find it at https://ci.appveyor.com/api-keys`nAppveyor Server users can find it at <appveyor_server_url>/api-keys")]
      [string]$ApiToken,

      [Parameter(Mandatory=$false)]
      [switch]$UseCurrentAzureLogin,

      [Parameter(Mandatory=$false)]
      [switch]$SkipDisclaimer,

      [Parameter(Mandatory=$false)]
      [string]$Location,

      [Parameter(Mandatory=$false)]
      [string]$VmSize,
      
      [Parameter(Mandatory=$false)]
      [string]$VhdFullPath,

      [Parameter(Mandatory=$false)]
      [string]$CommonPrefix = "appveyor",

      [Parameter(Mandatory=$false)]
      [ValidateSet('Windows','Linux')]
      [string]$ImageOs = "Windows",

      [Parameter(Mandatory=$false)]
      [string]$ImageName,

      [Parameter(Mandatory=$false)]
      [string]$ImageTemplate
    )

    function ExitScript {
        #TODO cleanup if needed
        break all
    }

    $ErrorActionPreference = "Stop"

    $StopWatch = New-Object System.Diagnostics.Stopwatch
    $StopWatch.Start()

    #Sanitize input
    $AppVeyorUrl = $AppVeyorUrl.TrimEnd("/")

    #Validate AppVeyor API access
    ValidateAppVeyorApiAccess $AppVeyorUrl $ApiToken

    if (-not (Get-Module -Name *Az.* -ListAvailable)) {
        Write-Warning "This command depends on Az PowerShell Module. Please install it with 'Install-Module -Name Az -AllowClobber' command"
        ExitScript
    }

    if (Get-Module -Name *AzureRM.* -ListAvailable) {
        Write-Warning "It is safer to uninstall AzureRM PowerShell module or use different computer to run this command. We noticed unpredictable behaviour when both Az and AzureRM modules are installed. Enter Ctrl-C to stop the command and run 'Uninstall-AzureRm' or do nothing to continue as is.`nWaiting 30 seconds..."
        for ($i = 30; $i -ge 0; $i--) {sleep 1; Write-Host "." -NoNewline}
        Write-Host ""
    }

    if (-not (Get-Command packer -ErrorAction Ignore)) {
        Write-Warning "This command depends on Packer by HashiCorp. Please install it with 'choco install packer' command or from download page https://www.packer.io/downloads.html. If it is already installed, please ensure that PATH environment variable contains path to it."
        ExitScript
    }

    $regex =[regex] "^([A-Za-z0-9]+)$"
    if (-not $regex.Match($CommonPrefix).Success) {
        Write-Warning "'CommonPrefix' can contain only letters and numbers"
        ExitScript
    }

    #"artifact" is longest name postfix. 
    #24 is storage account name limit
    #5 is minumum lenght of infix to be unique
    $maxtotallength = 24
    $mininfix = 5
    $maxpostfix = "artifact".Length
    $maxprefix = $maxtotallength - $maxpostfix - $mininfix
    if ($CommonPrefix.Length -ge  $maxprefix){
         Write-warning "Length of 'CommonPrefix' must be under $($maxprefix)"
         ExitScript
    }

    #Make storage account names globally unique
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding
    $apikeyhash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($ApiToken)))
    $infix = $apikeyhash.Replace("-", "").ToLower()
    $maxinfix = ($maxtotallength - $CommonPrefix.Length - $maxpostfix)
    if ($infix.Length -gt $maxinfix){$infix = $infix.Substring(0, $maxinfix)}

    $azure_storage_account_premium = "$($CommonPrefix)$($infix)prem".ToLower()
    $azure_storage_account_standard = "$($CommonPrefix)$($infix)std".ToLower()
    $azure_storage_account_cache = "$($CommonPrefix)$($infix)cache".ToLower()
    $azure_storage_account_artifacts = "$($CommonPrefix)$($infix)artifact".ToLower()

    $azure_storage_container = "$($CommonPrefix)-vms"
    $azure_cache_storage_name = "$($CommonPrefix)-azure-cache"
    $azure_artifact_storage_name = "$($CommonPrefix)-azure-artifacts"

    $azure_service_principal_name = "$($CommonPrefix)-sp"
    $azure_resource_group_name = "$($CommonPrefix)-rg"
    $azure_vnet_name = "$($CommonPrefix)-vnet"
    $azure_subnet_name = "$($CommonPrefix)-subnet"
    $azure_nsg_name = "$($CommonPrefix)-nsg"

    $build_cloud_name = "$($ImageOs)-Azure-build-environment"
    $ImageName = if ($ImageName) {$ImageName} else {"$($ImageOs) on Azure"}
    $ImageTemplate = if ($ImageTemplate) {$ImageTemplate} elseif ($ImageOs -eq "Windows") {"$PSScriptRoot/minimal-windows-server.json"} elseif ($ImageOs -eq "Linux") {"$PSScriptRoot/minimal-ubuntu.json"}

    $packer_manifest = "$PSScriptRoot/packer-manifest.json"
    $install_user = "appveyor"
    $install_password = (Get-Culture).TextInfo.ToTitleCase((New-Guid).ToString().SubString(0, 15).Replace("-", "")) + @('!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '=')[(Get-Random -Maximum 12)]

    #Login to Azure and select subscription
    Write-host "Selecting Azure user and subscription..." -ForegroundColor Cyan
    $contenxt = Get-AzContext
    if (-not $contenxt) {
        Login-AzAccount | Out-Null
    }
    elseif (-not $UseCurrentAzureLogin) {
        Write-host "You are currently logged in to Azure as $($contenxt.Account)"
        Write-Warning "Add '-UseCurrentAzureLogin' switch parameter to use currently logged in Azure user and skip this dialog next time."
        $relogin = Read-Host "Enter 1 if you want continue or 2 to re-login to Azure"
        if ($relogin -eq 1) {
            Write-host "Using Azure user '$($contenxt.Account)'" -ForegroundColor DarkGray
        }
        elseif ($relogin -eq 2) {Login-AzAccount | Out-Null}
        else {
            Write-Warning "Invalid input. Enter either 1 or 2."
            ExitScript
        }
    }
    else {
        Write-host "Using Azure account '$($contenxt.Account)'" -ForegroundColor DarkGray
    }

    if ($context.Subscription -and $UseCurrentAzureLogin) {
        Write-host "Using subscription '$($contenxt.Subscription.Name)'" -ForegroundColor DarkGray
        $azure_subscription_id = $contenxt.Subscription.Id
        $azure_tenant_id = $contenxt.Subscription.TenantId
    }
    else {
        $subs = Get-AzSubscription
        $subs = $subs | ? {$_.State -eq "Enabled"}
        if (-not $subs -or $subs.Count -eq 0) {
            Write-Warning "No Azure subscriptions enabled. Please login to the Azure portal and create or enable one. If this does not help, please run 'Logout-AzAccount' and try again."
            ExitScript
        }
        if ($subs.Count -gt 1) {
            Write-host "There is more than one enabled subscription under your account"
            for ($i = 1; $i -le $subs.Count; $i++) {"Select $i for $($subs[$i - 1].name)"}
            $subscription_number = Read-Host "Enter your selection"
            $selected_subscription = $subs[$subscription_number - 1]
            Write-host "Using subscription '$($selected_subscription.name)'" -ForegroundColor DarkGray
            Set-AzContext -SubscriptionId $selected_subscription.Id | Out-Null
            $azure_subscription_id = $selected_subscription.Id
            $azure_tenant_id = $selected_subscription.TenantId
        }
        else {
            Write-host "Using subscription '$($subs[0].name)'" -ForegroundColor DarkGray
            Set-AzContext -SubscriptionId $subs[0].Id | Out-Null
            $azure_subscription_id = $subs[0].Id
            $azure_tenant_id = $subs[0].TenantId
        }
    }

    if (-not $SkipDisclaimer) {
         Write-Warning "`nThis command will create Azure resources such as storage accounts, containers, virtual networks and subnets in subscription '$((Get-AzContext).Subscription.Name)'. Also, it will run Hashicorp Packer which will create its own temporary Azure resources and leave VHD blob in the storage account created by this command for future use by AppVeyor build VMs. Please be aware of possible charges from Azure. `nIf subscription '$((Get-AzContext).Subscription.Name)' contains production resources, it is safer to create a separate subscription and run this command against it. Additionally, a separate subscription is better to distinguish Azure bills for CI machines from other Azure bills. `nPress Enter to continue or Ctrl-C to exit the command. Use '-SkipDisclaimer' switch parameter to skip this message next time."
         $disclaimer = Read-Host
    }
    try {
        #Get or create service principal
        Write-host "`nGetting or creating Azure AD service principal..." -ForegroundColor Cyan
        $sp = Get-AzADServicePrincipal -DisplayName $azure_service_principal_name
        $app = Get-AzADApplication -DisplayName $azure_service_principal_name
        if (-not $sp -and $app) {
            Write-Warning "Service principal '$($azure_service_principal_name)' does not exist, but Azure AD application with the same name already exists." 
            "`nPlease either delete that Azure Ad Application or use another service principal name."
            ExitScript
        }
        if (-not $sp) {
            $sp = New-AzADServicePrincipal -DisplayName $azure_service_principal_name -Role Contributor
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp.Secret)
            $azure_client_secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
        # reset password if service principal already exists 
        else {
            Remove-AzADSpCredential -DisplayName $sp.DisplayName -Force
            $newCredential = New-AzADSpCredential -ObjectId $sp.Id -EndDate (get-date).AddYears(10)
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newCredential.Secret)
            $azure_client_secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
        $azure_client_id = $sp.ApplicationId
        Write-host "Using Azure AD service principal '$($azure_service_principal_name)'" -ForegroundColor DarkGray

        #Select location
        Write-host "`nSelecting location..." -ForegroundColor Cyan
        $locations = Get-AzLocation
        if ($Location) {
            $Location_full = ($locations | ? {$_.Location -eq $Location}).DisplayName
        }
        else {
            for ($i = 1; $i -le $locations.Count; $i++) {"Select $i for $($locations[$i - 1].DisplayName)"}
            Write-Warning "Add '-Location' parameter to skip this dialog next time."
            $location_number = Read-Host "Enter your selection"
            if (-not $location_number) {
                Write-Warning "No Azure location selected."
                ExitScript
            }
            $selected_location = $locations[$location_number - 1]
            $Location = $selected_location.Location
            $Location_full = $selected_location.DisplayName
        }
        Write-host "Using location '$($Location_full)'" -ForegroundColor DarkGray

        #Get or create resource group
        Write-host "`nGetting or creating Azure resource group..." -ForegroundColor Cyan
        $rg = Get-AzResourceGroup -Name $azure_resource_group_name -ErrorAction Ignore
        if (-not $rg) {
            $rg = New-AzResourceGroup -Name $azure_resource_group_name -Location $Location
        }
        elseif ($rg.Location -ne $Location) {
            Write-Warning "Resource group $($azure_resource_group_name) exists in location $($rg.Location) which is different from the location you chose ($($Location))"
            $changelocation = Read-Host "Enter 1 to use $($rg.Location) location or 2 to delete resource group $($azure_resource_group_name) in $($rg.Location) and re-create it in $($Location)"
            if ($changelocation -eq 1) {
                $Location = $rg.Location
                $Location_full = ($locations | ? {$_.Location -eq $rg.Location}).DisplayName
            }
            elseif ($changelocation -eq 2) {
                $recreate = Read-Host "Please type '$($azure_resource_group_name)' if you are sure to delete the resource group $($azure_resource_group_name) with all nested resources"
                if ($recreate -eq $azure_resource_group_name){
                    Remove-AzResourceGroup -Name $azure_resource_group_name -Force | Out-Null
                    $rg = New-AzResourceGroup -Name $azure_resource_group_name -Location $Location
                }
                else {
                    Write-Warning "Please consider whether you need to change a location or re-create a resource group and start over. ALternatively, you can use 'CommonPrefix' parameter to form alternative resource group name."
                    ExitScript
                }
            }
            else {
                Write-Warning "Invalid input. Enter either 1 or 2."
                ExitScript
            }
         }
         Write-host "Using resource group '$($azure_resource_group_name)' in location '$($Location_full)'" -ForegroundColor DarkGray

        #Select VM size
        Write-host "`nSelecting VM size..." -ForegroundColor Cyan
        if (-not $VmSize) {
            $vmsizes = Get-AzVMSize -Location $Location
            for ($i = 1; $i -le $vmsizes.Count; $i++) {"Select $i for $($vmsizes[$i - 1].Name) ($($vmsizes[$i - 1].NumberOfCores) Cores, $($vmsizes[$i - 1].MemoryInMB) Mb)"}
            if ($ImageOs -eq "Windows") {Write-Warning "Please use VM size which supports Premium storage (at least DS-series!)"}
            if ($ImageOs -eq "Linux") {Write-Warning "Minimum recommended is 'Standard_D2_v3'"}
            Write-Warning "Add '-VmSize' parameter to skip this dialog next time."
            $location_number = Read-Host "Enter your selection"
            $selected_vmsize = $vmsizes[$location_number - 1]
            $VmSize = $selected_vmsize.Name
        }
        Write-host "Using VM size '$($VmSize)'" -ForegroundColor DarkGray

        #Get or create storage accounts
        Write-host "`nGetting or creating Azure storage accounts..." -ForegroundColor Cyan
        function CreateStorageAccount ($azure_storage_account_name, $sku_name) {
        $sa = Get-AzStorageAccount -Name $azure_storage_account_name -ResourceGroupName $azure_resource_group_name -ErrorAction Ignore
        if (-not $sa) {
            $sacreatecount = 0
            try {
                $sacreatecount++
                $sa = New-AzStorageAccount -Name $azure_storage_account_name -ResourceGroupName $azure_resource_group_name -Location $Location -SkuName $sku_name  -Kind Storage
            }
            catch {
                if ($sacreatecount -ge 3) {
                    Write-Warning "Unable to create storage account '$($azure_storage_account_name)'. Error: $($error[0].Exception.Message)"
                    ExitScript
                }
            }
        }
        Write-host "Using storage account '$($azure_storage_account_name)' (SKU: $($sku_name))" -ForegroundColor DarkGray
        }

        # Select storage account supported by VM size
        $nonPremiumSizes = @(
                "Standard_D2_v3",
                "Standard_D4_v3",
                "Standard_D8_v3",
                "Standard_D16_v3",
                "Standard_D32_v3",
                "Standard_D48_v3",
                "Standard_D64_v3",

                "Standard_D2a_v3",
                "Standard_D4a_v3",
                "Standard_D8a_v3",
                "Standard_D16a_v3",
                "Standard_D32a_v3",
                "Standard_D48a_v3",
                "Standard_D64a_v3",

                "Standard_D1_v2",
                "Standard_D2_v2",
                "Standard_D3_v2",
                "Standard_D4_v2",
                "Standard_D5_v2",

                "Standard_A1_v2",
                "Standard_A2_v2",
                "Standard_A4_v2",
                "Standard_A8_v2",
                "Standard_A2m_v2",
                "Standard_A4m_v2",
                "Standard_A8m_v2",

                "Standard_E2_v3",
                "Standard_E4_v3",
                "Standard_E8_v3",
                "Standard_E16_v3",
                "Standard_E20_v3",
                "Standard_E32_v3",
                "Standard_E48_v3",
                "Standard_E64_v3",
                "Standard_E64i_v3",

                "Standard_E2a_v3",
                "Standard_E4a_v3",
                "Standard_E8a_v3",
                "Standard_E16a_v3",
                "Standard_E32a_v3",
                "Standard_E48a_v3",
                "Standard_E64a_v3",

                "Standard_D11_v2",
                "Standard_D12_v2",
                "Standard_D13_v2",
                "Standard_D14_v2",
                "Standard_D15_v2",

                "Standard_NC6",
                "Standard_NC12",
                "Standard_NC24",
                "Standard_NC24r",

                "Standard_NV6",
                "Standard_NV12",
                "Standard_NV24",

                "Standard_H8",
                "Standard_H16",
                "Standard_H8m",
                "Standard_H16m",
                "Standard_H16r",
                "Standard_H16mr",

                "Standard_F1",
                "Standard_F2",
                "Standard_F4",
                "Standard_F8",
                "Standard_F16",

                "A0\Basic_A0",
                "A1\Basic_A1",
                "A2\Basic_A2",
                "A3\Basic_A3",
                "A4\Basic_A4",

                "Standard_A0",
                "Standard_A1",
                "Standard_A2",
                "Standard_A3",
                "Standard_A4",
                "Standard_A5",
                "Standard_A6",
                "Standard_A7",

                "Standard_A8",
                "Standard_A9",
                "Standard_A10",
                "Standard_A11",

                "Standard_D1",
                "Standard_D2",
                "Standard_D3",
                "Standard_D4",

                "Standard_D11",
                "Standard_D12",
                "Standard_D13",
                "Standard_D14",

                "Standard_G1",
                "Standard_G2",
                "Standard_G3",
                "Standard_G4",
                "Standard_G5"
                )

        $azure_storage_account = $azure_storage_account_premium
        $sku_name = "Premium_LRS"
        if ($nonPremiumSizes | ? {$_ -eq $VmSize}) {
            #VM size does not support Premium storage
            $azure_storage_account = $azure_storage_account_standard
            $sku_name = "Standard_LRS"
        }
        CreateStorageAccount -azure_storage_account_name $azure_storage_account -sku_name $sku_name
        CreateStorageAccount -azure_storage_account_name $azure_storage_account_cache -sku_name Standard_LRS
        CreateStorageAccount -azure_storage_account_name $azure_storage_account_artifacts -sku_name Standard_LRS

        #Get or create vnet
        Write-host "`nGetting or creating Azure virtual network..." -ForegroundColor Cyan
        $vnet = Get-AzVirtualNetwork -Name $azure_vnet_name -ResourceGroupName $azure_resource_group_name -ErrorAction Ignore
        if (-not $vnet) {
            $subnet = New-AzVirtualNetworkSubnetConfig -Name $azure_subnet_name -AddressPrefix '10.0.0.0/24'
            $vnet = New-AzVirtualNetwork -Name $azure_vnet_name -ResourceGroupName $azure_resource_group_name -Location $Location -AddressPrefix "10.0.0.0/24" -Subnet $subnet
        }
        elseif (-not $vnet.Subnets -or $vnet.Subnets.Count -eq 0) {
            Write-Warning "Existing virtual network '$($azure_vnet_name)' does not have any subnet defined"
            ExitScript
        }
        elseif (-not ($vnet.Subnets | ? {$_.Name -eq $azure_subnet_name})) {
            Write-Warning "Existing virtual network '$($azure_vnet_name)' does not have subnet called $($azure_subnet_name), using existing subnet."
            $azure_subnet_name = $vnet.Subnets[0]
        }
        Write-host "Using virtual network '$($azure_vnet_name)' and subnet $($azure_subnet_name)" -ForegroundColor DarkGray

        #Get or create nsg
        Write-host "`nGetting or creating Azure network security group..." -ForegroundColor Cyan
        $nsg = Get-AzNetworkSecurityGroup -Name $azure_nsg_name -ResourceGroupName $azure_resource_group_name -ErrorAction Ignore
        if (-not $nsg) {
            $nsg = New-AzNetworkSecurityGroup -Name $azure_nsg_name -ResourceGroupName $azure_resource_group_name -Location $Location
        }
        Write-host "Using virtual network '$($azure_nsg_name)'" -ForegroundColor DarkGray

        $remoteaccessport = if ($ImageOs -eq "Windows") {3389} elseif ($ImageOs -eq "Linux") {22}
        $remoteaccessname = if ($ImageOs -eq "Windows") {"RDP"} elseif ($ImageOs -eq "Linux") {"SSH"}
        $remoteaccessrulepriority = if ($ImageOs -eq "Windows") {100} elseif ($ImageOs -eq "Linux") {101}
        $remoteaccesrulesname = "$($remoteaccessname)-in"
        Write-host "`nAllowing $($remoteaccessname) access to build VMs..." -ForegroundColor Cyan
        if (-not ($nsg.SecurityRules | ? {$_.DestinationPortRange -eq $remoteaccessport -and $_.Direction -eq "Inbound" -and $_.Access -eq "Allow"})) {
            $nsg | Add-AzNetworkSecurityRuleConfig -Name $remoteaccesrulesname -Description "Allow $($remoteaccessname)" -Access Allow -Protocol Tcp -Direction Inbound -Priority $remoteaccessrulepriority -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange $remoteaccessport | Set-AzNetworkSecurityGroup | Out-Null
            Write-host "Created inbound rule to allow TCP $($remoteaccessport) ($($remoteaccessname))" -ForegroundColor DarkGray
        }
        else {Write-host "Inbound rule to allow TCP $($remoteaccessport) ($($remoteaccessname)) already exist in network security group '$($azure_nsg_name)'" -ForegroundColor DarkGray}

        #Run Packer to create an image
        if (-not $VhdFullPath) {
            Write-host "`nRunning Packer to create a basic build VM image..." -ForegroundColor Cyan
            Write-Warning "Add '-VhdFullPath' parameter with VHD URL value if you want to reuse existing VHD (which must be in '$($azure_storage_account)' storage account). Enter Ctrl-C to stop the command and restart with '-VhdFullPath' parameter or do nothing and let the command create a new VHD.`nWaiting 30 seconds..."
            for ($i = 30; $i -ge 0; $i--) {sleep 1; Write-Host "." -NoNewline}
            Remove-Item $packer_manifest -Force -ErrorAction Ignore
            Write-Host "`n`nPacker progress:`n"
            $date_mark=Get-Date -UFormat "%Y%m%d%H%M%S"
            & packer build '--only=azure-arm' `
            -var "azure_subscription_id=$azure_subscription_id" `
            -var "azure_tenant_id=$azure_tenant_id" `
            -var "azure_client_id=$azure_client_id" `
            -var "azure_client_secret=$azure_client_secret" `
            -var "azure_location=$Location" `
            -var "azure_resource_group_name=$azure_resource_group_name" `
            -var "azure_storage_account=$azure_storage_account" `
            -var "install_password=$install_password" `
            -var "install_user=$install_user" `
            -var "azure_vm_size=$VmSize" `
            -var "build_agent_mode=Azure" `
            -var "image_description=$ImageName" `
            -var "datemark=$date_mark" `
            -var "packer_manifest=$packer_manifest" `
            $ImageTemplate

            #Get VHD path
            if (-not (test-path $packer_manifest)) {
                Write-Warning "Unable to find $packer_manifest. Please ensure Packer job finsihed successfully."
                ExitScript
            }
            Write-host "`nGetting VHD path..." -ForegroundColor Cyan
            $manifest = Get-Content -Path $packer_manifest | ConvertFrom-Json
            $VhdFullPath = $manifest.builds[0].artifact_id
            $vhd_path = $VhdFullPath.Replace("https://$($azure_storage_account).blob.core.windows.net/", "")
            Remove-Item $packer_manifest -Force -ErrorAction Ignore
            Write-host "Build image VHD created by Packer and available at '$($VhdFullPath)'" -ForegroundColor DarkGray
            Write-Host "Default build VM credentials: User: 'appveyor', Password: '$($install_password)'. Normally you do not need this password as it will be reset to a random string when the build starts. However you can use it if you need to create and update a VM from the Packer-created VHD manually"  -ForegroundColor DarkGray
        }
        else {
            Write-host "Using VHD path '$($VhdFullPath)'" -ForegroundColor DarkGray
            $vhd_path = $VhdFullPath.Replace("https://$($azure_storage_account).blob.core.windows.net/", "")
            $storagekey = (Get-AzStorageAccountKey -ResourceGroupName $azure_resource_group_name -Name $azure_storage_account)[0].Value
            $storagecontext =  New-AzStorageContext -StorageAccountName $azure_storage_account -StorageAccountKey $storagekey
            $storagecontainername = $vhd_path.Substring(0, $vhd_path.IndexOf("/"))
            $storageblobname = $vhd_path.Substring($vhd_path.IndexOf("/") + 1)
            $storageblob = Get-AzStorageBlob -Context $storagecontext -Container $storagecontainername -Blob $storageblobname -ErrorAction Ignore
            if (-not $storageblob) {
                Write-Warning "Unable to find storage blob '$($storageblobname)' in container '$($storagecontainername)', storage account '$($azure_storage_account)'"
                ExitScript
            }
        }

        #Create or update build cache storage settings
        Write-host "`nCreating or updating build cache storage settings on AppVeyor..." -ForegroundColor Cyan
        $storagekeycache = (Get-AzStorageAccountKey -ResourceGroupName $azure_resource_group_name -Name $azure_storage_account_cache)[0].Value
        $buildcaches = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches" -Headers $headers -Method Get
        $buildcache = $buildcaches | ? ({$_.name -eq $azure_cache_storage_name})[0]
        if (-not $buildcache) {
            $body = @{
                name = $azure_cache_storage_name
                cacheType = "Azure"
                settings = @{
                    accountName = $azure_storage_account_cache
                    accountAccessKey = $storagekeycache
                }
            }
            $jsonBody = $body | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            Write-host "AppVeyor build cache storage '$($azure_cache_storage_name)' has been created." -ForegroundColor DarkGray
        }
        else {
            $settings = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches/$($buildcache.buildCacheId)" -Headers $headers -Method Get
            $settings.name = $azure_cache_storage_name
            $settings.cacheType = "Azure"
            $settings.settings.accountName = $azure_storage_account_cache
            $settings.settings.accountAccessKey = $storagekeycache
            $jsonBody = $settings | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches"-Headers $headers -Body $jsonBody -Method Put | Out-Null
            Write-host "AppVeyor build cache storage '$($azure_cache_storage_name)' has been updated." -ForegroundColor DarkGray
        }

        #Create or update artifacts storage settings
        Write-host "`nCreating or updating artifacts storage settings on AppVeyor..." -ForegroundColor Cyan
        $storagekeyartifacts = (Get-AzStorageAccountKey -ResourceGroupName $azure_resource_group_name -Name $azure_storage_account_artifacts)[0].Value
        $artifactstorages = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages" -Headers $headers -Method Get
        $artifactstorage = $artifactstorages | ? ({$_.name -eq $azure_artifact_storage_name})[0]
        if (-not $artifactstorage) {
            $body = @{
                name = $azure_artifact_storage_name
                storageType = "Azure"
                settings = @{
                    accountName = $azure_storage_account_artifacts
                    accountAccessKey = $storagekeyartifacts
                }
            }
            $jsonBody = $body | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            Write-host "AppVeyor artifacts storage '$($azure_artifact_storage_name)' has been created." -ForegroundColor DarkGray
        }
        else {
            $settings = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages/$($artifactstorage.artifactStorageId)" -Headers $headers -Method Get
            $settings.name = $azure_artifact_storage_name
            $settings.storageType = "Azure"
            $settings.settings.accountName = $azure_storage_account_artifacts
            $settings.settings.accountAccessKey = $storagekeyartifacts
            $jsonBody = $settings | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages"-Headers $headers -Body $jsonBody -Method Put | Out-Null
            Write-host "AppVeyor artifacts storage '$($azure_artifact_storage_name)' has been updated." -ForegroundColor DarkGray
        }

        #Create or update cloud
        Write-host "`nCreating or updating build environment on AppVeyor..." -ForegroundColor Cyan
        $clouds = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds" -Headers $headers -Method Get
        $cloud = $clouds | ? ({$_.name -eq $build_cloud_name})[0]
        if (-not $cloud) {
            $body = @{
                name = $build_cloud_name
                cloudType = "Azure"
                workersCapacity = 20
                settings = @{
                    artifactStorageName = $azure_artifact_storage_name
                    buildCacheName = $azure_cache_storage_name
                    failureStrategy = @{
                        jobStartTimeoutSeconds = 180
                        provisioningAttempts = 3
                    }
                    cloudSettings = @{
                        azureAccount =@{
                            clientId = $azure_client_id
                            clientSecret = $azure_client_secret
                            tenantId = $azure_tenant_id
                            subscriptionId = $azure_subscription_id
                        }
                        vmConfiguration = @{
                            location = $Location
                            vmSize = $VmSize
                            diskStorageAccountName = $azure_storage_account
                            diskStorageContainer = $azure_storage_container
                            vmResourceGroup = $azure_resource_group_name
                        }
                        networking = @{
                            assignPublicIPAddress = $true
                            placeBehindAzureLoadBalancer = $false
                            virtualNetworkName = $azure_vnet_name
                            subnetName = $azure_subnet_name
                            securityGroupName = $azure_nsg_name
                            }
                        images = @(@{
                                name = $ImageName
                                vhdPathOrImage = $vhd_path
                            })
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
            $settings = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds/$($cloud.buildCloudId)" -Headers $headers -Method Get
            $settings.name = $build_cloud_name
            $settings.cloudType = "Azure"
            $settings.workersCapacity = 20
            if (-not $settings.settings.artifactStorageName ) {
                $settings.settings  | Add-Member NoteProperty "artifactStorageName" $azure_artifact_storage_name -force
            }
            else {
                $settings.settings.artifactStorageName = $azure_artifact_storage_name 
            }
            if (-not $settings.settings.buildCacheName ) {
                $settings.settings  | Add-Member NoteProperty "buildCacheName" $azure_cache_storage_name -force
            }
            else {
                $settings.settings.buildCacheName = $azure_cache_storage_name 
            }
            $settings.settings.failureStrategy.jobStartTimeoutSeconds = 180
            $settings.settings.failureStrategy.provisioningAttempts = 3
            $settings.settings.cloudSettings.azureAccount.clientId = $azure_client_id
            $settings.settings.cloudSettings.azureAccount.clientSecret = $azure_client_secret
            $settings.settings.cloudSettings.azureAccount.tenantId = $azure_tenant_id
            $settings.settings.cloudSettings.azureAccount.subscriptionId = $azure_subscription_id
            $settings.settings.cloudSettings.vmConfiguration.location = $Location
            $settings.settings.cloudSettings.vmConfiguration.vmSize = $VmSize
            $settings.settings.cloudSettings.vmConfiguration.diskStorageAccountName = $azure_storage_account
            $settings.settings.cloudSettings.vmConfiguration.diskStorageContainer = $azure_storage_container
            $settings.settings.cloudSettings.vmConfiguration.vmResourceGroup = $azure_resource_group_name
            $settings.settings.cloudSettings.networking.assignPublicIPAddress = $true
            $settings.settings.cloudSettings.networking.placeBehindAzureLoadBalancer = $false
            $settings.settings.cloudSettings.networking.virtualNetworkName = $azure_vnet_name
            $settings.settings.cloudSettings.networking.subnetName = $azure_subnet_name
            $settings.settings.cloudSettings.networking.securityGroupName = $azure_nsg_name
            $settings.settings.cloudSettings.images[0].name = $ImageName
            $settings.settings.cloudSettings.images[0].vhdPathOrImage = $vhd_path

            $jsonBody = $settings | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds"-Headers $headers -Body $jsonBody -Method Put | Out-Null
            Write-host "AppVeyor build environment '$($build_cloud_name)' has been updated." -ForegroundColor DarkGray
        }

        Write-host "`nEnsuring build worker image is available for AppVeyor projects..." -ForegroundColor Cyan
        $images = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-worker-images" -Headers $headers -Method Get
        $image = $images | ? ({$_.name -eq $ImageName})[0]
        $osType = if ($ImageOs -eq "Windows") {"Windows"} elseif ($ImageOs -eq "Linux") {"Ubuntu"}
        if (-not $image) {
            $body = @{
                name = $ImageName
                buildCloudName = $build_cloud_name
                osType = "$osType"
            }

            $jsonBody = $body | ConvertTo-Json
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-worker-images" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            Write-host "AppVeyor build worker image '$($ImageName)' has been created." -ForegroundColor DarkGray
        }
        else {
            $image.name = $ImageName
            $image.buildCloudName = $build_cloud_name
            $image.osType = "$osType"

            $jsonBody = $image | ConvertTo-Json
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-worker-images" -Headers $headers -Body $jsonBody  -Method Put | Out-Null
            Write-host "AppVeyor build worker image '$($ImageName)' has been updated." -ForegroundColor DarkGray
        }

        $StopWatch.Stop()
        $completed = "{0:hh}:{0:mm}:{0:ss}" -f $StopWatch.elapsed
        Write-Host "`nCompleted in $completed."

        #Report results and next steps
        Write-host "`nNext steps:"  -ForegroundColor Cyan
        Write-host " - Optionally review build environment '$($build_cloud_name)' at '$($AppVeyorUrl)/build-clouds/$($cloud.buildCloudId)'" -ForegroundColor DarkGray
        Write-host " - To start building on Azure set " -ForegroundColor DarkGray -NoNewline
        Write-host "$($ImageName) " -NoNewline 
        Write-host "build worker image " -ForegroundColor DarkGray -NoNewline 
        Write-host "and " -ForegroundColor DarkGray -NoNewline 
        Write-host "$($build_cloud_name) " -NoNewline 
        Write-host "build cloud in AppVeyor project settings or appveyor.yml." -NoNewline -ForegroundColor DarkGray
    }

    catch {
        Write-Warning "Command exited with error: $($_.Exception)"
        ExitScript
    }
}
