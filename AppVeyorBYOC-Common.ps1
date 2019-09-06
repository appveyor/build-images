function InstallAppVeyorHostAgent($appVeyorUrl, $hostAuthorizationToken) {

    $APPVEYOR_HOST_AGENT_MSI_URL = "https://www.appveyor.com/downloads/appveyor/appveyor-host-agent.msi"
    $APPVEYOR_HOST_AGENT_DEB_URL = "https://www.appveyor.com/downloads/appveyor/appveyor-host-agent.deb"    

    Write-Host "Installing AppVeyor Host Agent"

    if ($isLinux) {

        # Linux
        # =======

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
            Write-Host "Host Agent is already installed"
        }

    } elseif ($isMacOS) {

        # macOS
        # =======

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
            Write-Host "Host Agent is already installed"
        }

    } else {

        # Windows
        # =======

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
            Write-Host "Host Agent is already installed"
        }
    }
}