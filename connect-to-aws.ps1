<#
.SYNOPSIS
    Script to enable AWS builds. Works with both hosted AppVeyor and AppVeyor server.

.DESCRIPTION
    You can connect your AppVeyor account (on both hosted AppVeyor and on-premise AppVeyor Server) to your own AWS account for AppVeyor to instantiate build VMs in it. There are several benefits like having the ability to customize your build image, select desired VM size, set custom build timeout and many others. To simplify the setup process for you, we created a script which provisions necessary AWS resources, runs Hashicorp Packer to create a basic build image, and puts all the AppVeyor configuration together. After running this script, you should be able to start builds on AWS immediately (and optionally customize your AWS build environment later).

.PARAMETER appveyor_api_key
    API key for specific account (not 'All accounts'). Hosted AppVeyor users can find it at https://ci.appveyor.com/api-keys. Appveyor Server users can find it at <appveyor_server_url>/api-keys.

.PARAMETER appveyor_url
    AppVeyor URL. For hosted AppVeyor it is https://ci.appveyor.com. For Appveyor Server users it is URL of on-premise AppVeyor Server installation

.PARAMETER aws_access_key_id
    AWS Access Key ID to be used both by Packer to create an AMI and by AppVeyor to create required AWS resources and provision build VMs.

.PARAMETER aws_secret_access_key
    AWS Secret Access Key to be used both by Packer to create an AMI and by AppVeyor to create required AWS resources and provision build VMs.
    Note: later you can replace those credentials with Role ARN to assume in AppVeyor settings for your AWS build environment.

.PARAMETER skip_disclaimer
    Skip warning related to AWS resources creation and potential charges. It is recommended to read the warning at least once, but it can come handy if you need to re-run the script.

.PARAMETER aws_region
    AWS region where you want the script to create a build worker AMI and all additional required resources. Also, AppVeyor will create build VMs in this location. Use short notation (not display name) e.g. 'us-east-1', not 'US East (Virginia)'.

.PARAMETER aws_instance_type
    Type of EC2 instance, e.g. 'm4.large'

.PARAMETER aws_subnet_id
    Subnet ID for a subnet where build VMs will be created.

.PARAMETER aws_ami_id
    It may be that you run the script, and it creates a valid AMI, but some AppVeyor settings are not set correctly (or you may just want to change them without doing it in the AppVeyor build environments UI). In this case you want to skip the most time consuming step (creating an AMI) and pass the existing AMI ID to this parameter.

.PARAMETER common_prefix
    Script will prepend all created AWS resources and AppVeyor build environment name with it. Because of storage account names restrictions, is must contain only letters and numbers and be shorter than 16 symbols. Default value is 'appveyor'.

.PARAMETER image_os
    Operating system of build VM image. Valid values: 'Windows', 'Linux'. Default value is 'Windows'.

.PARAMETER image_description
    Description to be passed to Packer and name to be used for AppVeyor image.  Default value generated is based on the value of 'image_os' parameter.

.PARAMETER packer_template
    If you are familiar with Hashicorp Packer, you can replace template used by this script with another one.  Default value generated is based on the value of 'image_os' parameter.

    .EXAMPLE
    .\connect-to-aws.ps1
    Let script collect all required information

    .EXAMPLE
    .\connect-to-aws.ps1 -appveyor_api_key XXXXXXXXXXXXXXXXXXXXX -appveyor_url "https://ci.appveyor.com" -aws_access_key_id XXXXXXXXXXXXXXXXXXXX -aws_secret_access_key XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -skip_disclaimer -aws_region us-east-1 -aws_instance_type m4.large -aws_subnet subnet-xxxxxxxx
    Run script with all required parameters so script will ask no questions. It will create resources in AWS US East (Virginia) region and will connect it to hosted AppVeyor.
#>

[CmdletBinding()]
param
(
  [Parameter(Mandatory=$true,HelpMessage="API key for specific account (not 'All accounts')`nHosted AppVeyor users can find it at https://ci.appveyor.com/api-keys`nAppveyor Server users can find it at <appveyor_server_url>/api-keys")]
  [string]$appveyor_api_key,

  [Parameter(Mandatory=$true,HelpMessage="AppVeyor URL`nFor hosted AppVeyor it is https://ci.appveyor.com`nFor Appveyor Server users it is URL of on-premise AppVeyor Server installation")]
  [string]$appveyor_url,

  [Parameter(Mandatory=$false)]
  [string]$aws_access_key_id,

  [Parameter(Mandatory=$false)]
  [string]$aws_secret_access_key,

  [Parameter(Mandatory=$false)]
  [switch]$skip_disclaimer,

  [Parameter(Mandatory=$false)]
  [string]$aws_region,

  [Parameter(Mandatory=$false)]
  [string]$aws_instance_type,

  [Parameter(Mandatory=$false)]
  [string]$aws_subnet_id,

  [Parameter(Mandatory=$false)]
  [string]$aws_ami_id,

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

function exitScript {
    if ($aws_profile -and (Get-AWSCredentials -ProfileName $aws_profile)) {Remove-AWSCredentialProfile -ProfileName $aws_profile -ErrorAction Ignore -force}
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
    exitScript
}

try {
    $responce = Invoke-WebRequest -Uri $appveyor_url -ErrorAction SilentlyContinue
    if ($responce.StatusCode -ne 200) {
        Write-warning "AppVeyor URL '$($appveyor_url)' responded with code $($responce.StatusCode)"
        exitScript
    }
}
catch {
    Write-warning "Unable to connect to AppVeyor URL '$($appveyor_url)'. Error: $($error[0].Exception.Message)"
    exitScript
}

if (-not (Get-Module -Name *AWSPowerShell* -ListAvailable)) {
    Write-Warning "This script depends on AWS Tools for PowerShell. Please install them with the foll command: 'Install-Module -Name AWSPowerShell -Force; Get-Command -Module AWSPowerShell | Out-Null'"
    exitScript
}

if (-not (Get-Command packer -ErrorAction Ignore)) {
    Write-Warning "This script depends on Packer by HashiCorp. Please install it with 'choco install packer' ('apt get packer' for Linux) command or follow https://www.packer.io/intro/getting-started/install.html. If it is already installed, please ensure that PATH environment variable contains path to it."
    exitScript
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
    exitScript
}

if ($appveyor_url -eq "https://ci.appveyor.com") {
      try {
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds" -Headers $headers -Method Get | Out-Null
    }
    catch {
        Write-warning "Please contact support@appveyor.com and request enabling of 'Private build clouds' feature."
        exitScript
    }
}

$regex =[regex] "^([A-Za-z0-9]+)$"
if (-not $regex.Match($common_prefix).Success) {
    Write-Warning "'common_prefix' can contain only letters and numbers"
    exitScript
}

#"artifact" is longest name postfix. 
#63 is S3 bucket name limit
#5 is minumum lenght of infix to be unique
$maxtotallength = 63
$mininfix = 5
$maxpostfix = "artifact".Length
$maxprefix = $maxtotallength - $maxpostfix - $mininfix
if ($common_prefix.Length -ge  $maxprefix){
     Write-warning "Length of 'common_prefix' must be under $($maxprefix)"
     exitScript
}

#Make S3 names globally unique
$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$utf8 = new-object -TypeName System.Text.UTF8Encoding
$apikeyhash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($appveyor_api_key)))
$infix = $apikeyhash.Replace("-", "").ToLower()
$maxinfix = ($maxtotallength - $common_prefix.Length - $maxpostfix)
if ($infix.Length -gt $maxinfix){$infix = $infix.Substring(0, $maxinfix)}

$aws_s3_bucket_cache = "$($common_prefix)$($infix)cache".ToLower()
$aws_s3_bucket_artifacts = "$($common_prefix)$($infix)artifact".ToLower()

$aws_cache_storage_name = "$($common_prefix)-aws-cache"
$aws_artifact_storage_name = "$($common_prefix)-aws-artifacts"
$aws_sg_name = "$($common_prefix)-sg"
$aws_kp_name = "$($common_prefix)-kp"
$aws_kp_path = if (-not $IsWindows) {Join-Path -Path $home -ChildPath "$aws_kp_name.pem"} else {Join-Path -Path $env:userprofile -ChildPath "$aws_kp_name.pem"}
$aws_profile = "$($common_prefix)-temp"

$build_cloud_name = "$($image_os)-AWS-build-environment"
$image_description = if ($image_description) {$image_description} else {"$($image_os) on AWS"}
$packer_template = if ($packer_template) {$packer_template} elseif ($image_os -eq "Windows") {"./minimal-windows-server.json"} elseif ($image_os -eq "Linux") {"./minimal-ubuntu.json"}

$packer_manifest = "packer-manifest.json"
$install_user = "appveyor"
$install_password = "ABC" + (New-Guid).ToString().SubString(0, 12).Replace("-", "") + "!"

if (-not $skip_disclaimer) {
     Write-Warning "`nThis script will create EC2 resources such as security group and key pair. Also, it will run Hashicorp Packer which will create its own temporary EC2 resources and leave AMI for future use by AppVeyor build VMs. Please be aware of possible charges from Amazon. `nIf AWS account you are authorized to contains production resources, you might consider creating a separate account and run this script against it. Additionally, a separate account is better to distinguish AWS bills for CI machines from other AWS bills. `nPress Enter to continue or Ctrl-C to exit the script. Use '-skip_disclaimer' switch parameter to skip this message next time."
     $disclaimer = Read-Host
     }

try {
    #Set AWS Credentials
    if (-not $aws_access_key_id) {
        Write-Warning "Add '-aws_access_key_id' parameter to skip this dialog next time."
        $aws_access_key_id = Read-Host "Enter AWS access key ID"
    }
    if (-not $aws_secret_access_key) {
        Write-Warning "Add '-aws_secret_access_key' parameter to skip this dialog next time."
        $aws_secret_access_key = Read-Host "Enter AWS secret access key"
    }
    if (Get-AWSCredentials -ProfileName $aws_profile) {Remove-AWSCredentialProfile -ProfileName $aws_profile -ErrorAction Ignore -force}
    Set-AWSCredentials -AccessKey $aws_access_key_id -SecretKey $aws_secret_access_key -StoreAs $aws_profile
    Set-AWSCredentials -ProfileName $aws_profile

    #Select AWS region
    Write-host "`nSelecting AWS region..." -ForegroundColor Cyan
    $regions = Get-AWSRegion
    if ($aws_region) {
        $aws_region_full = ($regions | ? {$_.Region -eq $aws_region}).Name
    }
    else {
        for ($i = 1; $i -le $regions.Count; $i++) {"Select $i for $($regions[$i - 1].Name)"}
        Write-Warning "Add '-aws_region' parameter to skip this dialog next time."
        $region_number = Read-Host "Enter your selection"
        if (-not $region_number) {
            Write-Warning "No AWS region selected."
            exitScript
        }
        $selected_region = $regions[$region_number - 1]
        $aws_region = $selected_region.Region
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
    if (-not $aws_instance_type) {
        #Unable to get a list (https://github.com/aws/aws-cli/issues/1279) so people need to enter.
        if ($image_os -eq "Windows") {Write-Warning "Minimum recommended is 'm4.large'"}
        for ($i = 1; $i -le $instancetypes.Count; $i++) {"Select $i for $($instancetypes[$i - 1])"}
        if ($image_os -eq "Windows") {Write-Warning "Minimum recommended is 'm4.large'"}
        Write-Warning "Add '-aws_instance_type' parameter to skip this dialog next time."
        $instance_number = Read-Host "Enter your selection"
        if (-not $instance_number) {
            Write-Warning "No EC2 instance type selected."
            exitScript
        }
        $selected_instance_type = $instancetypes[$instance_number - 1]
        $aws_instance_type = $selected_instance_type
    }
    Write-host "Using instance type '$($aws_instance_type)'" -ForegroundColor DarkGray

    Write-host "`nGetting default subnet in the first availability zone..." -ForegroundColor Cyan
    if (-not $aws_subnet_id) {
        $availabilityzones = Get-EC2AvailabilityZone -Region $aws_region | ? {$_.State -eq "available"} | Sort-Object -Property ZoneName -ErrorAction Ignore
        if (-not $availabilityzones -or $availabilityzones.Count -lt 1) {
            Write-Warning "Unable to find EC2 availability zone with 'available' state."
            exitScript
        }
        $availabilityzone = $availabilityzones[0]
        $subnet = Get-EC2Subnet -Region $aws_region | ? {$_.AvailabilityZone -eq $AvailabilityZone.ZoneName -and $_.State -eq "available" -and $_.DefaultForAz -eq $true}
        if (-not $subnet) {
            Write-Warning "Unable to find default available subnet in the availability zone $($AvailabilityZone.ZoneName). Please use 'aws_subnet_id' parameter to specify a subnet"
            exitScript
        }
        $aws_subnet_id = $subnet.SubnetId
    }
    Write-host "Using subnet '$($aws_subnet_id)'" -ForegroundColor DarkGray

    #Get or create security group
    Write-host "`nGetting or creating AWS security group..." -ForegroundColor Cyan
    $sg = Get-EC2SecurityGroup -Region $aws_region -ErrorAction Ignore | ? {$_.GroupName -eq $aws_sg_name}
    if (-not $sg) {
        $sg = New-EC2SecurityGroup -GroupName $aws_sg_name -GroupDescription $aws_sg_name  -Region $aws_region
    }
    $sg = Get-EC2SecurityGroup -GroupName $aws_sg_name -Region $aws_region
    $aws_sg_id = $sg.GroupId
    Write-host "Using security group '$($aws_sg_name)'" -ForegroundColor DarkGray
    $remoteaccessport = if ($image_os -eq "Windows") {3389} elseif ($image_os -eq "Linux") {22}
    $remoteaccessname = if ($image_os -eq "Windows") {"RDP"} elseif ($image_os -eq "Linux") {"SSH"}
    Write-host "`nAllowing $($remoteaccessname) access to build VMs..." -ForegroundColor Cyan
    if (-not ($sg.IpPermission | ? {$_.ToPort -eq $remoteaccessport})) {
      $ipPermission = New-Object Amazon.EC2.Model.IpPermission
      $ipPermission.IpProtocol = "tcp"
      $ipPermission.ToPort = $remoteaccessport
      $ipPermission.FromPort = $remoteaccessport
      $ipPermission.IpRange = "0.0.0.0/0"
      Grant-EC2SecurityGroupIngress -GroupName $aws_sg_name -Region $aws_region -ipPermission $ipPermission
      Write-host "Created inbound rule to allow TCP $($remoteaccessport) ($($remoteaccessname))" -ForegroundColor DarkGray
    }
    else {Write-host "TCP $($remoteaccessport) ($($remoteaccessname)) inbound rule already exist for security group '$($aws_sg_name)'" -ForegroundColor DarkGray}

    #Get or create key pair
    Write-host "`nGetting or creating AWS key pair..." -ForegroundColor Cyan
    $kp = Get-EC2KeyPair -Region $aws_region -ErrorAction Ignore | ? {$_.KeyName -eq $aws_kp_name}
    if (-not $kp) {
        $kp = New-EC2KeyPair -KeyName $aws_kp_name -Region $aws_region
        $kp.KeyMaterial | Out-File -Encoding ascii $aws_kp_path
        Write-Warning "AWS key pair $($aws_kp_name) has been created. Please store private key $($aws_kp_path) in a secure location" 
    }
    Write-host "Using key pair '$($aws_kp_name)'" -ForegroundColor DarkGray

    #Create S3 bucket for cache storage
    Write-host "`nGetting or creating S3 bucket for cache storage..." -ForegroundColor Cyan
    $bucket = Get-S3Bucket -BucketName $aws_s3_bucket_cache
    if (-not $bucket) {
        $bucket = New-S3Bucket -BucketName $aws_s3_bucket_cache -Region $aws_region
    }
    else {
        $bucketregion = (Get-S3BucketLocation -BucketName $aws_s3_bucket_cache).Value
        if ($bucketregion -and ($bucketregion -ne $aws_region)) {
            Write-Warning @"
S3 bucket $($aws_s3_bucket_cache) id in '$($bucketregion)' region, while build environment is being set up in '$($aws_region)' region. This may lead to slower builds and unnecessary charges
`nYou have one of the following options:
`n- Restart use $($bucketregion) region instead of $($aws_region)to setup build environment.
`n- Use another prefix to name AWS objects (use 'common_prefix' paremeter).
`n- Delete $($aws_s3_bucket_cache) bucket.
"@
            exitScript
        }
    }
    Write-host "Using S3 bucket '$($aws_s3_bucket_cache)' for cache storage" -ForegroundColor DarkGray

    #Create S3 bucket for artifacts
        Write-host "`nGetting or creating S3 bucket for artifacts storage..." -ForegroundColor Cyan
    $bucket = Get-S3Bucket -BucketName $aws_s3_bucket_artifacts
    if (-not $bucket) {
        $bucket = New-S3Bucket -BucketName $aws_s3_bucket_artifacts -Region $aws_region
    }
    else {
        $bucketregion = (Get-S3BucketLocation -BucketName $aws_s3_bucket_artifacts).Value
        if ($bucketregion -and ($bucketregion -ne $aws_region)) {
            Write-Warning @"
S3 bucket $($aws_s3_bucket_artifacts) id in '$($bucketregion)' region, while build environment is being set up in '$($aws_region)' region. This may lead to slower builds and unnecessary charges
`nYou have one of the following options:
`n- Restart use $($bucketregion) region instead of $($aws_region)to setup build environment.
`n- Use another prefix to name AWS objects (use 'common_prefix' paremeter).
`n- Delete $($aws_s3_bucket_artifacts) bucket.
"@
            exitScript
        }
    }
    Write-host "Using S3 bucket '$($aws_s3_bucket_artifacts)' for artifacts storage" -ForegroundColor DarkGray

    #Run Packer to create an AMI
    if (-not $aws_ami_id) {
        Write-host "`nRunning Packer to create a basic build VM AMI..." -ForegroundColor Cyan
        Write-Warning "Add '-aws_ami_id' parameter with if you want to reuse existing AMI (which must be in '$($aws_region_full)' region). Enter Ctrl-C to stop the script and restart with '-aws_ami_id' parameter or do nothing and let the script create a new AMI.`nWaiting 30 seconds..."
        for ($i = 30; $i -ge 0; $i--) {sleep 1; Write-Host "." -NoNewline}
        Remove-Item ".\$($packer_manifest)" -Force -ErrorAction Ignore
        Write-Host "`n`nPacker progress:`n"
        $date_mark=Get-Date -UFormat "%Y%m%d%H%M%S"
        & packer build '--only=amazon-ebs' `
        -var "aws_access_key=$aws_access_key_id" `
        -var "aws_secret_key=$aws_secret_access_key" `
        -var "aws_region=$aws_region" `
        -var "install_password=$install_password" `
        -var "install_user=$install_user" `
        -var "aws_instance_type=$aws_instance_type" `
        -var "build_agent_mode=AmazonEC2" `
        -var "image_description=$image_description" `
        -var "datemark=$date_mark" `
        -var "packer_manifest=$packer_manifest" `
        $packer_template


        #Get VHD path
        if (-not (test-path ".\$($packer_manifest)")) {
            Write-Warning "Unable to find .\$($packer_manifest). Please ensure Packer job finsihed successfully."
            exitScript
        }
        Write-host "`nGetting AMI ID..." -ForegroundColor Cyan
        $manifest = Get-Content -Path ".\$($packer_manifest)" | ConvertFrom-Json
        $aws_ami_id = $manifest.builds[0].artifact_id.TrimStart("$($aws_region)").TrimStart(":")        
        Remove-Item ".\$($packer_manifest)" -Force -ErrorAction Ignore
        Write-host "Build image AMI created by Packer. AMI ID: '$($aws_ami_id)'" -ForegroundColor DarkGray
        Write-Host "Default build VM credentials: User: 'appveyor', Password: '$($install_password)'. Normally you do not need this password as it will be reset to a random string when the build starts. However you can use it if you need to create and update a VM from the Packer-created VHD manually"  -ForegroundColor DarkGray
    }
    else {
        Write-host "`nSkipping AMI creation with Packer..." -ForegroundColor Cyan
        Write-host "Using exiting AMI with ID '$($aws_ami_id)'" -ForegroundColor DarkGray
    }

    #Create or update build cache storage settings
    Write-host "`nCreating or updating build cache storage settings on AppVeyor..." -ForegroundColor Cyan
    $buildcaches = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches" -Headers $headers -Method Get
    $buildcache = $buildcaches | ? ({$_.name -eq $aws_cache_storage_name})[0]
    if (-not $buildcache) {
        $body = @{
            name = $aws_cache_storage_name
            cacheType = "AmazonS3"
            settings = @{
                accessKeyId = $aws_access_key_id
                secretAccessKey = $aws_secret_access_key
                region = $aws_region
                bucketName = $aws_s3_bucket_cache
            }
        }
        $jsonBody = $body | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
        Write-host "AppVeyor build cache storage '$($aws_cache_storage_name)' has been created." -ForegroundColor DarkGray
    }
    else {
        $settings = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches/$($buildcache.buildCacheId)" -Headers $headers -Method Get
        $settings.name = $aws_cache_storage_name
        $settings.cacheType = "AmazonS3"
        $settings.settings.accessKeyId = $aws_access_key_id
        $settings.settings.secretAccessKey = $aws_secret_access_key
        $settings.settings.region = $aws_region
        $settings.settings.bucketName = $aws_s3_bucket_cache
        $jsonBody = $settings | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-caches"-Headers $headers -Body $jsonBody -Method Put | Out-Null
        Write-host "AppVeyor build cache storage '$($aws_cache_storage_name)' has been updated." -ForegroundColor DarkGray
    }

    #Create or update artifacts storage settings
    Write-host "`nCreating or updating artifacts storage settings on AppVeyor..." -ForegroundColor Cyan
    $artifactstorages = Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages" -Headers $headers -Method Get
    $artifactstorage = $artifactstorages | ? ({$_.name -eq $aws_artifact_storage_name})[0]
    if (-not $artifactstorage) {
        $body = @{
            name = $aws_artifact_storage_name
            storageType = "AmazonS3"
            settings = @{
                accessKeyId = $aws_access_key_id
                secretAccessKey = $aws_secret_access_key
                region = $aws_region
                bucketName = $aws_s3_bucket_artifacts
            }
        }
        $jsonBody = $body | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
        Write-host "AppVeyor artifacts storage '$($aws_artifact_storage_name)' has been created." -ForegroundColor DarkGray
    }
    else {
        $settings = Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages/$($artifactstorage.artifactStorageId)" -Headers $headers -Method Get
        $settings.name = $aws_artifact_storage_name
        $settings.storageType = "AmazonS3"
        $settings.settings.accessKeyId = $aws_access_key_id
        $settings.settings.secretAccessKey = $aws_secret_access_key
        $settings.settings.region = $aws_region
        $settings.settings.bucketName = $aws_s3_bucket_artifacts
        $jsonBody = $settings | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri "$($appveyor_url)/api/artifact-storages"-Headers $headers -Body $jsonBody -Method Put | Out-Null
        Write-host "AppVeyor artifacts storage '$($aws_artifact_storage_name)' has been updated." -ForegroundColor DarkGray
    }

    #Create or update cloud
    Write-host "`nCreating or updating build environment on AppVeyor..." -ForegroundColor Cyan
    $clouds = Invoke-RestMethod -Uri "$($appveyor_url)/api/build-clouds" -Headers $headers -Method Get
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
                        accessKeyId = $aws_access_key_id
                        secretAccessKey = $aws_secret_access_key
                    }
                    vmConfiguration = @{
                        region = $aws_region
                        securityGroupId = $aws_sg_id
                        instanceSize = $aws_instance_type
                        keyPairName = $aws_kp_name
                    }
                    networking = @{
                        assignPublicIPAddress = $true
                        subnetId = $aws_subnet_id
                        }
                    images = @(@{
                            name = $image_description
                            imageId = $aws_ami_id
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
        $settings.settings.cloudSettings.awsAccount.accessKeyId = $aws_access_key_id
        $settings.settings.cloudSettings.awsAccount.secretAccessKey = $aws_secret_access_key
        $settings.settings.cloudSettings.vmConfiguration.region = $aws_region
        $settings.settings.cloudSettings.vmConfiguration.securityGroupId = $aws_sg_id
        $settings.settings.cloudSettings.vmConfiguration.instanceSize = $aws_instance_type
        $settings.settings.cloudSettings.vmConfiguration.keyPairName = $aws_kp_name
        $settings.settings.cloudSettings.networking.assignPublicIPAddress = $true
        $settings.settings.cloudSettings.networking.subnetId = $aws_subnet_id
        $settings.settings.cloudSettings.images[0].name = $image_description
        $settings.settings.cloudSettings.images[0].imageId = $aws_ami_id
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
            buildCloudName = $build_cloud_name
            osType = $osType
        }

        $jsonBody = $body | ConvertTo-Json
        Invoke-RestMethod -Uri "$($appveyor_url)/api/build-worker-images" -Headers $headers -Body $jsonBody  -Method Post | Out-Null
        Write-host "AppVeyor build worker image '$($image_description)' has been created." -ForegroundColor DarkGray
    }
    else {
        $image.name = $image_description
        $image.buildCloudName = $build_cloud_name
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
    Write-host " - To start building on AWS set " -ForegroundColor DarkGray -NoNewline
    Write-host "$($image_description) " -NoNewline 
    Write-host "build worker image in AppVeyor project settings or appveyor.yml." -ForegroundColor DarkGray
    if (Test-Path $aws_kp_path) {
        Write-Host " - Please do not forget to move $($aws_kp_path) to a secure location." -ForegroundColor DarkGray
    }
}

catch {
    Write-Warning "Script exited with error: $($_.Exception)"
    exitScript
}






