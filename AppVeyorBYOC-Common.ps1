function CreateSlug($str) {
    return (($str.ToLower() -replace "[^a-z0-9-]", "-") -replace "-+", "-")
}

function InstallAppVeyorHostAgent($appVeyorUrl, $hostAuthorizationToken) {

    $APPVEYOR_HOST_AGENT_MSI_URL = "https://www.appveyor.com/downloads/appveyor/appveyor-host-agent.msi"
    $APPVEYOR_HOST_AGENT_DEB_URL = "https://www.appveyor.com/downloads/appveyor/appveyor-host-agent.deb"    

    Write-Host "`nInstalling AppVeyor Host Agent" -ForegroundColor Cyan

    if ($isLinux) {

        # Linux
        # =======

        Write-Host "OS: Linux" -ForegroundColor Gray

        if (-not (Test-Path '/opt/appveyor/host-agent')) {

            $debPath = "/tmp/appveyor-host-agent.deb"

            Write-Host "Downloading appveyor-host-agent.deb..." -ForegroundColor Gray
            (New-Object Net.WebClient).DownloadFile($APPVEYOR_HOST_AGENT_DEB_URL, $debPath)

            Write-Host "Installing Host Agent..." -ForegroundColor Gray
            sudo bash -c "APPVEYOR_URL=$appVeyorUrl HOST_AUTH_TOKEN=$hostAuthorizationToken dpkg -i $debPath"

            Remove-Item $debPath

            $hostAgentPid = (pidof appveyor-host-agent)
            if ($hostAgentPid) {
                Write-Host "Host Agent has been installed"
            } else {
                Write-Host "Something went wrong and Host Agent was not installed" -ForegroundColor Red
                throw "Error installing Host Agent"
            }

        } else {
            Write-Host "Host Agent is already installed" -ForegroundColor DarkGray
        }

    } elseif ($isMacOS) {

        # macOS
        # =======

        Write-Host "OS: macOS" -ForegroundColor Gray

        $hostAgentProcess = Get-Process "appveyor-host-a" -ErrorAction SilentlyContinue
        if (-not $hostAgentProcess) {
            # make sure Homebrew is installed and available in the path
            if (-not (Get-Command brew -ErrorAction Ignore)) {
                Write-Warning "This command depends on Homebrew package manager. Please install it from https://brew.sh and re-run the command."
                return
            }

            Write-Host "Installing Host Agent..." -ForegroundColor Gray
            bash -c "HOMEBREW_APPVEYOR_URL=$appVeyorUrl HOMEBREW_HOST_AUTH_TKN=$hostAuthorizationToken brew install appveyor/brew/appveyor-host-agent"

            Write-Host "Starting up Host Agent service..."
            brew services start appveyor-host-agent

            $hostAgentProcess = Get-Process "appveyor-host-a" -ErrorAction SilentlyContinue
            if ($hostAgentProcess) {
                Write-Host "Host Agent has been installed"
            } else {
                Write-Host "Something went wrong and Host Agent was not installed" -ForegroundColor Red
                throw "Error installing Host Agent"
            }    
        } else {
            Write-Host "Host Agent is already installed" -ForegroundColor DarkGray
        }

    } else {

        # Windows
        # =======

        Write-Host "OS: Windows" -ForegroundColor Gray

        $hostAgentService = Get-Service "Appveyor.HostAgent" -ErrorAction SilentlyContinue
        if (-not $hostAgentService) {

            if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
                throw "The script should be run in elevated mode to install Host Agent. Run PowerShell in elevated mode (Run as Administrator) and re-run original 'Connect-AppVeyorToComputer' command."
            }

            Write-Host "Downloading appveyor-host-agent.msi..." -ForegroundColor Gray
            $msiPath = "$env:temp\appveyor-host-agent.msi"
            (New-Object Net.WebClient).DownloadFile($APPVEYOR_HOST_AGENT_MSI_URL, $msiPath)

            Write-Host "Installing Host Agent..." -ForegroundColor Gray
            cmd /c msiexec /i $msiPath /quiet APPVEYOR_URL="$appVeyorUrl" HOST_AUTHORIZATION_TOKEN="$hostAuthorizationToken"

            Remove-Item $msiPath
            $hostAgentService = Get-Service "Appveyor.HostAgent" -ErrorAction SilentlyContinue
            if ($hostAgentService) {
                Write-Host "Host Agent has been installed"
            } else {
                Write-Host "Something went wrong and Host Agent was not installed" -ForegroundColor Red
                throw "Error installing Host Agent"
            }                
        } else {
            Write-Host "Host Agent is already installed" -ForegroundColor DarkGray
        }
    }
}

function ValidateAppVeyorApiAccess($appVeyorUrl, $apiToken){
    Write-host "`nChecking AppVeyor API access..."  -ForegroundColor Cyan
    if ($apiToken -like "v2.*") {
        Write-Warning "Please select the API Key for specific account (not 'All Accounts') at '$appVeyorUrl/api-keys'"
        ExitScript
    }

    try {
        $responce = Invoke-WebRequest -Uri $appVeyorUrl -ErrorAction SilentlyContinue
        if ($responce.StatusCode -ne 200) {
            Write-warning "AppVeyor URL '$appVeyorUrl' responded with code $($responce.StatusCode)"
            ExitScript
        }
    }
    catch {
        Write-warning "Unable to connect to AppVeyor URL '$appVeyorUrl'. Error: $($error[0].Exception.Message)"
        ExitScript
    }

    $headers = @{
      "Authorization" = "Bearer $apiToken"
      "Content-type" = "application/json"
    }
    try {
        Invoke-RestMethod -Uri "$appVeyorUrl/api/projects" -Headers $headers -Method Get | Out-Null
    }
    catch {
        Write-warning "Unable to call AppVeyor REST API, please verify 'ApiToken' and ensure '-AppVeyorUrl' parameter is set if you are using on-premise AppVeyor Server."
        ExitScript
    }

    if ($appVeyorUrl -eq "https://ci.appveyor.com") {
          try {
            Invoke-RestMethod -Uri "$appVeyorUrl/api/build-clouds" -Headers $headers -Method Get | Out-Null
        }
        catch {
            Write-warning "Please contact support@appveyor.com and request enabling of 'BYOC' feature."
            ExitScript
        }
    }
    return $headers
}

function ValidateDependencies ($cloudType) {
    Write-host "`nChecking if required tools are installed..."  -ForegroundColor Cyan
    if ($cloudType -eq "Azure") {
        if (-not (Get-Module -Name *Az.* -ListAvailable)) {
            Write-Warning "This command depends on Az PowerShell Module. Please install it with 'Install-Module -Name Az -AllowClobber' command"
            ExitScript
        }

        if (Get-Module -Name *AzureRM.* -ListAvailable) {
            Write-Warning "It is safer to uninstall AzureRM PowerShell module or use different computer to run this command. We noticed unpredictable behaviour when both Az and AzureRM modules are installed. Enter Ctrl-C to stop the command and run 'Uninstall-AzureRm' or do nothing to continue as is.`nWaiting 30 seconds..."
            for ($i = 30; $i -ge 0; $i--) {sleep 1; Write-Host "." -NoNewline}
            Write-Host ""
        }
    }

    if ($cloudType -eq "GCE") {
        if (-not (Get-Command gcloud -ErrorAction Ignore)) {
            Write-Warning "This command depends on Google Cloud SDK. Use 'choco install gcloudsdk' on Windows, for Linux follow https://cloud.google.com/sdk/docs/quickstart-linux, for Mac: https://cloud.google.com/sdk/docs/quickstart-macos"
            ExitScript
        }

        #TODO remove if GoogleCloud does not appear to be needed (if al canbe done with gcloud)
        if (-not (Get-Module -Name GoogleCloud -ListAvailable)) {
            Write-Warning "This command depends on Google Cloud PowerShell module. Please install them with the following command: 'Install-Module -Name GoogleCloud -Force; Import-Module -Name GoogleCloud"
            ExitScript
        }
        #Import module anyway, to be sure.
        Import-Module -Name GoogleCloud
    }

    if ($cloudType -eq "AWS") {
        if (-not (Get-Module -Name *AWSPowerShell* -ListAvailable)) {
            Write-Warning "This command depends on AWS Tools for PowerShell. Please install them with the following command: 'Install-Module -Name AWSPowerShell -Force; Import-Module -Name AWSPowerShell'"
            ExitScript
        }
        if (-not (Get-Command Get-AWSCredentials -ErrorAction Ignore)) {
            Write-Warning "Unable to get 'Get-AWSCredentials' command. Please ensure latest 'AWSPowerShell' module is installed and imported"
            ExitScript
        }
    }

    if (-not (Get-Command packer -ErrorAction Ignore)) {
        Write-Warning "This command depends on Packer by HashiCorp. Please install it with 'choco install packer' command or from download page https://www.packer.io/downloads.html. If it is already installed, please ensure that PATH environment variable contains path to it."
        ExitScript
    }
}

function ParseImageFeatures ($imageFeatures, $imageTemplate, $imageOs) {
    if(-not $imageFeatures) {
        return $imageTemplate
    }
    $imageFeatures = $imageFeatures.Trim()
    if(($imageFeatures.Contains(' ') -and -not $imageFeatures.Contains(',')) -or $imageFeatures.Contains(';')) {
        Write-Warning "'ImageFeatures' should be comma-separate list or single value"
        ExitScript
    }
    if($imageOs -eq "Linux") {
        return $imageTemplate
    }

    $imageFeatures = ($imageFeatures.Split(',') | % { $_.Trim() })

    $before_reboot_scripts = @()
    $imageFeatures | % {
        $scriptName1 = "install_$_.ps1"
        $scriptName2 = "$_.ps1"
        if (Test-Path "$PSScriptRoot/scripts/Windows/$scriptName1") {
            $before_reboot_scripts += "{{ template_dir }}/scripts/Windows/$scriptName1"
            }
        elseif (Test-Path "$PSScriptRoot/scripts/Windows/$scriptName2") {
            $before_reboot_scripts += "{{ template_dir }}/scripts/Windows/$scriptName2"
            }
        else {
            Write-Warning "Unable to find $scriptName1 or $scriptName2 in $PSScriptRoot/scripts/Windows"
            ExitScript
        }
    }

    $after_reboot_scripts = @()
    $imageFeatures | % {
        $scriptName1 = "install_$($_)_after_reboot.ps1"
        $scriptName2 = "$($_)_after_reboot.ps1"
        if (Test-Path "$PSScriptRoot/scripts/Windows/$scriptName1") {
            $after_reboot_scripts += "{{ template_dir }}/scripts/Windows/$scriptName1"
            }
        elseif (Test-Path "$PSScriptRoot/scripts/Windows/$scriptName2") {
            $after_reboot_scripts += "{{ template_dir }}/scripts/Windows/$scriptName2"
            }
    }

    $packer_file = Get-Content $imageTemplate | ConvertFrom-Json

    $before_reboot = @{
        'type' = 'powershell'
        'scripts' = $before_reboot_scripts
        'elevated_user' = '{{user `install_user`}}'
        'elevated_password' = '{{user `install_password`}}'
    }
    $packer_file.provisioners += $before_reboot

    if ($after_reboot_scripts.Count -gt 0) {
        $reboot = @{
            'type' = 'windows-restart'
            'restart_timeout' = '30m'
        }
        $packer_file.provisioners += $reboot

        $after_reboot = @{
            'type' = 'powershell'
            'scripts' = $after_reboot_scripts
            'elevated_user' = '{{user `install_user`}}'
            'elevated_password' = '{{user `install_password`}}'
        }
        $packer_file.provisioners +=$after_reboot
    }

    $imageTemplateCustom = $ImageTemplate.Replace((Get-Item $imageTemplate).Basename, "$((Get-Item $ImageTemplate).Basename)-custom")
    $packer_file | ConvertTo-Json -Depth 20 | Set-Content -Path $imageTemplateCustom
    return $imageTemplateCustom
}

