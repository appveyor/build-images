Function Connect-AppVeyorToGCE {
    <#
    .SYNOPSIS
        Command to enable GCE builds. Works with both hosted AppVeyor and AppVeyor Server.

    .DESCRIPTION
        You can connect your AppVeyor account (on both hosted AppVeyor and on-premise AppVeyor Server) to your own GCE account for AppVeyor to instantiate build VMs in it. There are several benefits like having the ability to customize your build image, select desired VM size, set custom build timeout and many others. To simplify the setup process for you, command provisions necessary GCE and GCS resources, runs Hashicorp Packer to create a basic build image, and puts all the AppVeyor configuration together. After running this command, you should be able to start builds on GCE immediately (and optionally customize your GCE build environment later).

    .PARAMETER AppVeyorUrl
        AppVeyor URL. For hosted AppVeyor it is https://ci.appveyor.com. For Appveyor Server users it is URL of on-premise AppVeyor Server installation

    .PARAMETER ApiToken
        API key for specific account (not 'All accounts'). Hosted AppVeyor users can find it at https://ci.appveyor.com/api-keys. Appveyor Server users can find it at <appveyor_server_url>/api-keys.

    .PARAMETER SkipDisclaimer
        Skip warning related to GCE resources creation and potential charges. It is recommended to read the warning at least once, but it can come in handy if you need to re-run the command.

    .PARAMETER UseCurrentGcloudConfig
        Use current active Google cloud config, so command will use current Google account and create resources in the Google Cloud project set in the current config.

    .PARAMETER Zone
        Google cloud zone, e.g. 'us-east1-b'

    .PARAMETER VmSize
        Type of GCE machine, e.g. 'n1-standard-1'

    .PARAMETER ImageId
        It may be that having run the command and created a valid VM image, some AppVeyor settings are not set correctly (or you may just want to change them without doing it in the AppVeyor build environments UI). In this case you want to skip the most time consuming step (creating an image with Packer) and pass the existing image ID to this parameter.

    .PARAMETER CommonPrefix
        Command will prepend all created GCE resources names with it. Due to storage account names restrictions, it must contain only letters and numbers and be shorter than 16 symbols. Default value is 'appveyor'.

    .PARAMETER ImageOs
        Operating system of build VM image. Valid values: 'Windows', 'Linux'. Default value is 'Windows'.

    .PARAMETER ImageName
        Description to be passed to Packer and name to be used for AppVeyor image.  Default value generated is based on the value of 'ImageOs' parameter.

    .PARAMETER ImageTemplate
        If you are familiar with Hashicorp Packer, you can replace template used by this command with another one.  Default value generated is based on the value of 'ImageOs' parameter.

    .PARAMETER ImageFeatures
        Comma-separated list of feature IDs to be installed on the image. Available IDs can be found at https://github.com/appveyor/build-images/blob/master/byoc/image-builder-metadata.json under 'installedFeatures'.

    .PARAMETER ImageCustomScript
        Base-64 encoded text of custom sript to execute during image creation. It should not contain reboot instructions.

    .PARAMETER ImageCustomScriptAfterReboot
        Base-64 encoded text of custom sript to execute during image creation, after reboot. It is usefull for cases when custom software being installed with 'ImageCustomScript' required some additional action after computer restarted.

        .EXAMPLE
        Connect-AppVeyorToGCE
        Let command collect all required information

        .EXAMPLE
        Connect-AppVeyorToGCE -AppVeyorUrl https://ci.appveyor.com -ApiToken XXXXXXXXXXXXXXXXXXXXX -SkipDisclaimer -Zone us-east1-b -VmSize n1-standard-1
        Command will create resources us-east1-b zone, and will connect it to hosted AppVeyor. Machine type n1-standard-1 will be used for both Packer and AppVeyor builds.
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
      [switch]$UseCurrentGcloudConfig,

      [Parameter(Mandatory=$false)]
      [string]$Zone,

      [Parameter(Mandatory=$false)]
      [string]$VmSize,

      [Parameter(Mandatory=$false)]
      [string]$ImageId,

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
      [string]$ImageCustomScriptAfterReboot
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
    $headers = ValidateAppVeyorApiAccess $AppVeyorUrl $ApiToken

    #Ensure required tools installed
    ValidateDependencies -cloudType GCE

    $regex =[regex] "^([A-Za-z0-9]+)$"
    if (-not $regex.Match($CommonPrefix).Success) {
        Write-Warning "'CommonPrefix' can contain only letters and numbers"
        ExitScript
    }

    # restriction need to use in bucket name (https://cloud.google.com/storage/docs/naming)
    if (($CommonPrefix -like "goog*") -or ($CommonPrefix -like "*google*") -or ($CommonPrefix -like "*g00gle*")) {
        Write-Warning "'CommonPrefix' cannot begin with the 'goog' prefix and cannot contain 'google' or close misspellings, such as 'g00gle'"
        ExitScript
    }

    #"artifact" is longest name postfix. 
    #63 is GCS bucket name limit
    #5 is minumum lenght of infix to be unique
    $maxtotallength = 63
    $mininfix = 5
    $maxpostfix = "artifact".Length
    $maxprefix = $maxtotallength - $maxpostfix - $mininfix
    if ($CommonPrefix.Length -ge  $maxprefix){
         Write-warning "Length of 'CommonPrefix' must be under $($maxprefix)"
         ExitScript
    }

    #Make GCS bucket names globally unique
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding
    $apikeyhash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($ApiToken)))
    $infix = $apikeyhash.Replace("-", "").ToLower()
    $maxinfix = ($maxtotallength - $CommonPrefix.Length - $maxpostfix)
    if ($infix.Length -gt $maxinfix){$infix = $infix.Substring(0, $maxinfix)}

    $gcs_storage_bucket_cache = "$($CommonPrefix)$($infix)cache".ToLower()
    $gcs_storage_bucket_artifacts = "$($CommonPrefix)$($infix)artifact".ToLower()

    $gcs_cache_storage_name = "$($CommonPrefix)-gcs-cache"
    $gcs_artifact_storage_name = "$($CommonPrefix)-gcs-artifacts"

    $ImageName = if ($ImageName) {$ImageName} else {$ImageOs}
    $ImageTemplate = GetImageTemplatePath $imageTemplate
    $ImageTemplate = ParseImageFeaturesAndCustomScripts $ImageFeatures $ImageTemplate $ImageCustomScript $ImageCustomScriptAfterReboot $ImageOs

    $install_user = "appveyor"
    $install_password = CreatePassword

    $gce_network_name = "$($CommonPrefix)-network"    
    $gce_firewall_name = if ($ImageOs -eq "Windows") {"$($CommonPrefix)-rdp"} elseif ($ImageOs -eq "Linux") {"$($CommonPrefix)-ssh"}
    $gce_firewall_winrm__name = "$($CommonPrefix)-firewall-winrm"
    $gce_firewall_winrm__port = 5986
    $gce_service_account = "$($CommonPrefix)-sa"
    $gce_account_file = Join-Path $(CreateTempFolder) "$CommonPrefix-account-file.json"
    $gce_account_certificate_file = if ($env:HOME) {"$env:HOME/$($CommonPrefix)-account-certificate.p12"} elseif ($env:HOMEPATH) {"$env:HOMEPATH\$($CommonPrefix)-account-certificate.p12"}

    if (-not $SkipDisclaimer) {
         Write-Warning "`nThis command will create GCE resources such as network and service account, as well as GCS buckets. Also, it will run Hashicorp Packer which will create its own temporary GCE resources and create a VM image for future use by AppVeyor build VMs. Please note that charges for cloud VMs and other cloud resources will be applied directly to your GCE account bill. `n`nIf GCE project you are authorized to contains production resources, you might consider creating a separate project or even account and run this command against it. Additionally, a separate account is better to distinguish Google bills for CI machines from other Google bills. `n`nPress Enter to continue or Ctrl-C to exit the command. Use '-SkipDisclaimer' switch parameter to skip this message next time."
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

            elseif (-not $UseCurrentGcloudConfig) {
                Write-host "You are currently logged in to Google as '$($activeconfig.properties.core.account)', project '$($activeconfig.properties.core.project)'"
                Write-Warning "Add '-UseCurrentGcloudConfig' switch parameter to use current Google Cloud config and skip this dialog next time."
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
                    ExitScript
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
            ExitScript
        }
        Write-host "GCE API is enabled" -ForegroundColor DarkGray

        #Select GCE zone
        Write-host "`nSelecting GCE zone..." -ForegroundColor Cyan
        if (-not $Zone) {
            Write-Warning "Add '-Zone' parameter to skip this dialog next time"
            if ($activeconfig.properties.compute.zone) {
                Write-Host "You current Google Cloud zone is '$($activeconfig.properties.compute.zone)'"
                $usedefaultzone = Read-Host "Enter 1 if you want continue or 2 to select another zone"
                if ($usedefaultzone -eq 1) {
                    $Zone = $activeconfig.properties.compute.zone
                }
                elseif ($usedefaultzone -ne 2) {
                    Write-Warning "Invalid input. Enter either 1 or 2."
                    ExitScript
                }
            }
            if ((-not $activeconfig.properties.compute.zone) -or ($usedefaultzone -eq 2)) {
                $gcezones = gcloud compute zones list --format=json | ConvertFrom-Json
                for ($i = 1; $i -le $gcezones.Count; $i++) {"Select $i for $($gcezones[$i - 1].Name)"}
                $zone_number = Read-Host "Enter your selection"
                if (-not $zone_number) {
                    Write-Warning "No GCE zone selected."
                    ExitScript
                }
                $selected_zone = $gcezones[$zone_number - 1]
                $Zone = $selected_zone.Name
            }
        }
        Write-host "Using GCE zone '$($Zone)'" -ForegroundColor DarkGray

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
            ExitScript
        }
        Write-host "Using GCE network '$($gce_network_name)'" -ForegroundColor DarkGray

        $remoteaccessport = if ($ImageOs -eq "Windows") {3389} elseif ($ImageOs -eq "Linux") {22}
        $remoteaccessname = if ($ImageOs -eq "Windows") {"RDP"} elseif ($ImageOs -eq "Linux") {"SSH"}
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
            Write-Warning "Unable to allow TCP $($remoteaccessport). ($($remoteaccessname) access to build VMs will not be available. Please update settings for firewall $($gce_firewall_name), network $($gce_network_name) in Google Cloud console if $($remoteaccessname) access is needed."
        }

        Write-host "`nSelecting GCE machine type..." -ForegroundColor Cyan
        if (-not $VmSize) {
            $machinetypes = Get-GceMachineType -Zone $Zone
            for ($i = 1; $i -le $machinetypes.Count; $i++) {"Select $i for $($machinetypes[$i - 1].name)    $($machinetypes[$i - 1].description)"}
            if ($ImageOs -eq "Windows") {Write-Warning "Minimum recommended is 'n1-standard-2'"}
            if ($ImageOs -eq "Linux") {Write-Warning "Minimum recommended is 'n1-standard-1'"}
            Write-Warning "Add '-VmSize' parameter to skip this dialog next time."
            $instance_number = Read-Host "Enter your selection"
            if (-not $instance_number) {
                Write-Warning "No GCE machine type selected."
                ExitScript
            }
            #$selected_instance_type = $machinetypes[$instance_number - 1].name
            $VmSize = $machinetypes[$instance_number - 1].name
        }
        Write-host "Using instance type '$($VmSize)'" -ForegroundColor DarkGray

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
                ExitScript
            }
        }
        Write-host "Using GCE service account '$($gce_service_account)'" -ForegroundColor DarkGray
        $gceserviceaccount = GetGcloudSserviceAccount

        #Run Packer to create an image
        if (-not $ImageId) {
            $packerPath = GetPackerPath
            $packerManifest = "$(CreateTempFolder)/packer-manifest.json"
            Write-host "`nCreating temporary service account key for Packer..." -ForegroundColor Cyan
            #TODO check is number of keys already used
            $packer_gce_key = $null
            $keysBefore = gcloud iam service-accounts keys list --iam-account=$($gceserviceaccount.email) --format=json | ConvertFrom-Json
            $keycreationoutput = gcloud iam service-accounts keys create $gce_account_file --iam-account=$($gceserviceaccount.email)
            $keysAfter = gcloud iam service-accounts keys list --iam-account=$($gceserviceaccount.email) --format=json | ConvertFrom-Json
            $packer_gce_key = (Compare-Object -ReferenceObject $keysBefore -DifferenceObject $keysAfter -Property name -PassThru).name
            $packer_gce_key = $packer_gce_key.Substring($packer_gce_key.LastIndexOf("/")+1, 40)
            Write-host "Using temporary service account key '$($packer_gce_key)', key file '$($gce_account_file)'" -ForegroundColor DarkGray

            Write-host "`nTemporarily allowing TCP $($gce_firewall_winrm__port) (WinRM) for Packer build..." -ForegroundColor Cyan
            if (-not (GcloudFirewallAndRuleExtst -name $gce_firewall_winrm__name -port $gce_firewall_winrm__port)) {
                gcloud compute firewall-rules create $gce_firewall_winrm__name --allow tcp:$gce_firewall_winrm__port
                Write-host "Allowed TCP $($gce_firewall_winrm__port) (WinRM)" -ForegroundColor DarkGray
            }

            Write-host "`nRunning Packer to create a basic build VM image..." -ForegroundColor Cyan
            Write-Warning "Add '-ImageId' parameter with if you want to to skip Packer build and reuse existing image."
            Write-Host "`n`nPacker progress:`n"
            $date_mark=Get-Date -UFormat "%Y%m%d%H%M%S"

            $env:PACKER_LOG=1
            $env:PACKER_LOG_PATH= Join-Path $(GetHomeDir) "packer-$date_mark.log"

            & $packerPath build '--only=googlecompute' `
            -var "gce_account_file=$gce_account_file" `
            -var "gce_project=$($activeconfig.properties.core.project)" `
            -var "gce_zone=$Zone" `
            -var "gce_machine_type=$VmSize" `
            -var "install_password=$install_password" `
            -var "install_user=$install_user" `
            -var "build_agent_mode=GCE" `
            -var "image_description=$ImageName" `
            -var "datemark=$date_mark" `
            -var "packer_manifest=$packerManifest" `
            -var "OPT_FEATURES=$ImageFeatures" `
            $ImageTemplate

            #Get image path
            if (-not (test-path $packerManifest)) {
                Write-Warning "Packer build failed."
                ExitScript
            }
            Write-host "`nGetting image name..." -ForegroundColor Cyan
            $manifest = Get-Content -Path $packerManifest | ConvertFrom-Json
            $ImageId = $manifest.builds[0].artifact_id
            Remove-Item $packerManifest -Force -ErrorAction Ignore
            Write-host "Build image created by Packer: '$($ImageId)'" -ForegroundColor DarkGray
            Write-Host "Default build VM credentials: User: 'appveyor', Password: '$($install_password)'. Normally you do not need this password as it will be reset to a random string when the build starts. However you can use it if you need to create and update a VM from the Packer-created VHD manually"  -ForegroundColor DarkGray

            #TODO wrap and use with to cleanup in ExitScript
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
            Write-host "Using existing image '$($ImageId)'" -ForegroundColor DarkGray
        }

        # If either builc cache, artifact storage or cloud does no exist, issue and use new account certificate
        $buildcaches = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches" -Headers $headers -Method Get
        $buildcache = $buildcaches | ? ({$_.name -eq $gcs_cache_storage_name})[0]
        $artifactstorages = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages" -Headers $headers -Method Get
        $artifactstorage = $artifactstorages | ? ({$_.name -eq $gcs_artifact_storage_name})[0]
        $clouds = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds" -Headers $headers -Method Get
        $cloud = $clouds | ? ({$_.name -eq $build_cloud_name})[0]
        $gce_account_certificate_base64 = $null;
        if ((-not $buildcache) -or (-not $artifactstorage) -or (-not $cloud)) {
            Write-host "`nCreating service account certificate..." -ForegroundColor Cyan
            gcloud iam service-accounts keys create $gce_account_certificate_file --iam-account=$($gceserviceaccount.email) --key-file-type=p12
            $bytes = [System.IO.File]::ReadAllBytes($gce_account_certificate_file)
            $gce_account_certificate_base64 = [System.Convert]::ToBase64String($bytes)        
            if (-not $gce_account_certificate_base64) {
                Write-Warning "Unable to create service account certificate."
                ExitScript
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
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            Write-host "AppVeyor build cache storage '$($gcs_cache_storage_name)' has been created." -ForegroundColor DarkGray
        }
        else {
            $settings = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches/$($buildcache.buildCacheId)" -Headers $headers -Method Get
            $settings.name = $gcs_cache_storage_name
            $settings.cacheType = "Google"
            $settings.settings.serviceAccountEmail = $($gceserviceaccount.email)
            if ($gce_account_certificate_base64) {$settings.settings.serviceAccountCertificateBase64 = $gce_account_certificate_base64}
            $settings.settings.bucketName = $gcs_storage_bucket_cache
            $jsonBody = $settings | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches"-Headers $headers -Body $jsonBody -Method Put | Out-Null
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
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            Write-host "AppVeyor artifacts storage '$($gcs_artifact_storage_name)' has been created." -ForegroundColor DarkGray
        }
        else {
            $settings = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages/$($artifactstorage.artifactStorageId)" -Headers $headers -Method Get
            $settings.name = $gcs_artifact_storage_name
            $settings.storageType = "Google"
            $settings.settings.serviceAccountEmail = $($gceserviceaccount.email)
            if ($gce_account_certificate_base64) {$settings.settings.serviceAccountCertificateBase64 = $gce_account_certificate_base64}
            $settings.settings.bucketName = $gcs_storage_bucket_artifacts
            $jsonBody = $settings | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages"-Headers $headers -Body $jsonBody -Method Put | Out-Null
            Write-host "AppVeyor artifacts storage '$($gcs_artifact_storage_name)' has been updated." -ForegroundColor DarkGray
        }

        #Create or update cloud
        Write-host "`nCreating or updating build environment on AppVeyor..." -ForegroundColor Cyan
        $build_cloud_name = "GCE $Zone $VmSize"
        $clouds = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds" -Headers $headers -Method Get
        $cloud = $clouds | ? ({$_.name -eq $build_cloud_name})[0]
        $image_size = if ($ImageOs -eq "Windows") {200} elseif ($ImageOs -eq "Linux") {40}
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
                            zoneName = $Zone
                            sizeName = $VmSize
                        }
                        networking = @{
                            assignExternalIP = $true
                            networkName = $gce_network_name
                            }
                        images = @(@{
                                name = $ImageName
                                snapshotOrImage = $ImageId
                                sizeGB = $image_size
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
            $settings.settings.cloudSettings.vmConfiguration.zoneName = $Zone
            $settings.settings.cloudSettings.vmConfiguration.sizeName = $VmSize
            $settings.settings.cloudSettings.networking.assignExternalIP = $true
            $settings.settings.cloudSettings.networking.networkName = $gce_network_name
            if ($settings.settings.cloudSettings.images | ? {$_.name -eq $ImageName}) {
                ($settings.settings.cloudSettings.images | ? {$_.name -eq $ImageName}).snapshotOrImage = $ImageId
            }
            else {
                $new_image = @{
                    'name' = $ImageName
                    'snapshotOrImage' = $ImageId
                    'sizeGB' = $image_size
                }
                $new_image = $new_image | ConvertTo-Json | ConvertFrom-Json
                $settings.settings.cloudSettings.images += $new_image
            }

            $jsonBody = $settings | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds"-Headers $headers -Body $jsonBody -Method Put | Out-Null
            Write-host "AppVeyor build environment '$($build_cloud_name)' has been updated." -ForegroundColor DarkGray
        }

        SetBuildWorkerImage $headers $ImageName $ImageOs

        $StopWatch.Stop()
        $completed = "{0:hh}:{0:mm}:{0:ss}" -f $StopWatch.elapsed
        Write-Host "`nCompleted in $completed."

        PrintSummary 'GCE VMs' $AppVeyorUrl $cloud.buildCloudId $build_cloud_name $imageName
    }

    catch {
        Write-Warning "Command exited with error: $($_.Exception)"
        ExitScript
    }
}






