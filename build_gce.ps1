[CmdletBinding()]
param
(
  [string]$BUILDER = "googlecompute",
  [Parameter(Mandatory=$true)]
  [string]$GCE_ZONE,
  [Parameter(Mandatory=$true)]
  [string]$GCE_PROJECT,
  [Parameter(Mandatory=$true)]
  [ValidateScript({Test-Path -Path "$_"})]
  [string]$GCE_ACCFILE,
  [string]$DESCR,
  # actualy it have to be enum {"ubuntu1604", "ubuntu1804", "windows"}
  [Parameter(Mandatory=$true)]
  [ValidateSet("ubuntu1604", "ubuntu1804", "windows")]
  [string]$TEMPLATE
)

# $GCE_ZONE="us-central1-c"
# $GCE_PROJECT="appveyor-ci"
# $GCE_ACCFILE="AppVeyor_CI-f06617683c8e.json"

Write-Host "Starting Packer to build Appveyor VM..." -ForegroundColor Cyan

      if (-Not(Test-Path -Path "$TEMPLATE.json")) {
        echo "[ERROR] There is no '${TEMPLATE}.json' template to instruct packer. Aborting build."
        exit 10
      }

      $DATEMARK = Get-Date -UFormat "%Y%m%d%H%M%S"
      $SNAPNAME="${TEMPLATE}-${DATEMARK}"
      $VM_NAME="packer-${SNAPNAME}-instance"

      $PACKER_PARAMS = @()

      if (-Not([string]::IsNullOrEmpty($env:IS_INCREMENT))) {
        # TODO get latest released image.
        $IMAGE_NAME=((& gcloud compute --project "${GCE_PROJECT}" images list --sort-by='~creationTimestamp' `
                        --limit=1 --filter="name:packer-${TEMPLATE}-" --format='text(name)' | Select-String "Name:") -split ":\s+")[1]
        $UnixEpoch = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $Image_created = $UnixEpoch.AddSeconds(($IMAGE_NAME -split "-")[-1])
        echo "Image used as base is '${IMAGE_NAME}'. Created $Image_created"
        $PACKER_PARAMS+=("-var","gce_source_image=${IMAGE_NAME}")
      }
      if (-Not([string]::IsNullOrEmpty($env:DEPLOY_PARTS))) {
        $PACKER_PARAMS+=( "-var" , "deploy_parts=$env:DEPLOY_PARTS" )
      }
      $PACKER_PARAMS+=( "-var" , "image_description='${DESCR}'" )

      $env:PACKER_LOG_PATH = "./packer-$DATEMARK.log"
      $env:PACKER_LOG = "1"

      echo "packer build --only=${BUILDER} `
        -var `"gce_account_file=$GCE_ACCFILE`" `
        -var `"gce_project=$GCE_PROJECT`" `
        -var `"gce_zone=$GCE_ZONE`" `
        -var `"datemark=$DATEMARK`" `
        $PACKER_PARAMS `
        `"$TEMPLATE.json`""

      & packer build --only=${BUILDER} `
        -var "gce_account_file=$GCE_ACCFILE" `
        -var "gce_project=$GCE_PROJECT" `
        -var "gce_zone=$GCE_ZONE" `
        -var `"datemark=$DATEMARK`" `
        $PACKER_PARAMS `
        "$TEMPLATE.json"

      if (Test-Path -Path "versions.log") {Rename-Item -Path "versions.log" -NewName "versions-$DATEMARK.log"}
      if (Test-Path -Path "pwd.log") {Rename-Item -Path "pwd.log" -NewName "pwd-$DATEMARK.log"}


      # make snapshot
      $IMAGE_NAME=((& gcloud compute --project "${GCE_PROJECT}" images list --sort-by='~creationTimestamp' `
                    --limit=1 --filter="name:packer-${TEMPLATE}-" --format='text(name)' | Select-String "Name:") -split ":\s+")[1]

      if ([string]::IsNullOrEmpty($IMAGE_NAME)) {
        echo "Cannot find image created by packer. Aborting build."
        exit 30
      }

      if (((& gcloud compute instances list --filter="name:${VM_NAME} zone:${GCE_ZONE}" --project "${GCE_PROJECT}" 2> $null ) | Measure-Object -line).Lines -gt 1) {
        & gcloud --quiet compute instances delete "${VM_NAME}" --project "${GCE_PROJECT}" --zone=${GCE_ZONE}
      }

      & gcloud compute instances create "${VM_NAME}" `
        --project "${GCE_PROJECT}" `
        --zone "${GCE_ZONE}" `
        --machine-type "n1-standard-1" `
        --network "default" `
        --no-restart-on-failure `
        --maintenance-policy "TERMINATE" `
        --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" `
        --min-cpu-platform "Automatic" `
        --image "${IMAGE_NAME}" `
        --boot-disk-size "40" `
        --boot-disk-type "pd-standard" `
        --boot-disk-device-name "${VM_NAME}" `
        --description "From image ${IMAGE_NAME}, ${DESCR}"

      if (((& gcloud compute snapshots list --filter="name:${SNAPNAME}" --project "${GCE_PROJECT}" 2> $null ) | Measure-Object -line).Lines -gt 1) {
          & gcloud --quiet compute snapshots delete "${SNAPNAME}" --project "${GCE_PROJECT}"
      }

      & gcloud --quiet compute instances stop "${VM_NAME}" `
          --project "${GCE_PROJECT}" `
          --zone=${GCE_ZONE}

      & gcloud compute disks snapshot "${VM_NAME}" `
          --project "${GCE_PROJECT}" `
          --zone=${GCE_ZONE} `
          --snapshot-names="${SNAPNAME}" `
          --description="${DESCR}"

      & gcloud --quiet compute instances delete "${VM_NAME}" `
          --project "${GCE_PROJECT}" `
          --zone=${GCE_ZONE}





