[CmdletBinding()]
param
(
  [Parameter(Mandatory=$true,HelpMessage="API key for specific account (not 'All accounts')`nHosted AppVeyor users can find it at https://ci.appveyor.com/api-keys`nAppveyor Server users can find it at <appveyor_server_url>/api-keys")]
  [string]$appveyor_api_key,

  [Parameter(Mandatory=$true,HelpMessage="AppVeyor URL`nFor hosted AppVeyor it is https://ci.appveyor.com`nFor Appveyor Server users it is URL of on-premise AppVeyor Server installation")]
  [string]$appveyor_url,

  [Parameter(Mandatory=$false)]
  [switch]$use_current_azure_login,

  [Parameter(Mandatory=$false)]
  [switch]$skip_disclaimer,

  [Parameter(Mandatory=$false)]
  [string]$azure_location,

  [Parameter(Mandatory=$false)]
  [string]$azure_vm_size,
  
  [Parameter(Mandatory=$false)]
  [string]$vhd_full_path,

  [Parameter(Mandatory=$false)]
  [string]$azure_prefix = "appveyor",

  [Parameter(Mandatory=$false)]
  [string]$image_description = "Windows Server 2019 on Azure",

  [Parameter(Mandatory=$false)]
  [string]$packer_template = ".\minimal-windows-server-2019.json"
)

$ErrorActionPreference = "Stop"

$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()

#Sanitize input
$appveyor_url = $appveyor_url.TrimEnd("/")

#Validate input
$regex =[regex] "^([A-Za-z0-9]+)+(-?[A-Za-z0-9])*$"
if (-not $regex.Match($azure_prefix).Success) {
    Write-Warning "'azure_prefix' can contain letters, numbers and dash (-)"
    return
}

$maxazureprefix = 24 - "artifact".Length #"artifact" is longest storage account name postfix
if ($azure_prefix.Length -ge  $maxazureprefix){
     Write-warning "Length of 'azure_prefix' must be under $($maxazureprefix)"
     return
}

if ($appveyor_api_key -like "v2.*") {
    Write-Warning "Please select the API Key for specific account (not 'All Accounts') at '$($appveyor_url)/api-keys'"
    return
}

try {
    $responce = Invoke-WebRequest -Uri $appveyor_url -ErrorAction SilentlyContinue
    if ($responce.StatusCode -ne 200) {
        Write-warning "AppVeyor URL '$($appveyor_url)' respondd with code $($responce.StatusCode)"
        return
    }
}
catch {
    Write-warning "Unable to connect to AppVeyor URL '$($appveyor_url)'. Error: $($error[0].Exception.Message)"
        return
}

if (-not (test-path $packer_template)) {
    Write-Warning "Please provide correct relative path as the packer_template parameter"
    return
}

if (-not (Get-Module -Name *Az.* -ListAvailable)) {
    Write-Warning "This script depends on Az PowerShell Module. Please install it with 'Install-Module -Name Az -AllowClobber' command"
    return
}

if (Get-Module -Name *AzureRM.* -ListAvailable) {
    Write-Warning "It is safer to uninstall AzureRM PowerShell module or use different computer to run this script. We noticed unpredictable behaviour when both Az and AzureRM modules are installed. Enter Ctrl-C to stop the script and run 'Uninstall-AzureRm' or do nothing to continue as is.`nWaiting 30 seconds..."
    for ($i = 30; $i -ge 0; $i--) {sleep 1; Write-Host "." -NoNewline}
    Write-Host ""
}

if (-not (Get-Command packer -ErrorAction Ignore)) {
    Write-Warning "This script depends on Packer by HashiCorp. Please install it with 'choco install packer' command or from download page https://www.packer.io/downloads.html. If it is already installed, please ensure that PATH environment variable contains path to it."
    return
}

$headers = @{
  "Authorization" = "Bearer $appveyor_api_key"
  "Content-type" = "application/json"
}
try {
    Invoke-RestMethod -Uri "$($appveyor_url)/api/projects" -Headers $headers -Method Get | Out-Null
}
catch {
    Write-warning "Unable to call AppVeyor REST API, please verify 'appveyor_api_key' and ensure '-appveyor_url' parameter is set if you are using on-premise AppVeyor Server."
    return
}

if ($appveyor_url -eq "https://ci.appveyor.com") {
      try {
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds" -Headers $headers -Method Get | Out-Null
    }
    catch {
        Write-warning "Please contact support@appveyor.com and request enabling of 'Private build clouds' feature."
        return
    }
}

#Make storage account names globally unique
$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = new-object -TypeName System.Text.UTF8Encoding
$apikeyhash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($appveyor_api_key)))
$infix = $apikeyhash.Replace("-", "").Substring(0, ($maxazureprefix - $azure_prefix.Length)).ToLower()

$azure_storage_account = "$($azure_prefix)$($infix)vm"
$azure_storage_account_cache = "$($azure_prefix)$($infix)cache"
$azure_storage_account_artifacts = "$($azure_prefix)$($infix)artifact"

$azure_storage_container = "$($azure_prefix)-vms"
$azure_cache_storage_name = "$($azure_prefix)-cache"
$azure_artifact_storage_name = "$($azure_prefix)-artifacts"

$azure_service_principal_name = "$($azure_prefix)-sp"
$azure_resource_group_name = "$($azure_prefix)-rg"
$azure_vnet_name = "$($azure_prefix)-vnet"
$azure_subnet_name = "$($azure_prefix)-subnet"
$azure_nsg_name = "$($azure_prefix)-nsg"
$build_cloud_name = "$($azure_prefix)-build-environment"

$packer_manifest = "packer-manifest.json"
$install_user = "appveyor"
$install_password = "ABC" + (New-Guid).ToString().SubString(0, 12).Replace("-", "") + "!"

#Login to Azure and select subscription
Write-host "Selecting Azure user and subscription..." -ForegroundColor Cyan
$contenxt = Get-AzContext
if (-not $contenxt) {
    Login-AzAccount | Out-Null
}
elseif (-not $use_current_azure_login) {
    Write-host "You are currently logged in to Azure as $($contenxt.Account)"
    Write-Warning "Add '-use_current_azure_login' switch parameter to use currently logged in Azure user and skip this dialog next time."
    $relogin = Read-Host "Enter 1 if you want continue or 2 to re-login to Azure"
    if ($relogin -eq 1) {
        Write-host "Using Azure user '$($contenxt.Account)'" -ForegroundColor DarkGray
    }
    elseif ($relogin -eq 2) {Login-AzAccount | Out-Null}
    else {
        Write-Warning "Invalid input. Enter either 1 or 2."
        return
    }
}
else {
    Write-host "Using Azure account '$($contenxt.Account)'" -ForegroundColor DarkGray
}

if ($context.Subscription -and $use_current_azure_login) {
    Write-host "Using subscription '$($contenxt.Subscription.Name)'" -ForegroundColor DarkGray
    $azure_subscription_id = $contenxt.Subscription.Id
    $azure_tenant_id = $contenxt.Subscription.TenantId
}
else {
    $subs = Get-AzSubscription
    $subs = $subs | ? {$_.State -eq "Enabled"}
    if (-not $subs -or $subs.Count -eq 0) {
        Write-Warning "No Azure subscriptions enabled. Please login to the Azure portal and create or enable one."
        return
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

if (-not $skip_disclaimer) {
     Write-Warning "`nThis script will create Azure resources such as storage accounts, containers, virtual networks and subnets in subscription '$((Get-AzContext).Subscription.Name)'. Also, it will run Hashicorp Packer which will create its own temporary Azure resources and leave VHD blob in the storage account created by this script for future use by AppVeyor build VMs. Please be aware of possible charges from Azure. `nIf subscription '$((Get-AzContext).Subscription.Name)' contains production resources, it is safer to create a separate subscription and run this script against it. Additionally, separate subscription is better to distinguish Azure bills for CI machines from other Azure bills. `nPress Enter to continue or Ctrl-C to exit the script. Use '-skip_disclaimer' switch parameter to skip this message next time."
     $disclaimer = Read-Host
}

#Get or create service principal
Write-host "`nGetting or creating Azure AD service principal..." -ForegroundColor Cyan
$sp = Get-AzADServicePrincipal -DisplayName $azure_service_principal_name
$app = Get-AzADApplication -DisplayName $azure_service_principal_name
if (-not $sp -and $app) {
    Write-Warning "Service principal '$($azure_service_principal_name)' does not exist, but Azure AD application with the same name already exists." 
    "`nPlease either delete that Azure Ad Application or use another service principal name."
    return
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
if ($azure_location) {
    $azure_location_full = ($locations | ? {$_.Location -eq $azure_location}).DisplayName
}
else {
    for ($i = 1; $i -le $locations.Count; $i++) {"Select $i for $($locations[$i - 1].DisplayName)"}
    Write-Warning "Add '-azure_location' parameter to skip this dialog next time."
    $location_number = Read-Host "Enter your selection"
    $selected_location = $locations[$location_number - 1]
    $azure_location = $selected_location.Location
    $azure_location_full = $selected_location.DisplayName
}
Write-host "Using location '$($azure_location_full)'" -ForegroundColor DarkGray

#Get or create resource group
Write-host "`nGetting or creating Azure resource group..." -ForegroundColor Cyan
$rg = Get-AzResourceGroup -Name $azure_resource_group_name -ErrorAction Ignore
if (-not $rg) {
    $rg = New-AzResourceGroup -Name $azure_resource_group_name -Location $azure_location
}
elseif ($rg.Location -ne $azure_location) {
    Write-Warning "Resource group $($azure_resource_group_name) exists in location $($rg.Location) which is different from the location you chose ($($azure_location))"
    $changelocation = Read-Host "Enter 1 to use $($rg.Location) location or 2 to delete resource group $($azure_resource_group_name) in $($rg.Location) and re-create it in $($azure_location)"
    if ($changelocation -eq 1) {
        $azure_location = $rg.Location
        $azure_location_full = ($locations | ? {$_.Location -eq $rg.Location}).DisplayName
    }
    elseif ($changelocation -eq 2) {
        $recreate = Read-Host "Please type '$($azure_resource_group_name)' if you are sure to delete the resource group $($azure_resource_group_name) with all nested resources"
        if ($recreate -eq $azure_resource_group_name){
            Remove-AzResourceGroup -Name $azure_resource_group_name -Force | Out-Null
            $rg = New-AzResourceGroup -Name $azure_resource_group_name -Location $azure_location
        }
        else {
            Write-Warning "Please consider whether you need to change a location or re-create a resource group and start over. ALternatively, you can use 'azure_prefix' script parameter to form alternative resource group name."
            return
        }
    }
    else {
        Write-Warning "Invalid input. Enter either 1 or 2."
        return
    }
 }
 Write-host "Using resource group '$($azure_resource_group_name)' in location '$($azure_location_full)'" -ForegroundColor DarkGray

#Select VM size
Write-host "`nSelecting VM size..." -ForegroundColor Cyan
if (-not $azure_vm_size) {
    $vmsizes = Get-AzVMSize -Location $azure_location
    Write-Warning "Please use VM size which supports Premium storage (at least DS-series!)"
    for ($i = 1; $i -le $vmsizes.Count; $i++) {"Select $i for $($vmsizes[$i - 1].Name)"}
    Write-Warning "Please use VM size which supports Premium storage (at least DS-series!)"
    Write-Warning "Add '-azure_vm_size' parameter to skip this dialog next time."
    $location_number = Read-Host "Enter your selection"
    $selected_vmsize = $vmsizes[$location_number - 1]
    $azure_vm_size = $selected_vmsize.Name
}
Write-host "Using VM size '$($azure_vm_size)'" -ForegroundColor DarkGray

#Get or create storage accounts
Write-host "`nGetting or creating Azure storage accounts..." -ForegroundColor Cyan
function CreateStorageAccount ($azure_storage_account_name, $sku_name) {
$sa = Get-AzStorageAccount -Name $azure_storage_account_name -ResourceGroupName $azure_resource_group_name -ErrorAction Ignore
if (-not $sa) {
    $sacreatecount = 0
    try {
        $sacreatecount++
        $sa = New-AzStorageAccount -Name $azure_storage_account_name -ResourceGroupName $azure_resource_group_name -Location $azure_location -SkuName $sku_name  -Kind Storage
    }
    catch {
        if ($sacreatecount -ge 3) {
            Write-Warning "Unable to create storage account '$($azure_storage_account_name)'. Error: $($error[0].Exception.Message)"
            return
        }
    }
}
Write-host "Using storage account '$($azure_storage_account_name)' (SKU: $($sku_name))" -ForegroundColor DarkGray
}
CreateStorageAccount -azure_storage_account_name $azure_storage_account -sku_name Premium_LRS
CreateStorageAccount -azure_storage_account_name $azure_storage_account_cache -sku_name Standard_LRS
CreateStorageAccount -azure_storage_account_name $azure_storage_account_artifacts -sku_name Standard_LRS

#Get or create vnet
Write-host "`nGetting or creating Azure virtual network..." -ForegroundColor Cyan
$vnet = Get-AzVirtualNetwork -Name $azure_vnet_name -ResourceGroupName $azure_resource_group_name -ErrorAction Ignore
if (-not $vnet) {
    $subnet = New-AzVirtualNetworkSubnetConfig -Name $azure_subnet_name -AddressPrefix '10.0.0.0/24'
    $vnet = New-AzVirtualNetwork -Name $azure_vnet_name -ResourceGroupName $azure_resource_group_name -Location $azure_location -AddressPrefix "10.0.0.0/24" -Subnet $subnet
}
elseif (-not $vnet.Subnets -or $vnet.Subnets.Count -eq 0) {
    Write-Warning "Existing virtual network '$($azure_vnet_name)' does not have any subnet defined"
    return
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
    $nsg = New-AzNetworkSecurityGroup -Name $azure_nsg_name -ResourceGroupName $azure_resource_group_name -Location $azure_location
}
Write-host "Using virtual network '$($azure_nsg_name)'" -ForegroundColor DarkGray

#Run Packer to create an image
if (-not $vhd_full_path) {
    Write-host "`nRunning Packer to create a basic build VM image..." -ForegroundColor Cyan
    Write-Warning "Add '-vhd_full_path' parameter with VHD URL value if you want to reuse existing VHD (which must be in '$($azure_storage_account)' storage account). Enter Ctrl-C to stop the script and restart with '-vhd_full_path' parameter or do nothing and let the script create a new VHD.`nWaiting 30 seconds..."
    for ($i = 30; $i -ge 0; $i--) {sleep 1; Write-Host "." -NoNewline}
    Write-Host "`n`nPacker progress:`n"
    $date_mark=Get-Date -UFormat "%Y%m%d%H%M%S"
    & packer build '--only=azure-arm' `
    -var "azure_subscription_id=$azure_subscription_id" `
    -var "azure_tenant_id=$azure_tenant_id" `
    -var "azure_client_id=$azure_client_id" `
    -var "azure_client_secret=$azure_client_secret" `
    -var "azure_location=$azure_location" `
    -var "azure_resource_group_name=$azure_resource_group_name" `
    -var "azure_storage_account=$azure_storage_account" `
    -var "install_password=$install_password" `
    -var "install_user=$install_user" `
    -var "azure_vm_size=$azure_vm_size" `
    -var "build_agent_mode=Azure" `
    -var "image_description=$image_description" `
    -var "datemark=$date_mark" `
    -var "packer_manifest=$packer_manifest" `
    $packer_template

    #Get VHD path
    if (-not (test-path ".\$($packer_manifest)")) {
        Write-Warning "Unable to find .\$($packer_manifest). Please ensure Packer job finsihed successfully."
        return
    }
    Write-host "`nGetting VHD path..." -ForegroundColor Cyan
    $manifest = Get-Content -Path ".\$($packer_manifest)" | ConvertFrom-Json
    $vhd_full_path = $manifest.builds[0].artifact_id
    $vhd_path = $vhd_full_path.Replace("https://$($azure_storage_account).blob.core.windows.net/", "")
    Remove-Item ".\$($packer_manifest)" -Force -ErrorAction Ignore
    Write-host "Build image VHD created by Packer and available at '$($vhd_full_path)'" -ForegroundColor DarkGray
    Write-Host "Default build VM credentials: User: 'appveyor', Password: '$($install_password)'. Normally you do not need this password as it will be reset to a random string when the build starts. However you can use it if you need to create and update a VM from the Packer-created VHD manually"  -ForegroundColor DarkGray
}
else {
    Write-host "Using VHD path '$($vhd_full_path)'" -ForegroundColor DarkGray
    $vhd_path = $vhd_full_path.Replace("https://$($azure_storage_account).blob.core.windows.net/", "")
    $storagekey = (Get-AzStorageAccountKey -ResourceGroupName $azure_resource_group_name -Name $azure_storage_account)[0].Value
    $storagecontext =  New-AzStorageContext -StorageAccountName $azure_storage_account -StorageAccountKey $storagekey
    $storagecontainername = $vhd_path.Substring(0, $vhd_path.IndexOf("/"))
    $storageblobname = $vhd_path.Substring($vhd_path.IndexOf("/") + 1)
    $storageblob = Get-AzStorageBlob -Context $storagecontext -Container $storagecontainername -Blob $storageblobname -ErrorAction Ignore
    if (-not $storageblob) {
        Write-Warning "Unable to find storage blob '$($storageblobname)' in container '$($storagecontainername)', storage account '$($azure_storage_account)'"
        return
    }
}

#Create or update build cache storage settings
Write-host "`nCreating or updating build cache storage settings on AppVeyor..." -ForegroundColor Cyan
$storagekeycache = (Get-AzStorageAccountKey -ResourceGroupName $azure_resource_group_name -Name $azure_storage_account_cache)[0].Value
$buildcaches = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches" -Headers $headers -Method Get
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
    Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
    Write-host "AppVeyor build cache storage '$($azure_cache_storage_name)' has been created." -ForegroundColor DarkGray
}
else {
    $settings = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches/$($buildcache.buildCacheId)" -Headers $headers -Method Get
    $settings.name = $azure_cache_storage_name
    $settings.cacheType = "Azure"
    $settings.settings.accountName = $azure_storage_account_cache
    $settings.settings.accountAccessKey = $storagekeycache
    $jsonBody = $settings | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches"-Headers $headers -Body $jsonBody -Method Put | Out-Null
    Write-host "AppVeyor build cache storage '$($azure_cache_storage_name)' has been updated." -ForegroundColor DarkGray
}

#Create or update artifacts storage settings
Write-host "`nCreating or updating artifacts storage settings on AppVeyor..." -ForegroundColor Cyan
$storagekeyartifacts = (Get-AzStorageAccountKey -ResourceGroupName $azure_resource_group_name -Name $azure_storage_account_artifacts)[0].Value
$artifactstorages = Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages" -Headers $headers -Method Get
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
    Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
    Write-host "AppVeyor artifacts storage '$($azure_artifact_storage_name)' has been created." -ForegroundColor DarkGray
}
else {
    $settings = Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages/$($artifactstorage.artifactStorageId)" -Headers $headers -Method Get
    $settings.name = $azure_artifact_storage_name
    $settings.storageType = "Azure"
    $settings.settings.accountName = $azure_storage_account_artifacts
    $settings.settings.accountAccessKey = $storagekeyartifacts
    $jsonBody = $settings | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages"-Headers $headers -Body $jsonBody -Method Put | Out-Null
    Write-host "AppVeyor artifacts storage '$($azure_artifact_storage_name)' has been updated." -ForegroundColor DarkGray
}

#Create or update cloud
Write-host "`nCreating or updating build environment on AppVeyor..." -ForegroundColor Cyan
$clouds = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds" -Headers $headers -Method Get
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
                    location = $azure_location
                    vmSize = $azure_vm_size
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
                        name = $image_description
                        vhdPathOrImage = $vhd_path
                    })
            }
        }
    }

    $jsonBody = $body | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
    $clouds = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds" -Headers $headers -Method Get
    $cloud = $clouds | ? ({$_.name -eq $build_cloud_name})[0]
    Write-host "AppVeyor build environment '$($build_cloud_name)' has been created." -ForegroundColor DarkGray
}
else {
    $settings = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds/$($cloud.buildCloudId)" -Headers $headers -Method Get
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
    $settings.settings.cloudSettings.vmConfiguration.location = $azure_location
    $settings.settings.cloudSettings.vmConfiguration.vmSize = $azure_vm_size
    $settings.settings.cloudSettings.vmConfiguration.diskStorageAccountName = $azure_storage_account
    $settings.settings.cloudSettings.vmConfiguration.diskStorageContainer = $azure_storage_container
    $settings.settings.cloudSettings.vmConfiguration.vmResourceGroup = $azure_resource_group_name
    $settings.settings.cloudSettings.networking.assignPublicIPAddress = $true
    $settings.settings.cloudSettings.networking.placeBehindAzureLoadBalancer = $false
    $settings.settings.cloudSettings.networking.virtualNetworkName = $azure_vnet_name
    $settings.settings.cloudSettings.networking.subnetName = $azure_subnet_name
    $settings.settings.cloudSettings.networking.securityGroupName = $azure_nsg_name
    $settings.settings.cloudSettings.images[0].name = $image_description
    $settings.settings.cloudSettings.images[0].vhdPathOrImage = $vhd_path

    $jsonBody = $settings | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds"-Headers $headers -Body $jsonBody -Method Put | Out-Null
    Write-host "AppVeyor build environment '$($build_cloud_name)' has been updated." -ForegroundColor DarkGray
}

Write-host "`nEnsuring build worker image is available for AppVeyor projects..." -ForegroundColor Cyan
$images = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-worker-images" -Headers $headers -Method Get
$image = $images | ? ({$_.name -eq $image_description})[0]
if (-not $image) {
    $body = @{
        name = $image_description
        buildCloudName = $build_cloud_name
        osType = "Windows"
    }

    $jsonBody = $body | ConvertTo-Json
    Invoke-RestMethod -Uri "$($appveyor_url)/api/build-worker-images" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
    Write-host "AppVeyor build worker image '$($image_description)' has been created." -ForegroundColor DarkGray
}
else {
    $image.name = $image_description
    $image.buildCloudName = $build_cloud_name
    $image.osType = "Windows"

    $jsonBody = $image | ConvertTo-Json
    Invoke-RestMethod -Uri "$($appveyor_url)/api/build-worker-images" -Headers $headers -Body $jsonBody  -Method Put | Out-Null
    Write-host "AppVeyor build worker image '$($image_description)' has been updated." -ForegroundColor DarkGray
}

$StopWatch.Stop()
if (-not $vhd_full_path) {
    Write-Host "`nCompleted in $($StopWatch.elapsed.minutes) minutes."
}

#Report results and next steps
Write-host "`nNext steps:"  -ForegroundColor Cyan
Write-host " - Optionally review build environment '$($build_cloud_name)' at '$($appveyor_url)/build-clouds/$($cloud.buildCloudId)'" -ForegroundColor DarkGray
Write-host " - To start buling on Azure set '$($image_description)' build worker image in AppVeyor project settings or appveyor.yml." -ForegroundColor DarkGray
