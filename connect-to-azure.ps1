[CmdletBinding()]
param
(
  [Parameter(Mandatory=$true)]
  [string]$appveyor_api_key,

  [Parameter(Mandatory=$false)]
  [string]$azure_prefix,  

  [Parameter(Mandatory=$false)]
  [string]$appveyor_url = "https://ci.appveyor.com",

  [Parameter(Mandatory=$false)]
  [string]$image_description = "Windows Server 2019 on Azure",

  [Parameter(Mandatory=$false)]
  [string]$packer_template = ".\minimal-windows-server-2019.json",

  [Parameter(Mandatory=$false)]
  [string]$install_password  
)

$ErrorActionPreference = "Stop";

if (-not $azure_prefix) {
    $azure_prefix = "appveyor"
}

$azure_service_principal_name = "$($azure_prefix)-sp"
$azure_resource_group_name = "$($azure_prefix)-rg"
$azure_storage_account = "$($azure_prefix)sa"
$azure_storage_container = "$($azure_prefix)-vms"
$azure_vnet_name = "$($azure_prefix)-vnet"
$azure_subnet_name = "$($azure_prefix)-subnet"
$azure_nsg_name = "$($azure_prefix)-nsg"
$build_cloud_name = "$($azure_prefix)-build-environment"

#TODO: hard-code or parametrize?
$install_user = "appveyor"

#Sanitize input
$appveyor_url = $appveyor_url.TrimEnd("/")

#Validate input
if ($appveyor_api_key -like "v2.*") {
    Write-Warning "Please select the API Key for specific account (not 'All Accounts') at https://ci.appveyor.com/api-keys"
    return
}

if ((Invoke-WebRequest -Uri $appveyor_url -ErrorAction SilentlyContinue).StatusCode -ne 200) {
    Write-warning "AppVeyor did not respond successfully on address $($appveyor_url)"
    return
}

if (-not (test-path $packer_template)) {
    Write-Warning "Please provide correct relative path as the packer_template parameter"
    return
}

#Validate that $appveyor_api_key can call $appveyor_url based API

#TODO VALIDATE IF PBC ENABLED

#TODO regex from prod code -- validate build_cloud_name

#Validate that Az module is installed (and maybe AzureRm is not)

#Validate that packer is installed


#Generate install_password (TODO ensure works on Linux)
if (-not $install_password) {
    Add-Type -AssemblyName System.Web
    $install_password = [System.Web.Security.Membership]::GeneratePassword(12, 4)
}

#Login to Azure and select subscription
Write-host "Selecting Azure User and subscription..." -ForegroundColor Cyan
$contenxt = Get-AzContext
if (-not $contenxt) {
    Login-AzAccount | Out-Null
}
else {
    Write-host "You are currently logged to Azure as $($contenxt.Account)"
    $relogin = Read-Host "Enter 1 if you want continue or 2 to re-login to Azure"
    if ($relogin -eq 1) {Write-host "Deploying as $($contenxt.Account)" -ForegroundColor DarkGray}
    elseif ($relogin -eq 2) {Login-AzAccount | Out-Null}
    else {
        Write-Warning "Invalid input. Enter either 1 or 2."
        return
    }
}

$subs = Get-AzSubscription
$subs = $subs | ? {$_.State -eq "Enabled"}
if (-not $subs -or $subs.Count -eq 0) {
    Write-Warning "No Azure subscriptions enabled"
    return
}
if ($subs.Count -gt 1) {
    Write-host "There are more than one enabled subscription under your account"
    for ($i = 1; $i -le $subs.Count; $i++) {"Select $i for $($subs[$i - 1].name)"}
    $subscription_number = Read-Host "Enter your selection"
    $selected_subscription = $subs[$subscription_number - 1]
    Write-host "Using subsciption $($selected_subscription.name)" -ForegroundColor DarkGray
    Set-AzContext -SubscriptionId $selected_subscription.Id | Out-Null
    $azure_subscription_id = $selected_subscription.Id
    $azure_tenant_id = $selected_subscription.TenantId
}
else {
    Write-host "Using subsciption $($subs[0].name)" -ForegroundColor DarkGray
    Set-AzContext -SubscriptionId $subs[0].Id | Out-Null
    $azure_subscription_id = $subs[0].Id
    $azure_tenant_id = $subs[0].TenantId
}

#Get or create service principal
Write-host "`nGetting or creating Azure AD service principal..." -ForegroundColor Cyan
$sp = Get-AzADServicePrincipal -DisplayName $azure_service_principal_name
$app = Get-AzADApplication -DisplayName $azure_service_principal_name
if (-not $sp -and $app) {
    Write-Warning "Service principal $($azure_service_principal_name) does not exist, but Azure AD application with the same name already exist." 
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
Write-host "Using Azure AD service principal $($azure_service_principal_name)" -ForegroundColor DarkGray

#Select location
Write-host "`nSelecting location..." -ForegroundColor Cyan
$locations = Get-AzLocation
for ($i = 1; $i -le $locations.Count; $i++) {"Select $i for $($locations[$i - 1].DisplayName)"}
$location_number = Read-Host "Enter your selection"
$selected_location = $locations[$location_number - 1]
Write-host "Using location $($selected_location.DisplayName)" -ForegroundColor DarkGray
$azure_location = $selected_location.Location
$azure_location_full = $selected_location.DisplayName

#Get or create resource group
Write-host "`nGetting or creating Azure resource group..." -ForegroundColor Cyan
$rg = Get-AzResourceGroup -Name $azure_resource_group_name -ErrorAction Ignore
if (-not $rg) {
    $rg = New-AzResourceGroup -Name $azure_resource_group_name -Location $azure_location
}
elseif ($rg.Location -ne $azure_location) {
    Write-Warning "Resource group $($azure_resource_group_name) exists in location $($rg.Location) which is different from the location you choose ($($azure_location))"
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
            Write-Warning "Please consider if you need to change a location or re-create a resource group and start over. ALternatively you can use 'azure_prefix' script parameter to form alternative resource group name."
            return        
        }
    }
    else {
        Write-Warning "Invalid input. Enter either 1 or 2."
        return
    }
 }
 Write-host "Using resource group $($azure_resource_group_name) in location $($azure_location_full)" -ForegroundColor DarkGray

#Select VM size
Write-host "`nSelecting VM size..." -ForegroundColor Cyan
$vmsizes = Get-AzVMSize -Location $azure_location
for ($i = 1; $i -le $vmsizes.Count; $i++) {"Select $i for $($vmsizes[$i - 1].Name)"}
$location_number = Read-Host "Enter your selection"
$selected_vmsize = $vmsizes[$location_number - 1]
Write-host "Using VM size $($selected_vmsize.Name)" -ForegroundColor DarkGray
$azure_vm_size = $selected_vmsize.Name

#Get or create storage account
Write-host "`nGetting or creating Azure storage account..." -ForegroundColor Cyan
$sa = Get-AzStorageAccount -Name $azure_storage_account -ResourceGroupName $azure_resource_group_name -ErrorAction Ignore
if (-not $rg) {
    $sa = New-AzStorageAccount -Name $azure_storage_account -ResourceGroupName $azure_resource_group_name -Location $azure_location -SkuName Standard_LRS  -Kind Storage
}
Write-host "Using storage account $($azure_storage_account)" -ForegroundColor DarkGray

#Get or create vnet
Write-host "`nGetting or creating Azure virtual network..." -ForegroundColor Cyan
$vnet = Get-AzVirtualNetwork -Name $azure_vnet_name -ResourceGroupName $azure_resource_group_name -ErrorAction Ignore
if (-not $rg) {
    $vnet = New-AzVirtualNetwork -Name $azure_vnet_name -ResourceGroupName $azure_resource_group_name -Subnet $azure_subnet_name
}
Write-host "Using virtual network $($azure_vnet_name) and subnet $($azure_subnet_name)" -ForegroundColor DarkGray

#Get or create nsg
Write-host "`nGetting or creating Azure network security group..." -ForegroundColor Cyan
$nsg = Get-AzNetworkSecurityGroup -Name $azure_nsg_name -ResourceGroupName $azure_resource_group_name -ErrorAction Ignore
if (-not $rg) {
    $nsg = New-AzNetworkSecurityGroup -Name $azure_nsg_name -ResourceGroupName $azure_resource_group_name -Location $azure_location
}
Write-host "Using virtual network $($azure_nsg_name)" -ForegroundColor DarkGray


#Run packet to create an image
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
$packer_template



Write-warning "debug return"; return

#Rollback -- delete Azure entites
#Remove-AzureRmResourceGroup -Name $azure_resource_group_name -Verbose -Force

#Create or update cloud
$headers = @{
  "Authorization" = "Bearer $appveyor_api_key"
  "Content-type" = "application/json"
}
$body = @{
    name = $build_cloud_name
    cloudType = "Azure"
    workersCapacity = 20
    settings = @{
        artifactStorageName = $null
        buildCacheName = $null
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
                    vhdPathOrImage = "foo/bar" #TODO Read from the packer output
                })
        }
    }
}

$jsonBody = $body | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds" -Headers $headers -Body $jsonBody  -Method Post

#Report results and next steps
Write-Host "Default build VM credentials: `nUser: 'appveyor', Password: '$($)' (will be reset to the random when build starts.)"