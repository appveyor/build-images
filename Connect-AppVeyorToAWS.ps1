Function Connect-AppVeyorToAWS {
    <#
    .SYNOPSIS
        Command to enable AWS builds. Works with both hosted AppVeyor and AppVeyor Server.

    .DESCRIPTION
        You can connect your AppVeyor account (on both hosted AppVeyor and on-premise AppVeyor Server) to your own AWS account for AppVeyor to instantiate build VMs in it. There are several benefits like having the ability to customize your build image, select desired VM size, set custom build timeout and many others. To simplify the setup process for you, command provisions necessary AWS resources, runs Hashicorp Packer to create a basic build image, and puts all the AppVeyor configuration together. After running this command, you should be able to start builds on AWS immediately (and optionally customize your AWS build environment later).

    .PARAMETER AppVeyorUrl
        AppVeyor URL. For hosted AppVeyor it is https://ci.appveyor.com. For Appveyor Server users it is URL of on-premise AppVeyor Server installation

    .PARAMETER ApiToken
        API key for specific account (not 'All accounts'). Hosted AppVeyor users can find it at https://ci.appveyor.com/api-keys. Appveyor Server users can find it at <appveyor_server_url>/api-keys.

    .PARAMETER AccessKeyId
        AWS Access Key ID to be used both by Packer to create an AMI and by AppVeyor to create required AWS resources and provision build VMs.

    .PARAMETER SecretAccessKey
        AWS Secret Access Key to be used both by Packer to create an AMI and by AppVeyor to create required AWS resources and provision build VMs.
        Note: later you can replace those credentials with Role ARN to assume in AppVeyor settings for your AWS build environment.

    .PARAMETER SkipDisclaimer
        Skip warning related to AWS resources creation and potential charges. It is recommended to read the warning at least once, but it can come handy if you need to re-run the command.

    .PARAMETER Region
        AWS region where you want the command to create a build worker AMI and all additional required resources. Also, AppVeyor will create build VMs in this location. Use short notation (not display name) e.g. 'us-east-1', not 'US East (Virginia)'.

    .PARAMETER InstanceSize
        Type of EC2 instance, e.g. 'm4.large'

    .PARAMETER SubnetId
        Subnet ID for a subnet where build VMs will be created.

    .PARAMETER AmiId
        It may be that you run the command, and it creates a valid AMI, but some AppVeyor settings are not set correctly (or you may just want to change them without doing it in the AppVeyor build environments UI). In this case you want to skip the most time consuming step (creating an AMI) and pass the existing AMI ID to this parameter.

    .PARAMETER CommonPrefix
        Command will prepend all created AWS resources names with it. Because of storage account names restrictions, is must contain only letters and numbers and be shorter than 16 symbols. Default value is 'appveyor'.

    .PARAMETER ImageOs
        Operating system of build VM image. Valid values: 'Windows', 'Linux'. Default value is 'Windows'.

    .PARAMETER ImageName
        Description to be passed to Packer and name to be used for AppVeyor image. Default value generated is based on the value of 'ImageOs' parameter.

    .PARAMETER ImageTemplate
        If you are familiar with Hashicorp Packer, you can replace template used by this command with another one. Default value generated is based on the value of 'ImageOs' parameter.

    .PARAMETER ImageFeatures
        Comma-separated list of feature IDs to be installed on the image. Available IDs can be found at https://github.com/appveyor/build-images/blob/master/byoc/image-builder-metadata.json under 'installedFeatures'.

    .PARAMETER ImageCustomScript
        Base-64 encoded text of custom sript to execute during image creation. It should not contain reboot instructions.

    .PARAMETER ImageCustomScriptAfterReboot
        Base-64 encoded text of custom sript to execute during image creation, after reboot. It is usefull for cases when custom software being installed with 'ImageCustomScript' required some additional action after computer restarted.

        .EXAMPLE
        Connect-AppVeyorToAWS
        Let command collect all required information

        .EXAMPLE
        Connect-AppVeyorToAWS -AppVeyorUrl "https://ci.appveyor.com" -ApiToken XXXXXXXXXXXXXXXXXXXXX -AccessKeyId XXXXXXXXXXXXXXXXXXXX -SecretAccessKey XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -SkipDisclaimer -Region us-east-1 -InstanceSize m4.large -aws_subnet subnet-xxxxxxxx
        Run command with all required parameters so command will ask no questions. It will create resources in AWS US East (Virginia) region and will connect it to hosted AppVeyor.
    #>

    [CmdletBinding()]
    param
    (
      [Parameter(Mandatory=$true,HelpMessage="AppVeyor URL`nFor hosted AppVeyor it is https://ci.appveyor.com`nFor Appveyor Server users it is URL of on-premise AppVeyor Server installation")]
      [string]$AppVeyorUrl,

      [Parameter(Mandatory=$true,HelpMessage="API key for specific account (not 'All accounts')`nHosted AppVeyor users can find it at https://ci.appveyor.com/api-keys`nAppveyor Server users can find it at <appveyor_server_url>/api-keys")]
      [string]$ApiToken,

      [Parameter(Mandatory=$false)]
      [string]$AccessKeyId,

      [Parameter(Mandatory=$false)]
      [string]$SecretAccessKey,

      [Parameter(Mandatory=$false)]
      [switch]$SkipDisclaimer,

      [Parameter(Mandatory=$false)]
      [string]$Region,

      [Parameter(Mandatory=$false)]
      [string]$InstanceSize,

      [Parameter(Mandatory=$false)]
      [string]$SubnetId,

      [Parameter(Mandatory=$false)]
      [string]$AmiId,

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
        if ($aws_profile -and (Get-AWSCredentials -ProfileName $aws_profile)) {Remove-AWSCredentialProfile -ProfileName $aws_profile -ErrorAction Ignore -force}
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
    ValidateDependencies -cloudType AWS

    $regex =[regex] "^([A-Za-z0-9]+)$"
    if (-not $regex.Match($CommonPrefix).Success) {
        Write-Warning "'CommonPrefix' can contain only letters and numbers"
        ExitScript
    }

    #"artifact" is longest name postfix. 
    #63 is S3 bucket name limit
    #5 is minumum lenght of infix to be unique
    $maxtotallength = 63
    $mininfix = 5
    $maxpostfix = "artifact".Length
    $maxprefix = $maxtotallength - $maxpostfix - $mininfix
    if ($CommonPrefix.Length -ge  $maxprefix){
         Write-warning "Length of 'CommonPrefix' must be under $($maxprefix)"
         ExitScript
    }

    #Make S3 names globally unique
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding
    $apikeyhash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($ApiToken)))
    $infix = $apikeyhash.Replace("-", "").ToLower()
    $maxinfix = ($maxtotallength - $CommonPrefix.Length - $maxpostfix)
    if ($infix.Length -gt $maxinfix){$infix = $infix.Substring(0, $maxinfix)}

    $aws_s3_bucket_cache = "$($CommonPrefix)$($infix)cache".ToLower()
    $aws_s3_bucket_artifacts = "$($CommonPrefix)$($infix)artifact".ToLower()

    $aws_cache_storage_name = "$($CommonPrefix)-aws-cache"
    $aws_artifact_storage_name = "$($CommonPrefix)-aws-artifacts"
    $aws_sg_name = "$($CommonPrefix)-sg"
    $aws_kp_name = "$($CommonPrefix)-kp"
    $aws_kp_path = if (-not $IsWindows) {Join-Path -Path $home -ChildPath "$aws_kp_name.pem"} else {Join-Path -Path $env:userprofile -ChildPath "$aws_kp_name.pem"}
    $aws_profile = "$($CommonPrefix)-temp"

    $ImageName = if ($ImageName) {$ImageName} else {$ImageOs}
    $ImageTemplate = GetImageTemplatePath $imageTemplate
    $ImageTemplate = ParseImageFeaturesAndCustomScripts $ImageFeatures $ImageTemplate $ImageCustomScript $ImageCustomScriptAfterReboot $ImageOs

    $install_user = "appveyor"
    $install_password = CreatePassword

    if (-not $SkipDisclaimer) {
         Write-Warning "`nThis command will create EC2 resources such as security group and key pair. Also, it will run Hashicorp Packer which will create its own temporary EC2 resources and leave AMI for future use by AppVeyor build VMs. Please note that charges for cloud VMs and other cloud resources will be applied directly to your AWS account bill. `n`nIf AWS account you are authorized to contains production resources, you might consider creating a separate account and run this command against it. Additionally, a separate account is better to distinguish AWS bills for CI machines from other AWS bills. `n`nPress Enter to continue or Ctrl-C to exit the command. Use '-SkipDisclaimer' switch parameter to skip this message next time."
         $disclaimer = Read-Host
         }

    try {
        #Set AWS Credentials
        if (-not $AccessKeyId) {
            Write-Warning "Add '-AccessKeyId' parameter to skip this dialog next time."
            $AccessKeyId = Read-Host "Enter AWS access key ID"
        }
        if (-not $SecretAccessKey) {
            Write-Warning "Add '-SecretAccessKey' parameter to skip this dialog next time."
            $SecretAccessKey = Read-Host "Enter AWS secret access key"
        }
        if (Get-AWSCredentials -ProfileName $aws_profile) {Remove-AWSCredentialProfile -ProfileName $aws_profile -ErrorAction Ignore -force}
        Set-AWSCredentials -AccessKey $AccessKeyId -SecretKey $SecretAccessKey -StoreAs $aws_profile
        Set-AWSCredentials -ProfileName $aws_profile

        #Select AWS region
        Write-host "`nSelecting AWS region..." -ForegroundColor Cyan
        $regions = Get-AWSRegion
        if ($Region) {
            $aws_region_full = ($regions | ? {$_.Region -eq $Region}).Name
        }
        else {
            for ($i = 1; $i -le $regions.Count; $i++) {"Select $i for $($regions[$i - 1].Name)"}
            Write-Warning "Add '-Region' parameter to skip this dialog next time."
            $region_number = Read-Host "Enter your selection"
            if (-not $region_number) {
                Write-Warning "No AWS region selected."
                ExitScript
            }
            $selected_region = $regions[$region_number - 1]
            $Region = $selected_region.Region
            $aws_region_full = $selected_region.Name
        }
        Write-host "Using AWS region '$($aws_region_full)'" -ForegroundColor DarkGray

        #Select VM size
        $instancetypes = @(
                    "t2.nano",
                    "t2.micro",
                    "t2.small",
                    "t2.medium",
                    "t2.large",
                    "t2.xlarge",
                    "t2.2xlarge",

                    "t3.nano",
                    "t3.micro",
                    "t3.small",
                    "t3.medium",
                    "t3.large",
                    "t3.xlarge",
                    "t3.2xlarge",

                    "t3a.nano",
                    "t3a.micro",
                    "t3a.small",
                    "t3a.medium",
                    "t3a.large",
                    "t3a.xlarge",
                    "t3a.2xlarge",

                    "m4.large",
                    "m4.xlarge",
                    "m4.2xlarge",
                    "m4.4xlarge",
                    "m4.10xlarge",
                    "m4.16xlarge",

                    "m5.large",
                    "m5.xlarge",
                    "m5.2xlarge",
                    "m5.4xlarge",
                    "m5.12xlarge",
                    "m5.24xlarge",
                    "m5d.large",
                    "m5d.xlarge",
                    "m5d.2xlarge",
                    "m5d.4xlarge",
                    "m5d.12xlarge",
                    "m5d.24xlarge",
                    "m5d.metal",

                    "m5a.large",
                    "m5a.xlarge",
                    "m5a.2xlarge",
                    "m5a.4xlarge",
                    "m5a.12xlarge",
                    "m5a.24xlarge",
                    "m5ad.large",
                    "m5ad.xlarge",
                    "m5ad.2xlarge",
                    "m5ad.4xlarge",
                    "m5ad.12xlarge",
                    "m5ad.24xlarge",

                    "c4.large",
                    "c4.xlarge",
                    "c4.2xlarge",
                    "c4.4xlarge",
                    "c4.8xlarge",

                    "c5.large",
                    "c5.xlarge",
                    "c5.2xlarge",
                    "c5.4xlarge",
                    "c5.9xlarge",
                    "c5.18xlarge",
                    "c5d.xlarge",
                    "c5d.2xlarge",
                    "c5d.4xlarge",
                    "c5d.9xlarge",
                    "c5d.18xlarge",

                    "c5n.large",
                    "c5n.xlarge",
                    "c5n.2xlarge",
                    "c5n.4xlarge",
                    "c5n.9xlarge",
                    "c5n.18xlarge",

                    "r4.large",
                    "r4.xlarge",
                    "r4.2xlarge",
                    "r4.4xlarge",
                    "r4.8xlarge",
                    "r4.16xlarge",

                    "r5.large",
                    "r5.xlarge",
                    "r5.2xlarge",
                    "r5.4xlarge",
                    "r5.12xlarge",
                    "r5.24xlarge",
                    "r5d.large",
                    "r5d.xlarge",
                    "r5d.2xlarge",
                    "r5d.4xlarge",
                    "r5d.12xlarge",
                    "r5d.24xlarge",
                    "r5d.metal",

                    "r5a.large",
                    "r5a.xlarge",
                    "r5a.2xlarge",
                    "r5a.4xlarge",
                    "r5a.12xlarge",
                    "r5a.24xlarge",
                    "r5ad.large",
                    "r5ad.xlarge",
                    "r5ad.2xlarge",
                    "r5ad.4xlarge",
                    "r5ad.12xlarge",
                    "r5ad.24xlarge",

                    "x1.16xlarge",
                    "x1.32xlarge",

                    "x1e.xlarge",
                    "x1e.2xlarge",
                    "x1e.4xlarge",
                    "x1e.8xlarge",
                    "x1e.16xlarge",
                    "x1e.32xlarge",

                    "z1d.large",
                    "z1d.xlarge",
                    "z1d.2xlarge",
                    "z1d.3xlarge",
                    "z1d.6xlarge",
                    "z1d.12xlarge",

                    "u-6tb1.metal",
                    "u-9tb1.metal",
                    "u-12tb1.metal",

                    "i3.large",
                    "i3.xlarge",
                    "i3.2xlarge",
                    "i3.4xlarge",
                    "i3.8xlarge",
                    "i3.16xlarge",
                    "i3.metal",

                    "i3en.large",
                    "i3en.xlarge",
                    "i3en.2xlarge",
                    "i3en.3xlarge",
                    "i3en.6xlarge",
                    "i3en.12xlarge",
                    "i3en.24xlarge",

                    "d2.xlarge",
                    "d2.2xlarge",
                    "d2.4xlarge",
                    "d2.8xlarge",

                    "h1.2xlarge",
                    "h1.4xlarge",
                    "h1.8xlarge",
                    "h1.16xlarge",

                    "f1.2xlarge",
                    "f1.4xlarge",
                    "f1.16xlarge",

                    "g3s.xlarge",
                    "g3.4xlarge",
                    "g3.8xlarge",
                    "g3.16xlarge",

                    "p2.xlarge",
                    "p2.8xlarge",
                    "p2.16xlarge",

                    "p3.2xlarge",
                    "p3.8xlarge",
                    "p3.16xlarge",
                    "p3dn.24xlarge"
                    )
        Write-host "`nSelecting EC2 instance type..." -ForegroundColor Cyan
        if (-not $InstanceSize) {
            #Unable to get a list (https://github.com/aws/aws-cli/issues/1279) so people need to enter.
            for ($i = 1; $i -le $instancetypes.Count; $i++) {"Select $i for $($instancetypes[$i - 1])"}
            if ($ImageOs -eq "Windows") {Write-Warning "Minimum recommended is 'm4.large'"}
            if ($ImageOs -eq "Linux") {Write-Warning "Minimum recommended is 't3.medium'"}
            Write-Warning "Add '-InstanceSize' parameter to skip this dialog next time."
            $instance_number = Read-Host "Enter your selection"
            if (-not $instance_number) {
                Write-Warning "No EC2 instance type selected."
                ExitScript
            }
            $selected_instance_type = $instancetypes[$instance_number - 1]
            $InstanceSize = $selected_instance_type
        }
        Write-host "Using instance type '$($InstanceSize)'" -ForegroundColor DarkGray

        Write-host "`nGetting default subnet in the first availability zone..." -ForegroundColor Cyan
        if (-not $SubnetId) {
            $availabilityzones = Get-EC2AvailabilityZone -Region $Region | ? {$_.State -eq "available"} | Sort-Object -Property ZoneName -ErrorAction Ignore
            if (-not $availabilityzones -or $availabilityzones.Count -lt 1) {
                Write-Warning "Unable to find EC2 availability zone with 'available' state."
                ExitScript
            }
            $availabilityzone = $availabilityzones[0]
            $subnet = Get-EC2Subnet -Region $Region | ? {$_.AvailabilityZone -eq $AvailabilityZone.ZoneName -and $_.State -eq "available" -and $_.DefaultForAz -eq $true}
            if (-not $subnet) {
                Write-Warning "Unable to find default available subnet in the availability zone $($AvailabilityZone.ZoneName). Please use 'SubnetId' parameter to specify a subnet"
                ExitScript
            }
            $SubnetId = $subnet.SubnetId
        }
        Write-host "Using subnet '$($SubnetId)'" -ForegroundColor DarkGray

        #Get or create security group
        Write-host "`nGetting or creating AWS security group..." -ForegroundColor Cyan
        $sg = Get-EC2SecurityGroup -Region $Region -ErrorAction Ignore | ? {$_.GroupName -eq $aws_sg_name}
        if (-not $sg) {
            $sg = New-EC2SecurityGroup -GroupName $aws_sg_name -GroupDescription $aws_sg_name  -Region $Region
        }
        $sg = Get-EC2SecurityGroup -GroupName $aws_sg_name -Region $Region
        $aws_sg_id = $sg.GroupId
        Write-host "Using security group '$($aws_sg_name)'" -ForegroundColor DarkGray
        $remoteaccessport = if ($ImageOs -eq "Windows") {3389} elseif ($ImageOs -eq "Linux") {22}
        $remoteaccessname = if ($ImageOs -eq "Windows") {"RDP"} elseif ($ImageOs -eq "Linux") {"SSH"}
        Write-host "`nAllowing $($remoteaccessname) access to build VMs..." -ForegroundColor Cyan
        if (-not ($sg.IpPermission | ? {$_.ToPort -eq $remoteaccessport})) {
          $ipPermission = New-Object Amazon.EC2.Model.IpPermission
          $ipPermission.IpProtocol = "tcp"
          $ipPermission.ToPort = $remoteaccessport
          $ipPermission.FromPort = $remoteaccessport
          $ipPermission.IpRange = "0.0.0.0/0"
          Grant-EC2SecurityGroupIngress -GroupName $aws_sg_name -Region $Region -ipPermission $ipPermission
          Write-host "Created inbound rule to allow TCP $($remoteaccessport) ($($remoteaccessname))" -ForegroundColor DarkGray
        }
        else {Write-host "TCP $($remoteaccessport) ($($remoteaccessname)) inbound rule already exist for security group '$($aws_sg_name)'" -ForegroundColor DarkGray}

        #Get or create key pair
        Write-host "`nGetting or creating AWS key pair..." -ForegroundColor Cyan
        $kp = Get-EC2KeyPair -Region $Region -ErrorAction Ignore | ? {$_.KeyName -eq $aws_kp_name}
        if (-not $kp) {
            $kp = New-EC2KeyPair -KeyName $aws_kp_name -Region $Region
            $kp.KeyMaterial | Out-File -Encoding ascii $aws_kp_path
            Write-Warning "AWS key pair $($aws_kp_name) has been created. Please store private key $($aws_kp_path) in a secure location" 
        }
        Write-host "Using key pair '$($aws_kp_name)'" -ForegroundColor DarkGray

        #Create S3 bucket for cache storage
        Write-host "`nGetting or creating S3 bucket for cache storage..." -ForegroundColor Cyan
        $bucket = Get-S3Bucket -BucketName $aws_s3_bucket_cache
        if (-not $bucket) {
            $bucket = New-S3Bucket -BucketName $aws_s3_bucket_cache -Region $Region
        }
        else {
            $bucketregion = (Get-S3BucketLocation -BucketName $aws_s3_bucket_cache).Value
            if ($bucketregion -and ($bucketregion -ne $Region)) {
                Write-Warning @"
S3 bucket $($aws_s3_bucket_cache) id in '$($bucketregion)' region, while build environment is being set up in '$($Region)' region. This may lead to slower builds and unnecessary charges
`nYou have one of the following options:
`n- Restart use $($bucketregion) region instead of $($Region)to setup build environment.
`n- Use another prefix to name AWS objects (use 'CommonPrefix' paremeter).
`n- Delete $($aws_s3_bucket_cache) bucket.
"@
                ExitScript
            }
        }
        Write-host "Using S3 bucket '$($aws_s3_bucket_cache)' for cache storage" -ForegroundColor DarkGray

        #Create S3 bucket for artifacts
            Write-host "`nGetting or creating S3 bucket for artifacts storage..." -ForegroundColor Cyan
        $bucket = Get-S3Bucket -BucketName $aws_s3_bucket_artifacts
        if (-not $bucket) {
            $bucket = New-S3Bucket -BucketName $aws_s3_bucket_artifacts -Region $Region
        }
        else {
            $bucketregion = (Get-S3BucketLocation -BucketName $aws_s3_bucket_artifacts).Value
            if ($bucketregion -and ($bucketregion -ne $Region)) {
                Write-Warning @"
S3 bucket $($aws_s3_bucket_artifacts) id in '$($bucketregion)' region, while build environment is being set up in '$($Region)' region. This may lead to slower builds and unnecessary charges
`nYou have one of the following options:
`n- Restart use $($bucketregion) region instead of $($Region)to setup build environment.
`n- Use another prefix to name AWS objects (use 'CommonPrefix' paremeter).
`n- Delete $($aws_s3_bucket_artifacts) bucket.
"@
                ExitScript
            }
        }
        Write-host "Using S3 bucket '$($aws_s3_bucket_artifacts)' for artifacts storage" -ForegroundColor DarkGray

        #Run Packer to create an AMI
        if (-not $AmiId) {
            $packerPath = GetPackerPath
            $packerManifest = "$(CreateTempFolder)/packer-manifest.json"
            Write-host "`nRunning Packer to create a basic build VM AMI..." -ForegroundColor Cyan
            Write-Warning "Add '-AmiId' parameter with if you want to to skip Packer build and and reuse existing AMI. It must be in '$($aws_region_full)' region)."
            Write-Host "`n`nPacker progress:`n"
            $date_mark=Get-Date -UFormat "%Y%m%d%H%M%S"

            $env:PACKER_LOG=1
            $env:PACKER_LOG_PATH= Join-Path $(GetHomeDir) "packer-$date_mark.log"

            & $packerPath build '--only=amazon-ebs' `
            -var "aws_access_key=$AccessKeyId" `
            -var "aws_secret_key=$SecretAccessKey" `
            -var "aws_region=$Region" `
            -var "install_password=$install_password" `
            -var "install_user=$install_user" `
            -var "aws_instance_type=$InstanceSize" `
            -var "build_agent_mode=AmazonEC2" `
            -var "image_description=$ImageName" `
            -var "datemark=$date_mark" `
            -var "packer_manifest=$packerManifest" `
            -var "OPT_FEATURES=$ImageFeatures" `
            $ImageTemplate


            #Get VHD path
            if (-not (test-path $packerManifest)) {
                Write-Warning "Packer build failed."
                ExitScript
            }
            Write-host "`nGetting AMI ID..." -ForegroundColor Cyan
            $manifest = Get-Content -Path $packerManifest | ConvertFrom-Json
            $AmiId = $manifest.builds[0].artifact_id.TrimStart("$($Region)").TrimStart(":")        
            Remove-Item $packerManifest -Force -ErrorAction Ignore
            Write-host "Build image AMI created by Packer. AMI ID: '$($AmiId)'" -ForegroundColor DarkGray
            Write-Host "Default build VM credentials: User: 'appveyor', Password: '$($install_password)'. Normally you do not need this password as it will be reset to a random string when the build starts. However you can use it if you need to create and update a VM from the Packer-created VHD manually"  -ForegroundColor DarkGray
        }
        else {
            Write-host "`nSkipping AMI creation with Packer..." -ForegroundColor Cyan
            Write-host "Using exiting AMI with ID '$($AmiId)'" -ForegroundColor DarkGray
        }

        #Create or update build cache storage settings
        Write-host "`nCreating or updating build cache storage settings on AppVeyor..." -ForegroundColor Cyan
        $buildcaches = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches" -Headers $headers -Method Get
        $buildcache = $buildcaches | ? ({$_.name -eq $aws_cache_storage_name})[0]
        if (-not $buildcache) {
            $body = @{
                name = $aws_cache_storage_name
                cacheType = "AmazonS3"
                settings = @{
                    accessKeyId = $AccessKeyId
                    secretAccessKey = $SecretAccessKey
                    region = $Region
                    bucketName = $aws_s3_bucket_cache
                }
            }
            $jsonBody = $body | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            Write-host "AppVeyor build cache storage '$($aws_cache_storage_name)' has been created." -ForegroundColor DarkGray
        }
        else {
            $settings = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches/$($buildcache.buildCacheId)" -Headers $headers -Method Get
            $settings.name = $aws_cache_storage_name
            $settings.cacheType = "AmazonS3"
            $settings.settings.accessKeyId = $AccessKeyId
            $settings.settings.secretAccessKey = $SecretAccessKey
            $settings.settings.region = $Region
            $settings.settings.bucketName = $aws_s3_bucket_cache
            $jsonBody = $settings | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-caches"-Headers $headers -Body $jsonBody -Method Put | Out-Null
            Write-host "AppVeyor build cache storage '$($aws_cache_storage_name)' has been updated." -ForegroundColor DarkGray
        }

        #Create or update artifacts storage settings
        Write-host "`nCreating or updating artifacts storage settings on AppVeyor..." -ForegroundColor Cyan
        $artifactstorages = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages" -Headers $headers -Method Get
        $artifactstorage = $artifactstorages | ? ({$_.name -eq $aws_artifact_storage_name})[0]
        if (-not $artifactstorage) {
            $body = @{
                name = $aws_artifact_storage_name
                storageType = "AmazonS3"
                settings = @{
                    accessKeyId = $AccessKeyId
                    secretAccessKey = $SecretAccessKey
                    region = $Region
                    bucketName = $aws_s3_bucket_artifacts
                }
            }
            $jsonBody = $body | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
            Write-host "AppVeyor artifacts storage '$($aws_artifact_storage_name)' has been created." -ForegroundColor DarkGray
        }
        else {
            $settings = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages/$($artifactstorage.artifactStorageId)" -Headers $headers -Method Get
            $settings.name = $aws_artifact_storage_name
            $settings.storageType = "AmazonS3"
            $settings.settings.accessKeyId = $AccessKeyId
            $settings.settings.secretAccessKey = $SecretAccessKey
            $settings.settings.region = $Region
            $settings.settings.bucketName = $aws_s3_bucket_artifacts
            $jsonBody = $settings | ConvertTo-Json -Depth 10
            Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/artifact-storages"-Headers $headers -Body $jsonBody -Method Put | Out-Null
            Write-host "AppVeyor artifacts storage '$($aws_artifact_storage_name)' has been updated." -ForegroundColor DarkGray
        }

        #Create or update cloud
        Write-host "`nCreating or updating build environment on AppVeyor..." -ForegroundColor Cyan
        $build_cloud_name = "AWS $Region $InstanceSize"
        $clouds = Invoke-RestMethod -Uri "$($AppVeyorUrl)/api/build-clouds" -Headers $headers -Method Get
        $cloud = $clouds | ? ({$_.name -eq $build_cloud_name})[0]
        if (-not $cloud) {
            $body = @{
                name = $build_cloud_name
                cloudType = "AmazonEC2"
                workersCapacity = 20
                settings = @{
                    artifactStorageName = $aws_artifact_storage_name
                    buildCacheName = $aws_cache_storage_name
                    failureStrategy = @{
                        jobStartTimeoutSeconds = 300
                        provisioningAttempts = 3
                    }
                    cloudSettings = @{
                        awsAccount =@{
                            accessKeyId = $AccessKeyId
                            secretAccessKey = $SecretAccessKey
                        }
                        vmConfiguration = @{
                            region = $Region
                            securityGroupId = $aws_sg_id
                            instanceSize = $InstanceSize
                            keyPairName = $aws_kp_name
                        }
                        networking = @{
                            assignPublicIPAddress = $true
                            subnetId = $SubnetId
                            }
                        images = @(@{
                                name = $ImageName
                                imageId = $AmiId
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
            $settings.cloudType = "AmazonEC2"
            $settings.workersCapacity = 20
            if (-not $settings.settings.artifactStorageName ) {
                $settings.settings  | Add-Member NoteProperty "artifactStorageName" $aws_artifact_storage_name -force
            }
            else {
                $settings.settings.artifactStorageName = $aws_artifact_storage_name 
            }
            if (-not $settings.settings.buildCacheName ) {
                $settings.settings  | Add-Member NoteProperty "buildCacheName" $aws_cache_storage_name -force
            }
            else {
                $settings.settings.buildCacheName = $aws_cache_storage_name 
            }
            $settings.settings.failureStrategy.jobStartTimeoutSeconds = 300
            $settings.settings.failureStrategy.provisioningAttempts = 3
            $settings.settings.cloudSettings.awsAccount.accessKeyId = $AccessKeyId
            $settings.settings.cloudSettings.awsAccount.secretAccessKey = $SecretAccessKey
            $settings.settings.cloudSettings.vmConfiguration.region = $Region
            $settings.settings.cloudSettings.vmConfiguration.securityGroupId = $aws_sg_id
            $settings.settings.cloudSettings.vmConfiguration.instanceSize = $InstanceSize
            $settings.settings.cloudSettings.vmConfiguration.keyPairName = $aws_kp_name
            $settings.settings.cloudSettings.networking.assignPublicIPAddress = $true
            $settings.settings.cloudSettings.networking.subnetId = $SubnetId
            if ($settings.settings.cloudSettings.images | ? {$_.name -eq $ImageName}) {
                ($settings.settings.cloudSettings.images | ? {$_.name -eq $ImageName}).imageId = $AmiId
            }
            else {
                $new_image = @{
                    'name' = $ImageName
                    'imageId' = $AmiId
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

        #Report results and next steps
        PrintSummary 'AWS EC2 VMs' $AppVeyorUrl $cloud.buildCloudId $build_cloud_name $imageName
        if (Test-Path $aws_kp_path) {
            Write-Host " - Please do not forget to move $($aws_kp_path) to a secure location." -ForegroundColor DarkGray
        }
    }

    catch {
        Write-Warning "Command exited with error: $($_.Exception)"
        ExitScript
    }
}




