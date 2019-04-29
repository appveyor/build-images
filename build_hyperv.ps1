[CmdletBinding()]
param
(
  [Parameter(Mandatory=$true)]
  [string]$BUILDER,
  [string]$DESCR,
  # actualy it have to be enum {"ubuntu1604", "ubuntu1804"}
  [Parameter(Mandatory=$true)]
  [ValidateSet("ubuntu1604", "ubuntu1804", "windows")]
  [string]$TEMPLATE
)

Write-Host "Starting Packer to build Appveyor VM..." -ForegroundColor Cyan

      if (-Not(Test-Path -Path "$TEMPLATE.json")) {
        echo "[ERROR] There is no '${TEMPLATE}.json' to instruct packer. Aborting build."
        exit 10
      }

      $DATEMARK = Get-Date -UFormat "%Y%m%d%H%M%S"

      $PACKER_PARAMS = @()

      if (-Not([string]::IsNullOrEmpty($env:DEPLOY_PARTS))) {
        $PACKER_PARAMS+=( "-var" , "deploy_parts=$env:DEPLOY_PARTS" )
      }

      $PACKER_PARAMS+=( "-var" , "image_description='${DESCR}'" )

      $env:PACKER_LOG_PATH = "./packer-$DATEMARK.log"
      $env:PACKER_LOG = "1"

      echo "packer build --only=${BUILDER} `
        -var `"datemark=$DATEMARK`" `
        $PACKER_PARAMS `
        `"$TEMPLATE.json`""

      & packer build --only=${BUILDER} `
        -var `"datemark=$DATEMARK`" `
        $PACKER_PARAMS `
        "$TEMPLATE.json"

      if (Test-Path -Path "versions.log") {Rename-Item -Path "versions.log" -NewName "versions-$DATEMARK.log"}
      if (Test-Path -Path "pwd.log") {Rename-Item -Path "pwd.log" -NewName "pwd-$DATEMARK.log"}


# move result vhdx files from build folder
# this could be non mandatory function with $Path variable
      if ($isWindows -and $(Test-Path -Path "D:")) {
          $PackerOutputFolder = [io.path]::combine(${env:APPVEYOR_BUILD_FOLDER}, "output-hyperv-vmcx", "Virtual Hard Disks")
          $BackupFolder = [io.path]::combine("D:","backup")
          if (Test-Path -Path $PackerOutputFolder) {
              $BackupSubFolder = [io.path]::combine($BackupFolder, "${env:TEMPLATE}-$DATEMARK")
              New-Item -ItemType directory -Path $BackupSubFolder -Force
              Get-ChildItem $PackerOutputFolder -filter "*.vhdx" | % {
                  Move-item -path $_.fullname -Destination [io.path]::combine($BackupSubFolder, "$($_.Name.split("-")[0])-ready-$DATEMARK.vhdx")
              }
              @(
                  "versions-${env:UBUNTU_VERSION}-$DATEMARK.log",
                  "pwd-${env:UBUNTU_VERSION}-$DATEMARK.log",
                  "packer-${env:UBUNTU_VERSION}-$DATEMARK.log"
              ) | % {
                  if (Test-Path -Path $_) {
                      Copy-Item $_ -Destination $BackupSubFolder
                  }
              }
          }
      }
