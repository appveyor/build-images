<#
.SYNOPSIS
    Script to enable GCE builds. Works with both hosted AppVeyor and AppVeyor server.

.DESCRIPTION
    You can connect your AppVeyor account (on both hosted AppVeyor and on-premise AppVeyor Server) to your own GCE account for AppVeyor to instantiate build VMs in it. There are several benefits like having the ability to customize your build image, select desired VM size, set custom build timeout and many others. To simplify the setup process for you, we created a script which provisions necessary GCE and GCS resources, runs Hashicorp Packer to create a basic build image, and puts all the AppVeyor configuration together. After running this script, you should be able to start builds on GCE immediately (and optionally customize your GCE build environment later).

.PARAMETER appveyor_api_key
    API key for specific account (not 'All accounts'). Hosted AppVeyor users can find it at https://ci.appveyor.com/api-keys. Appveyor Server users can find it at <appveyor_server_url>/api-keys.

.PARAMETER appveyor_url
    AppVeyor URL. For hosted AppVeyor it is https://ci.appveyor.com. For Appveyor Server users it is URL of on-premise AppVeyor Server installation

.PARAMETER skip_disclaimer
    Skip warning related to GCE resources creation and potential charges. It is recommended to read the warning at least once, but it can come handy if you need to re-run the script.

.PARAMETER use_current_gcloud_config
    Use current active Google cloud config, so script will use current Google account and create resources in the Google Cloud project set in the current config.

.PARAMETER gce_zone
    Google cloud zone, e.g. 'us-east1-b'

.PARAMETER gce_machine_type
    Type of GCE machine, e.g. 'n1-standard-1'

.PARAMETER gce_image_name
    It may be that you run the script, and it creates a valid VM snapshot, but some AppVeyor settings are not set correctly (or you may just want to change them without doing it in the AppVeyor build environments UI). In this case you want to skip the most time consuming step (creating a snapshot with Packer) and pass the existing snapshot to this parameter.

.PARAMETER common_prefix
    Script will prepend all created GCE resources and AppVeyor build environment name with it. Because of storage account names restrictions, is must contain only letters and numbers and be shorter than 16 symbols. Default value is 'appveyor'.

.PARAMETER image_os
    Operating system of build VM image. Valid values: 'Windows', 'Linux'. Default value is 'Windows'.

.PARAMETER image_description
    Description to be passed to Packer and name to be used for AppVeyor image.  Default value generated is based on the value of 'image_os' parameter.

.PARAMETER packer_template
    If you are familiar with Hashicorp Packer, you can replace template used by this script with another one.  Default value generated is based on the value of 'image_os' parameter.

    .EXAMPLE
    .\connect-to-gce.ps1
    Let script collect all required information

    .EXAMPLE
    .\connect-to-gce.ps1 -appveyor_api_key XXXXXXXXXXXXXXXXXXXXX -appveyor_url https://ci.appveyor.com -skip_disclaimer -gce_zone us-east1-b -gce_machine_type n1-standard-1
    Script will create resources us-east1-b zone, and will connect it to hosted AppVeyor. Machine type n1-standard-1 will be used for both Packer and AppVeyor builds.
#>

[CmdletBinding()]
param
(
  [Parameter(Mandatory=$true,HelpMessage="API key for specific account (not 'All accounts')`nHosted AppVeyor users can find it at https://ci.appveyor.com/api-keys`nAppveyor Server users can find it at <appveyor_server_url>/api-keys")]
  [string]$appveyor_api_key,

  [Parameter(Mandatory=$true,HelpMessage="AppVeyor URL`nFor hosted AppVeyor it is https://ci.appveyor.com`nFor Appveyor Server users it is URL of on-premise AppVeyor Server installation")]
  [string]$appveyor_url,

  [Parameter(Mandatory=$false)]
  [switch]$skip_disclaimer,

  [Parameter(Mandatory=$false)]
  [switch]$use_current_gcloud_config,

  [Parameter(Mandatory=$false)]
  [string]$gce_zone,

  [Parameter(Mandatory=$false)]
  [string]$gce_machine_type,

  [Parameter(Mandatory=$false)]
  [string]$gce_image_name,

  [Parameter(Mandatory=$false)]
  [string]$common_prefix = "appveyor",

  [Parameter(Mandatory=$false)]
  [ValidateSet('Windows','Linux')]
  [string]$image_os = "Windows",

  [Parameter(Mandatory=$false)]
  [string]$image_description,

  [Parameter(Mandatory=$false)]
  [string]$packer_template
)

function Exit-Script {
    #TODO cleanup if needed
    exit 1
}

$ErrorActionPreference = "Stop"

$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()

#Sanitize input
$appveyor_url = $appveyor_url.TrimEnd("/")

#Validate input
if ($appveyor_api_key -like "v2.*") {
    Write-Warning "Please select the API Key for specific account (not 'All Accounts') at '$($appveyor_url)/api-keys'"
    Exit-Script
}

try {
    $responce = Invoke-WebRequest -Uri $appveyor_url -ErrorAction SilentlyContinue
    if ($responce.StatusCode -ne 200) {
        Write-warning "AppVeyor URL '$($appveyor_url)' responded with code $($responce.StatusCode)"
        Exit-Script
    }
}
catch {
    Write-warning "Unable to connect to AppVeyor URL '$($appveyor_url)'. Error: $($error[0].Exception.Message)"
    Exit-Script
}

if (-not (Get-Command gcloud -ErrorAction Ignore)) {
    Write-Warning "This script depends on Google Cloud SDK. Use 'choco install gcloudsdk' on Windows, for Linux follow https://cloud.google.com/sdk/docs/quickstart-linux, for Mac: https://cloud.google.com/sdk/docs/quickstart-macos"
    Exit-Script
}

#TODO remove if GoogleCloud does not appear to be needed (if al canbe done with gcloud)
if (-not (Get-Module -Name GoogleCloud -ListAvailable)) {
    Write-Warning "This script depends on Google Cloud PowerShell module. Please install them with the following command: 'Install-Module -Name GoogleCloud -Force; Import-Module -Name GoogleCloud"
    Exit-Script
}
#Import module anyway, to be sure.
Import-Module -Name GoogleCloud

if (-not (Get-Command packer -ErrorAction Ignore)) {
    Write-Warning "This script depends on Packer by HashiCorp. Please install it with 'choco install packer' ('apt get packer' for Linux) command or follow https://www.packer.io/intro/getting-started/install.html. If it is already installed, please ensure that PATH environment variable contains path to it."
    Exit-Script
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
    Exit-Script
}

if ($appveyor_url -eq "https://ci.appveyor.com") {
      try {
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds" -Headers $headers -Method Get | Out-Null
    }
    catch {
        Write-warning "Please contact support@appveyor.com and request enabling of 'Private build clouds' feature."
        Exit-Script
    }
}

$regex =[regex] "^([A-Za-z0-9]+)$"
if (-not $regex.Match($common_prefix).Success) {
    Write-Warning "'common_prefix' can contain only letters and numbers"
    Exit-Script
}

# restriction need to use in bucket name (https://cloud.google.com/storage/docs/naming)
if (($common_prefix -like "goog*") -or ($common_prefix -like "*google*") -or ($common_prefix -like "*g00gle*")) {
    Write-Warning "'common_prefix' cannot begin with the 'goog' prefix and cannot contain 'google' or close misspellings, such as 'g00gle'"
    Exit-Script
}

#"artifact" is longest name postfix. 
#63 is GCS bucket name limit
#5 is minumum lenght of infix to be unique
$maxtotallength = 63
$mininfix = 5
$maxpostfix = "artifact".Length
$maxprefix = $maxtotallength - $maxpostfix - $mininfix
if ($common_prefix.Length -ge  $maxprefix){
     Write-warning "Length of 'common_prefix' must be under $($maxprefix)"
     Exit-Script
}

#Make GCS bucket names globally unique
$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = new-object -TypeName System.Text.UTF8Encoding
$apikeyhash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($appveyor_api_key)))
$infix = $apikeyhash.Replace("-", "").ToLower()
$maxinfix = ($maxtotallength - $common_prefix.Length - $maxpostfix)
if ($infix.Length -gt $maxinfix){$infix = $infix.Substring(0, $maxinfix)}

$gcs_storage_bucket_cache = "$($common_prefix)$($infix)cache".ToLower()
$gcs_storage_bucket_artifacts = "$($common_prefix)$($infix)artifact".ToLower()

$gcs_cache_storage_name = "$($common_prefix)-gcs-cache"
$gcs_artifact_storage_name = "$($common_prefix)-gcs-artifacts"

$build_cloud_name = "$($image_os)-GCE-build-environment"
$image_description = if ($image_description) {$image_description} else {"$($image_os) on GCE"}
$packer_template = if ($packer_template) {$packer_template} elseif ($image_os -eq "Windows") {"./minimal-windows-server.json"} elseif ($image_os -eq "Linux") {"./minimal-ubuntu.json"}

$packer_manifest = "packer-manifest.json"
$install_user = "appveyor"
$install_password = "ABC" + (New-Guid).ToString().SubString(0, 12).Replace("-", "") + "!"

$gce_network_name = "$($common_prefix)-network"
$gce_firewall_name = "$($common_prefix)-firewall"
$gce_firewall_winrm__name = "$($common_prefix)-firewall-winrm"
$gce_firewall_winrm__port = 5986
$gce_service_account = "$($common_prefix)-sa"
$gce_account_file = if ($env:HOME) {"$env:HOME/$($common_prefix)-account-file.json"} elseif ($env:HOMEPATH) {"$env:HOMEPATH\$($common_prefix)-account-file.json"}
$gce_account_certificate_file = if ($env:HOME) {"$env:HOME/$($common_prefix)-account-certificate.p12"} elseif ($env:HOMEPATH) {"$env:HOMEPATH\$($common_prefix)-account-certificate.p12"}

if (-not $skip_disclaimer) {
     Write-Warning "`nThis script will create GCE resources such as network and service account, as well as GCS buckets. Also, it will run Hashicorp Packer which will create its own temporary GCE resources and c reate a VM image for future use by AppVeyor build VMs. Please be aware of possible charges from Google. `nIf GCE project you are authorized to contains production resources, you might consider creating a separate project or even account and run this script against it. Additionally, a separate account is better to distinguish Google bills for CI machines from other Google bills. `nPress Enter to continue or Ctrl-C to exit the script. Use '-skip_disclaimer' switch parameter to skip this message next time."
     $disclaimer = Read-Host
     }

try {

    Write-host "`nSelecting Google cloud project..." -ForegroundColor Cyan
    function SelectGGloudConfig() {
        $gcloudconfigs = gcloud config configurations list --format=json | ConvertFrom-Json
        $script:activeconfig = $gcloudconfigs | ? {$_.IS_ACTIVE -eq $true}
        if (-not $activeconfig) {
            Write-Warning "Unable to find active Google Cloud configuration, lets re-initialize Google cloud settings"
            gcloud init
            SelectGGloudConfig
        }
        if (-not $activeconfig.properties.core.project) {
            Write-Warning "Google Cloud configuration project is not set, lets re-initialize Google cloud settings"
            gcloud init
            SelectGGloudConfig
        }

        elseif (-not $use_current_gcloud_config) {
            Write-host "You are currently logged in to Google as '$($activeconfig.properties.core.account)', project '$($activeconfig.properties.core.project)'"
            Write-Warning "Add '-use_current_gcloud_config' switch parameter to use current Google Cloud config and skip this dialog next time."
            $relogin = Read-Host "Enter 1 if you want continue or 2 to re-initialize Google cloud settings"
            if ($relogin -eq 1) {
                Write-host "Using Google account '$($activeconfig.properties.core.account)', project '$($activeconfig.properties.core.project)'" -ForegroundColor DarkGray
            }
            elseif ($relogin -eq 2) {
                gcloud init
                SelectGGloudConfig
            }
            else {
                Write-Warning "Invalid input. Enter either 1 or 2."
                Exit-Script
            }
        }
        else {
            Write-host "Using Google account '$($activeconfig.properties.core.account)', project '$($activeconfig.properties.core.project)'" -ForegroundColor DarkGray
        }
    }
    SelectGGloudConfig

    Write-host "`nChecking if GCE API is enabled and enabling it if not..." -ForegroundColor Cyan
    function GcloudApiEnabled() {
        if ((gcloud services list --format=json | ConvertFrom-Json) | ? {$_.config.Name -eq "compute.googleapis.com"}) {
            return $true
        }
        return $false
    }
    if (-not (GcloudApiEnabled)) {
        gcloud services enable "compute.googleapis.com"
    }
    if (-not (GcloudApiEnabled)) {
        Write-Warning "Cannot enable GCE API"
        Exit-Script
    }
    Write-host "GCE API is enabled" -ForegroundColor DarkGray

    #Select GCE zone
    Write-host "`nSelecting GCE zone..." -ForegroundColor Cyan
    if (-not $gce_zone) {
        Write-Warning "Add '-gce_zone' parameter to skip this dialog next time"
        if ($activeconfig.properties.compute.zone) {
            Write-Host "You current Google Cloud zone is '$($activeconfig.properties.compute.zone)'"
            $usedefaultzone = Read-Host "Enter 1 if you want continue or 2 to select another zone"
            if ($usedefaultzone -eq 1) {
                $gce_zone = $activeconfig.properties.compute.zone
            }
            elseif ($usedefaultzone -ne 2) {
                Write-Warning "Invalid input. Enter either 1 or 2."
                Exit-Script
            }
        }
        if ((-not $activeconfig.properties.compute.zone) -or ($usedefaultzone -eq 2)) {
            $gcezones = gcloud compute zones list --format=json | ConvertFrom-Json
            for ($i = 1; $i -le $gcezones.Count; $i++) {"Select $i for $($gcezones[$i - 1].Name)"}
            $zone_number = Read-Host "Enter your selection"
            if (-not $zone_number) {
                Write-Warning "No GCE zone selected."
                Exit-Script
            }
            $selected_zone = $gcezones[$zone_number - 1]
            $gce_zone = $selected_zone.Name
        }
    }
    Write-host "Using GCE zone '$($gce_zone)'" -ForegroundColor DarkGray

    Write-host "`nGetting or creating GCE network..." -ForegroundColor Cyan
    function GcloudNetworkExtst() {
        if ((gcloud compute networks list --format=json | ConvertFrom-Json) | ? {$_.Name -eq $gce_network_name}) {
            return $true
        }
        return $false
    }
    if (-not (GcloudNetworkExtst)) {
        $ErrorActionPreference = "Stop"
        gcloud compute networks create $gce_network_name
    }
    if (-not (GcloudNetworkExtst)) {
        Write-Warning "Unable to get or create GCE network $($gce_network_name)"
        Exit-Script
    }
    Write-host "Using GCE network '$($gce_network_name)'" -ForegroundColor DarkGray

    $remoteaccessport = if ($image_os -eq "Windows") {3389} elseif ($image_os -eq "Linux") {22}
    $remoteaccessname = if ($image_os -eq "Windows") {"RDP"} elseif ($image_os -eq "Linux") {"SSH"}
    Write-host "`nAllowing $($remoteaccessname) access to build VMs..." -ForegroundColor Cyan
    function GcloudFirewallAndRuleExtst($name, $port) {
        if ((gcloud compute firewall-rules list --format json | ConvertFrom-Json) | ? {($_.name -eq $name) `
        -and ($_.allowed | ? ({($_.IPProtocol -eq "tcp") -and ($_.ports | ? {$_ -eq $port})})) `
        -and ($_.direction -eq "ingress") `
        -and ($_.disabled -eq $false) `
        }) 
        {
            return $true
        }
        return $false
    }
    if (-not (GcloudFirewallAndRuleExtst -name $gce_firewall_name -port $remoteaccessport)) {
        gcloud compute firewall-rules create $gce_firewall_name --network $gce_network_name --allow tcp:$remoteaccessport
        Write-host "Allowed TCP port $($remoteaccessport) ($($remoteaccessname))" -ForegroundColor DarkGray
    }
    else {Write-host "TCP $($remoteaccessport) ($($remoteaccessname)) already allowed on firewall $($gce_firewall_name), network $($gce_network_name)" -ForegroundColor DarkGray}
    if (-not (GcloudFirewallAndRuleExtst -name $gce_firewall_name -port $remoteaccessport)) {
        Write-Warning "Unable to allow TCP $($remoteaccessport). ($($remoteaccessname) assess to build VMs will not be available. Please update settings for firewall $($gce_firewall_name), network $($gce_network_name) in Google Cloud console if $($remoteaccessname) assess is needed."
    }

    Write-host "`nSelecting GCE machine type..." -ForegroundColor Cyan
    if (-not $gce_machine_type) {
        $machinetypes = Get-GceMachineType -Zone $gce_zone
        if ($image_os -eq "Windows") {Write-Warning "Minimum recommended is 'n1-standard-1'"}
        for ($i = 1; $i -le $machinetypes.Count; $i++) {"Select $i for $($machinetypes[$i - 1].name)    $($machinetypes[$i - 1].description)"}
        if ($image_os -eq "Windows") {Write-Warning "Minimum recommended is 'n1-standard-1'"}
        Write-Warning "Add '-gce_machine_type' parameter to skip this dialog next time."
        $instance_number = Read-Host "Enter your selection"
        if (-not $instance_number) {
            Write-Warning "No GCE machine type selected."
            Exit-Script
        }
        #$selected_instance_type = $machinetypes[$instance_number - 1].name
        $gce_machine_type = $machinetypes[$instance_number - 1].name
    }
    Write-host "Using instance type '$($gce_machine_type)'" -ForegroundColor DarkGray

    #Create GCS bucket for cache storage
    Write-host "`nGetting or creating GCS bucket for cache storage..." -ForegroundColor Cyan
    $bucket = Test-GcsBucket -Name $gcs_storage_bucket_cache
    if (-not $bucket) {
        $bucket = New-GcsBucket -Name $gcs_storage_bucket_cache -Project $activeconfig.properties.core.project
    }
    Write-host "Using GCS bucket '$($gcs_storage_bucket_cache)' for cache storage" -ForegroundColor DarkGray

    #Create gcs bucket for artifacts
    Write-host "`nGetting or creating GCS bucket for artifacts storage..." -ForegroundColor Cyan
    $bucket = Test-GcsBucket -Name $gcs_storage_bucket_artifacts
    if (-not $bucket) {
        $bucket = New-GcsBucket -Name $gcs_storage_bucket_artifacts -Project $activeconfig.properties.core.project
    }
    Write-host "Using GCS bucket '$($gcs_storage_bucket_artifacts)' for artifacts storage" -ForegroundColor DarkGray

    Write-host "`nGetting or creating GCE service account..." -ForegroundColor Cyan
    function GetGcloudSserviceAccount() {
        $retVal = (gcloud iam service-accounts list --format=json | ConvertFrom-Json) | ? {$_.email -eq "$($gce_service_account)@$($activeconfig.properties.core.project).iam.gserviceaccount.com"}
        if ($retVal) {
            return $retVal
        }
        return $null
    }
    if (-not (GetGcloudSserviceAccount)) {
        gcloud iam service-accounts create $gce_service_account --display-name=$gce_service_account

        gcloud projects add-iam-policy-binding $($activeconfig.properties.core.project) `
        --member serviceAccount:$($gce_service_account)@$($activeconfig.properties.core.project).iam.gserviceaccount.com `
        --role roles/compute.instanceAdmin.v1

        gcloud projects add-iam-policy-binding $($activeconfig.properties.core.project) `
        --member serviceAccount:$($gce_service_account)@$($activeconfig.properties.core.project).iam.gserviceaccount.com `
        --role roles/iam.serviceAccountUser
    }
    if (-not (GetGcloudSserviceAccount)) {
        sleep 5
        if (-not (GetGcloudSserviceAccount)) {
            Write-Warning "Unable to get or create GCE service account '$($gce_service_account)'"
            Exit-Script
        }
    }
    Write-host "Using GCE service account '$($gce_service_account)'" -ForegroundColor DarkGray
    $gceserviceaccount = GetGcloudSserviceAccount

    #Run Packer to create an snapshot
    if (-not $gce_image_name) {

        Write-host "`nCreating temporary service account key for Packer..." -ForegroundColor Cyan
        #TODO check is number of keys already used
        $packer_gce_key = $null
        $keysBefore = gcloud iam service-accounts keys list --iam-account=$($gceserviceaccount.email) --format=json | ConvertFrom-Json
        $keycreationoutput = gcloud iam service-accounts keys create $gce_account_file --iam-account=$($gceserviceaccount.email)
        $keysAfter = gcloud iam service-accounts keys list --iam-account=$($gceserviceaccount.email) --format=json | ConvertFrom-Json
        $packer_gce_key = (Compare-Object -ReferenceObject $keysBefore -DifferenceObject $keysAfter -Property name -PassThru).name
        $packer_gce_key = $packer_gce_key.Substring($packer_gce_key.LastIndexOf("/")+1, 40)
        Write-host "Using temporary service account key '$($packer_gce_key)', key file '$($gce_account_file)'" -ForegroundColor DarkGray

        Write-host "`nTemporary allowing TCP $($gce_firewall_winrm__port) (WinRM) for Packer build..." -ForegroundColor Cyan
        if (-not (GcloudFirewallAndRuleExtst -name $gce_firewall_winrm__name -port $gce_firewall_winrm__port)) {
            gcloud compute firewall-rules create $gce_firewall_winrm__name --allow tcp:$gce_firewall_winrm__port
            Write-host "Allowed TCP $($gce_firewall_winrm__port) (WinRM)" -ForegroundColor DarkGray
        }

        Write-host "`nRunning Packer to create a basic build VM snapshot..." -ForegroundColor Cyan
        Write-Warning "Add '-gce_image_name' parameter with if you want to reuse existing snapshot. Enter Ctrl-C to stop the script and restart with '-gce_image_name' parameter or do nothing and let the script create a new snapshot.`nWaiting 30 seconds..."
        for ($i = 30; $i -ge 0; $i--) {sleep 1; Write-Host "." -NoNewline}
        Remove-Item ".\$($packer_manifest)" -Force -ErrorAction Ignore
        Write-Host "`n`nPacker progress:`n"
        $date_mark=Get-Date -UFormat "%Y%m%d%H%M%S"
        & packer build '--only=googlecompute' `
        -var "gce_account_file=$gce_account_file" `
        -var "gce_project=$($activeconfig.properties.core.project)" `
        -var "gce_zone=$gce_zone" `
        -var "gce_machine_type=$gce_machine_type" `
        -var "install_password=$install_password" `
        -var "install_user=$install_user" `
        -var "build_agent_mode=GCE" `
        -var "image_description=$image_description" `
        -var "datemark=$date_mark" `
        -var "packer_manifest=$packer_manifest" `
        $packer_template

        #Get image path
        if (-not (test-path ".\$($packer_manifest)")) {
            Write-Warning "Unable to find .\$($packer_manifest). Please ensure Packer job finsihed successfully."
            Exit-Script
        }
        Write-host "`nGetting image name..." -ForegroundColor Cyan
        $manifest = Get-Content -Path ".\$($packer_manifest)" | ConvertFrom-Json
        $gce_image_name = $manifest.builds[0].artifact_id
        #TODO uncomment
        #Remove-Item ".\$($packer_manifest)" -Force -ErrorAction Ignore
        Write-host "Build image created by Packer: '$($gce_image_name)'" -ForegroundColor DarkGray
        Write-Host "Default build VM credentials: User: 'appveyor', Password: '$($install_password)'. Normally you do not need this password as it will be reset to a random string when the build starts. However you can use it if you need to create and update a VM from the Packer-created VHD manually"  -ForegroundColor DarkGray

        #TODO wrap and use with to cleanup in Exit-Script
        Write-host "`nDeleting temporary firewall $($gce_firewall_winrm__name)..." -ForegroundColor Cyan
        if (GcloudFirewallAndRuleExtst -name $gce_firewall_winrm__name -port $gce_firewall_winrm__port) {
            gcloud compute firewall-rules delete $gce_firewall_winrm__name --quiet
        }
        if (-not (GcloudFirewallAndRuleExtst -name $gce_firewall_winrm__name -port $gce_firewall_winrm__port)) {
            Write-host "Firewall $($gce_firewall_winrm__name) has been deleted" -ForegroundColor DarkGray
        }
        else {
            Write-Warning "Unable to delete firewal rule $($gce_firewall_winrm__name). WinRM port $($gce_firewall_winrm__port) can be accessible from the outside. Please use Google Cloud console to delete this firewall rule if needed."
        }

        Write-host "`nDeleting temporary service account key '$($packer_gce_key)' used for Packer..." -ForegroundColor Cyan
        gcloud iam service-accounts keys delete $packer_gce_key --iam-account=$($gceserviceaccount.email) --quiet

        Write-host "`nDeleting temporary service account key file '$($gce_account_file)' used for Packer..." -ForegroundColor Cyan
        Del $gce_account_file -Force
    }
    else {
        Write-host "`nSkipping image creation with Packer..." -ForegroundColor Cyan
        Write-host "Using exiting image '$($gce_image_name)'" -ForegroundColor DarkGray
    }

    # If either builc cache, artifact storage or cloud does no exist, issue and use new account certificate
    $buildcaches = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches" -Headers $headers -Method Get
    $buildcache = $buildcaches | ? ({$_.name -eq $gcs_cache_storage_name})[0]
    $artifactstorages = Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages" -Headers $headers -Method Get
    $artifactstorage = $artifactstorages | ? ({$_.name -eq $gcs_artifact_storage_name})[0]
    $clouds = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds" -Headers $headers -Method Get
    $cloud = $clouds | ? ({$_.name -eq $build_cloud_name})[0]
    $gce_account_certificate_base64 = $null;
    if ((-not $buildcache) -or (-not $artifactstorage) -or (-not $cloud)) {
        Write-host "`nCreating service account certificate..." -ForegroundColor Cyan
        gcloud iam service-accounts keys create $gce_account_certificate_file --iam-account=$($gceserviceaccount.email) --key-file-type=p12
        $bytes = [System.IO.File]::ReadAllBytes($gce_account_certificate_file)
        $gce_account_certificate_base64 = [System.Convert]::ToBase64String($bytes)        
        if (-not $gce_account_certificate_base64) {
            Write-Warning "Unable to create service account certificate."
            Exit-Script
        }
        Write-host "Service account certificate has been created." -ForegroundColor DarkGray
        Write-host "`nDeleting temporary service account certificate file '$($gce_account_certificate_file)'..." -ForegroundColor Cyan
        Del $gce_account_certificate_file -Force
        Write-host "Service account certificate file has been deleted." -ForegroundColor DarkGray
    }

    #Create or update build cache storage settings
    Write-host "`nCreating or updating build cache storage settings on AppVeyor..." -ForegroundColor Cyan
    if (-not $buildcache) {
        $body = @{
            name = $gcs_cache_storage_name
            cacheType = "Google"
            settings = @{
                serviceAccountEmail = $($gceserviceaccount.email)
                serviceAccountCertificateBase64 = $gce_account_certificate_base64
                bucketName = $gcs_storage_bucket_cache
            }
        }
        $jsonBody = $body | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
        Write-host "AppVeyor build cache storage '$($gcs_cache_storage_name)' has been created." -ForegroundColor DarkGray
    }
    else {
        $settings = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches/$($buildcache.buildCacheId)" -Headers $headers -Method Get
        $settings.name = $gcs_cache_storage_name
        $settings.cacheType = "Google"
        $settings.settings.serviceAccountEmail = $($gceserviceaccount.email)
        if ($gce_account_certificate_base64) {$settings.settings.serviceAccountCertificateBase64 = $gce_account_certificate_base64}
        $settings.settings.bucketName = $gcs_storage_bucket_cache
        $jsonBody = $settings | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches"-Headers $headers -Body $jsonBody -Method Put | Out-Null
        Write-host "AppVeyor build cache storage '$($gcs_cache_storage_name)' has been updated." -ForegroundColor DarkGray
    }

    #Create or update artifacts storage settings
    Write-host "`nCreating or updating artifacts storage settings on AppVeyor..." -ForegroundColor Cyan

    if (-not $artifactstorage) {
        $body = @{
            name = $gcs_artifact_storage_name
            storageType = "Google"
            settings = @{
                serviceAccountEmail = $($gceserviceaccount.email)
                serviceAccountCertificateBase64 = $gce_account_certificate_base64
                bucketName = $gcs_storage_bucket_artifacts
            }
        }
        $jsonBody = $body | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
        Write-host "AppVeyor artifacts storage '$($gcs_artifact_storage_name)' has been created." -ForegroundColor DarkGray
    }
    else {
        $settings = Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages/$($artifactstorage.artifactStorageId)" -Headers $headers -Method Get
        $settings.name = $gcs_artifact_storage_name
        $settings.storageType = "Google"
        $settings.settings.serviceAccountEmail = $($gceserviceaccount.email)
        if ($gce_account_certificate_base64) {$settings.settings.serviceAccountCertificateBase64 = $gce_account_certificate_base64}
        $settings.settings.bucketName = $gcs_storage_bucket_artifacts
        $jsonBody = $settings | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages"-Headers $headers -Body $jsonBody -Method Put | Out-Null
        Write-host "AppVeyor artifacts storage '$($gcs_artifact_storage_name)' has been updated." -ForegroundColor DarkGray
    }

    #Create or update cloud
    Write-host "`nCreating or updating build environment on AppVeyor..." -ForegroundColor Cyan
    if (-not $cloud) {
        $body = @{
            name = $build_cloud_name
            cloudType = "GCE"
            workersCapacity = 20
            settings = @{
                artifactStorageName = $gcs_artifact_storage_name
                buildCacheName = $gcs_cache_storage_name
                failureStrategy = @{
                    jobStartTimeoutSeconds = 300
                    provisioningAttempts = 3
                }
                cloudSettings = @{
                    googleAccount =@{
                        projectName = $($activeconfig.properties.core.project)
                        serviceAccountEmail = $($gceserviceaccount.email)
                        serviceAccountCertificateBase64 = $gce_account_certificate_base64
                    }
                    vmConfiguration = @{
                        zoneName = $gce_zone
                        sizeName = $gce_machine_type
                    }
                    networking = @{
                        assignExternalIP = $true
                        networkName = $gce_network_name
                        }
                    images = @(@{
                            name = $image_description
                            snapshotOrImage = $gce_image_name
                            sizeGB = 200
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
        $settings.cloudType = "GCE"
        $settings.workersCapacity = 20
        if (-not $settings.settings.artifactStorageName ) {
            $settings.settings  | Add-Member NoteProperty "artifactStorageName" $gcs_artifact_storage_name -force
        }
        else {
            $settings.settings.artifactStorageName = $gcs_artifact_storage_name 
        }
        if (-not $settings.settings.buildCacheName ) {
            $settings.settings  | Add-Member NoteProperty "buildCacheName" $gcs_cache_storage_name -force
        }
        else {
            $settings.settings.buildCacheName = $gcs_cache_storage_name 
        }
        $settings.settings.failureStrategy.jobStartTimeoutSeconds = 300
        $settings.settings.failureStrategy.provisioningAttempts = 3
        $settings.settings.cloudSettings.googleAccount.projectName = $($activeconfig.properties.core.project)
        $settings.settings.cloudSettings.googleAccount.serviceAccountEmail = $($gceserviceaccount.email)
        if ($gce_account_certificate_base64) {$settings.settings.cloudSettings.googleAccount.serviceAccountCertificateBase64 = $gce_account_certificate_base64}
        $settings.settings.cloudSettings.vmConfiguration.zoneName = $gce_zone
        $settings.settings.cloudSettings.vmConfiguration.sizeName = $gce_machine_type
        $settings.settings.cloudSettings.networking.assignExternalIP = $true
        $settings.settings.cloudSettings.networking.networkName = $gce_network_name
        $settings.settings.cloudSettings.images[0].name = $image_description
        $settings.settings.cloudSettings.images[0].snapshotOrImage = $gce_image_name
        $settings.settings.cloudSettings.images[0].sizeGB = 200
        $jsonBody = $settings | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds"-Headers $headers -Body $jsonBody -Method Put | Out-Null
        Write-host "AppVeyor build environment '$($build_cloud_name)' has been updated." -ForegroundColor DarkGray
    }

    Write-host "`nEnsuring build worker image is available for AppVeyor projects..." -ForegroundColor Cyan
    $images = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-worker-images" -Headers $headers -Method Get
    $image = $images | ? ({$_.name -eq $image_description})[0]
    $osType = if ($image_os -eq "Windows") {"Windows"} elseif ($image_os -eq "Linux") {"Ubuntu"}
    if (-not $image) {
        $body = @{
            name = $image_description
            osType = $osType
        }

        $jsonBody = $body | ConvertTo-Json
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-worker-images" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
        Write-host "AppVeyor build worker image '$($image_description)' has been created." -ForegroundColor DarkGray
    }
    else {
        $image.name = $image_description
        $image.osType = $osType
        $jsonBody = $image | ConvertTo-Json
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-worker-images" -Headers $headers -Body $jsonBody  -Method Put | Out-Null
        Write-host "AppVeyor build worker image '$($image_description)' has been updated." -ForegroundColor DarkGray
    }

    $StopWatch.Stop()
    $completed = "{0:hh}:{0:mm}:{0:ss}" -f $StopWatch.elapsed
    Write-Host "`nCompleted in $completed."

    #Report results and next steps
    Write-host "`nNext steps:"  -ForegroundColor Cyan
    Write-host " - Optionally review build environment '$($build_cloud_name)' at '$($appveyor_url)/build-clouds/$($cloud.buildCloudId)'" -ForegroundColor DarkGray
    Write-host " - To start building on GCE set " -ForegroundColor DarkGray -NoNewline
    Write-host "$($image_description) " -NoNewline 
    Write-host "build worker image " -ForegroundColor DarkGray -NoNewline 
    Write-host "and " -ForegroundColor DarkGray -NoNewline 
    Write-host "$($build_cloud_name) " -NoNewline 
    Write-host "build cloud in AppVeyor project settings or appveyor.yml." -NoNewline -ForegroundColor DarkGray
}

catch {
    Write-Warning "Script exited with error: $($_.Exception)"
    Exit-Script
}






