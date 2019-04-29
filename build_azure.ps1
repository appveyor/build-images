[CmdletBinding()]
param
(
  [string]$azure_client_id,
  [string]$azure_client_secret,
  [string]$azure_location,
  [string]$azure_resource_group_name,
  [string]$azure_storage_account,
  [string]$azure_subscription_id,
  [string]$azure_tenant_id,
  [string]$azure_object_id,
  [Parameter(Mandatory=$true)]
  [string]$windows_appveyor_password,
  [string]$DESCR,
  # actualy it have to be enum {"ubuntu1604", "ubuntu1804"}
  [Parameter(Mandatory=$true)]
  [ValidateSet("ubuntu1604", "ubuntu1804", "windows")]
  [string]$TEMPLATE
)

Write-Host "Starting Packer to build Appveyor VM..." -ForegroundColor Cyan

      if (-Not(Test-Path -Path "$TEMPLATE.json")) {
        echo "[ERROR] There is no '${TEMPLATE}.json' template to instruct packer. Aborting build."
        exit 10
      }

      $DATEMARK = Get-Date -UFormat "%Y%m%d%H%M%S"
      $DESCR = "build N $env:APPVEYOR_BUILD_NUMBER, $($env:APPVEYOR_REPO_COMMIT.substring(0,7)), $env:APPVEYOR_REPO_COMMIT_MESSAGE"
      $env:PACKER_LOG_PATH = "./packer-$DATEMARK.log"
      $env:PACKER_LOG = "1"

      echo $env:PACKER_LOG_PATH

      echo "packer build '--only=azure-arm' `
        -var `"azure_client_id=$azure_client_id`" `
        -var `"azure_client_secret=$azure_client_secret`" `
        -var `"azure_location=$azure_location`" `
        -var `"azure_resource_group_name=$azure_resource_group_name`" `
        -var `"azure_storage_account=$azure_storage_account`" `
        -var `"azure_subscription_id=$azure_subscription_id`" `
        -var `"azure_tenant_id=$azure_tenant_id`" `
        -var `"azure_object_id=$azure_object_id`" `
        -var `"windows_appveyor_password=$windows_appveyor_password`" `
        -var `"image_description=$DESCR`" `
        `"$TEMPLATE.json`""


      & packer build '--only=azure-arm' `
        -var-file="azure.json" `
        -var "windows_appveyor_password=$windows_appveyor_password" `
        -var "image_description=$DESCR" `
        "$TEMPLATE.json"

        # -var "azure_client_id=$azure_client_id" `
        # -var "azure_client_secret=$azure_client_secret" `
        # -var "azure_location=$azure_location" `
        # -var "azure_resource_group_name=$azure_resource_group_name" `
        # -var "azure_storage_account=$azure_storage_account" `
        # -var "azure_subscription_id=$azure_subscription_id" `
        # -var "azure_tenant_id=$azure_tenant_id" `
        # -var "azure_object_id=$azure_object_id" `
