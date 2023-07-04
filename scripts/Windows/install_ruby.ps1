﻿. "$PSScriptRoot\common.ps1"

$started = Get-Date

# download SSL certificates
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object Net.WebClient).DownloadFile('http://curl.haxx.se/ca/cacert.pem', "$env:temp\cacert.pem")
$env:SSL_CERT_FILE = "$env:temp\cacert.pem"

if (-not $env:INSTALL_LATEST_ONLY) {
    $rubies = @(
        @{
            "version"            = "Ruby 1.9.3-p551"
            "install_path"       = "C:\Ruby193"
            "download_url"       = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby193.zip"
            "devkit_paths"       = @()
            "install_psych"      = "true"
            "dontUpdate"         = $true
            "dontUpdateRubygems" = $true
            #"rubygemsUpdate" = $true
        }
        @{
            "version"        = "Ruby 2.0.0-p648"
            "install_path"   = "C:\Ruby200"
            "download_url"   = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby200.zip"
            "devkit_paths"   = @()
            "install_psych"  = "true"
            "dontUpdate"     = $true
            "rubygemsUpdate" = $true
        }
        @{
            "version"        = "Ruby 2.0.0-p648 (x64)"
            "install_path"   = "C:\Ruby200-x64"
            "download_url"   = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby200-x64.zip"
            "install_psych"  = "true"
            "dontUpdate"     = $true
            "rubygemsUpdate" = $true
        }
        @{
            "version"        = "Ruby 2.2.6"
            "install_path"   = "C:\Ruby22"
            "download_url"   = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby22.zip"
            "dontUpdate"     = $true
            "rubygemsUpdate" = $true
        }
        @{
            "version"        = "Ruby 2.2.6 (x64)"
            "install_path"   = "C:\Ruby22-x64"
            "download_url"   = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby22-x64.zip"
            "dontUpdate"     = $true
            "rubygemsUpdate" = $true
        }
        @{
            "version"        = "Ruby 2.1.9"
            "install_path"   = "C:\Ruby21"
            "download_url"   = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby21.zip"
            "dontUpdate"     = $true
            "rubygemsUpdate" = $true
        }
        @{
            "version"        = "Ruby 2.1.9 (x64)"
            "install_path"   = "C:\Ruby21-x64"
            "download_url"   = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby21-x64.zip"
            "dontUpdate"     = $true
            "rubygemsUpdate" = $true
        }
        @{
            "version"      = "Ruby 2.3.3"
            "install_path" = "C:\Ruby23"
            "download_url" = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby23.zip"
            "devkit_paths" = @()
            "dontUpdate"   = $true
            "bundlerV2"    = $true
        }
        @{
            "version"      = "Ruby 2.3.3 (x64)"
            "install_path" = "C:\Ruby23-x64"
            "download_url" = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby23-x64.zip"
            "devkit_paths" = @()
            "dontUpdate"   = $true
            "bundlerV2"    = $true
        }
        @{
            "version"      = "Ruby 2.4.10-1"
            "install_path" = "C:\Ruby24"
            "download_url" = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby24.zip"
            "devkit_url"   = ""
            "devkit_paths" = @()
            "dontUpdate"   = $true
            "bundlerV2"    = $true
        }
        @{
            "version"      = "Ruby 2.4.10-1 (x64)"
            "install_path" = "C:\Ruby24-x64"
            "download_url" = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby24-x64.zip"
            "devkit_url"   = ""
            "devkit_paths" = @()
            "dontUpdate"   = $true
            "bundlerV2"    = $true
        }
        @{
            "version"      = "Ruby 2.5.9-1"
            "install_path" = "C:\Ruby25"
            "download_url" = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby25.zip"
            "devkit_url"   = ""
            "devkit_paths" = @()
            "dontUpdate"   = $true
            "bundlerV2"    = $true
        }
        @{
            "version"      = "Ruby 2.5.9-1 (x64)"
            "install_path" = "C:\Ruby25-x64"
            "download_url" = "https://appveyordownloads.blob.core.windows.net/misc/ruby/Ruby25-x64.zip"
            "devkit_url"   = ""
            "devkit_paths" = @()
            "dontUpdate"   = $true
            "bundlerV2"    = $true
        }
        @{
            "version"      = "Ruby 2.6.9-1"
            "install_path" = "C:\Ruby26"
            "download_url" = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.6.9-1/rubyinstaller-2.6.9-1-x86.exe"
            "devkit_url"   = ""
            "devkit_paths" = @()
            "bundlerV2"    = $true
        }    
        @{
            "version"      = "Ruby 2.6.9-1 (x64)"
            "install_path" = "C:\Ruby26-x64"
            "download_url" = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.6.9-1/rubyinstaller-2.6.9-1-x64.exe"
            "devkit_url"   = ""
            "devkit_paths" = @()
            "bundlerV2"    = $true
        }
        @{
            "version"      = "Ruby 2.7.8-1"
            "install_path" = "C:\Ruby27"
            "download_url" = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.7.8-1/rubyinstaller-2.7.8-1-x86.exe"
            "devkit_url"   = ""
            "devkit_paths" = @()
            "bundlerV2"    = $true
        }    
        @{
            "version"      = "Ruby 2.7.8-1 (x64)"
            "install_path" = "C:\Ruby27-x64"
            "download_url" = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.7.8-1/rubyinstaller-2.7.8-1-x64.exe"
            "devkit_url"   = ""
            "devkit_paths" = @()
            "bundlerV2"    = $true
        }        
    )
}
else {
    $rubies = @()
}

$rubies = $rubies + @(
    @{
        "version"      = "Ruby 3.0.6-1"
        "install_path" = "C:\Ruby30"
        "download_url" = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.0.6-1/rubyinstaller-3.0.6-1-x86.exe"
        "devkit_url"   = ""
        "devkit_paths" = @()
        "bundlerV2"    = $true
    }    
    @{
        "version"      = "Ruby 3.0.6-1 (x64)"
        "install_path" = "C:\Ruby30-x64"
        "download_url" = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.0.6-1/rubyinstaller-3.0.6-1-x64.exe"
        "devkit_url"   = ""
        "devkit_paths" = @()
        "bundlerV2"    = $true
    }
    @{
        "version"      = "Ruby 3.1.4-1"
        "install_path" = "C:\Ruby31"
        "download_url" = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.1.4-1/rubyinstaller-3.1.4-1-x86.exe"
        "devkit_url"   = ""
        "devkit_paths" = @()
        "bundlerV2"    = $true
    }
    @{
        "version"      = "Ruby 3.1.4-1 (x64)"
        "install_path" = "C:\Ruby31-x64"
        "download_url" = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.1.4-1/rubyinstaller-3.1.4-1-x64.exe"
        "devkit_url"   = ""
        "devkit_paths" = @()
        "bundlerV2"    = $true
    }
    @{
        "version"      = "Ruby 3.2.2-1"
        "install_path" = "C:\Ruby32"
        "download_url" = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.2.2-1/rubyinstaller-3.2.2-1-x86.exe"
        "devkit_url"   = ""
        "devkit_paths" = @()
        "bundlerV2"    = $true
    }
    @{
        "version"      = "Ruby 3.2.2-1 (x64)"
        "install_path" = "C:\Ruby32-x64"
        "download_url" = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.2.2-1/rubyinstaller-3.2.2-1-x64.exe"
        "devkit_url"   = ""
        "devkit_paths" = @()
        "bundlerV2"    = $true
    }
)

function UpdateRubyPath($rubyPath) {
    $env:path = ($env:path -split ';' | Where-Object { -not $_.contains('\Ruby') }) -join ';'
    $env:path = "$rubyPath;$env:path"
}
function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
    | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
    | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
    | Select UninstallString).UninstallString
}

function Get-FileNameFromUrl($url) {
    $fileName = $url.Trim('/')
    $idx = $fileName.LastIndexOf('/')
    if ($idx -ne -1) {
        $fileName = $fileName.substring($idx + 1)
        $idx = $fileName.IndexOf('?')
        if ($idx -ne -1) {
            $fileName = $fileName.substring(0, $idx)
        }
    }
    return $fileName
}

function Install-Ruby($ruby) {
    Write-Host "Installing $($ruby.version)" -ForegroundColor Cyan

    if ($ruby.download_url.contains('github.com')) {
        #########################
        ##
        ##  New 2.4 installer
        ##
        #########################

        # uninstall existing
        $rubyUninstallPath = "$ruby.install_path\unins000.exe"
        if ([IO.File]::Exists($rubyUninstallPath)) {
            Write-Host "  Uninstalling previous Ruby 2.4..." -ForegroundColor Gray
            "`"$rubyUninstallPath`" /silent" | out-file "$env:temp\uninstall-ruby.cmd" -Encoding ASCII
            & "$env:temp\uninstall-ruby.cmd"
            del "$env:temp\uninstall-ruby.cmd"
            Start-Sleep -s 5
        }

        if (Test-Path $ruby.install_path) {
            Write-Host "  Deleting $($ruby.install_path)" -ForegroundColor Gray
            Remove-Item $ruby.install_path -Force -Recurse
        }

        $exePath = "$($env:TEMP)\rubyinstaller.exe"

        Write-Host "  Downloading $($ruby.version) from $($ruby.download_url)" -ForegroundColor Gray
        (New-Object Net.WebClient).DownloadFile($ruby.download_url, $exePath)

        Write-Host "Installing..." -ForegroundColor Gray
        cmd /c start /wait $exePath /verysilent /allusers /dir="$($ruby.install_path.replace('\', '/'))" /tasks="noassocfiles,nomodpath,noridkinstall"
        del $exePath
        Write-Host "Installed" -ForegroundColor Green

        # setup Ruby
        UpdateRubyPath "$($ruby.install_path)\bin"
        Write-Host "ruby --version" -ForegroundColor Gray
        cmd /c ruby --version

        Write-Host "gem --version" -ForegroundColor Gray
        cmd /c gem --version

        # list installed gems
        Write-Host "gem list --local" -ForegroundColor Gray
        cmd /c gem list --local

    }
    else {
        #########################
        ##
        ##  Old installer
        ##
        #########################

        # delete if exists
        if (Test-Path $ruby.install_path) {
            Write-Host "  Deleting $($ruby.install_path)" -ForegroundColor Gray
            Remove-Item $ruby.install_path -Force -Recurse
        }

        # create temp directory for all downloads
        $tempPath = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        New-Item $tempPath -ItemType Directory | Out-Null

        $distFileName = Get-FileNameFromUrl $ruby.download_url
        $distLocalFileName = (Join-Path $tempPath $distFileName)

        # download archive to a temp
        Write-Host "  Downloading $($ruby.version) from $($ruby.download_url)" -ForegroundColor Gray
        (New-Object Net.WebClient).DownloadFile($ruby.download_url, $distLocalFileName)

        # extract archive to C:\
        Write-Host "  Extracting Ruby files..." -ForegroundColor Gray
        cmd /c 7z x $distLocalFileName -o"$($ruby.install_path)" | Out-Null

        # setup Ruby
        UpdateRubyPath "$($ruby.install_path)\bin"
        Write-Host "ruby --version" -ForegroundColor Gray
        cmd /c ruby --version

        Write-Host "gem --version" -ForegroundColor Gray
        cmd /c gem --version

        # list installed gems
        Write-Host "gem list --local" -ForegroundColor Gray
        cmd /c gem list --local
    }

    # delete temp path
    if ($tempPath) {
        Write-Host "  Cleaning up..." -ForegroundColor Gray
        Remove-Item $tempPath -Force -Recurse
    }

    Write-Host "  Done!" -ForegroundColor Green
}

function Update-Ruby($ruby) {

    if ($ruby.dontUpdate) {
        return
    }

    Write-Host "Updating $($ruby.version)" -ForegroundColor Cyan

    UpdateRubyPath "$($ruby.install_path)\bin"

    if ($ruby.install_psych) {
        Write-Host "gem install psych -v 2.2.4" -ForegroundColor Gray
        Start-ProcessWithOutput "gem install psych -v 2.2.4 --no-rdoc"
    }
    elseif ($ruby.update_psych) {
        Write-Host "gem update psych" -ForegroundColor Gray
        Start-ProcessWithOutput "gem update psych"
    }

    if (-not $ruby.dontUpdateRubygems) {
        if ($ruby.rubygemsUpdate) {
            # Ruby < 2.3
            Write-Host "gem install rubygems-update -v `"~>2.7`" --no-rdoc" -ForegroundColor Gray
            cmd /c gem install rubygems-update -v `"~>2.7`" --no-rdoc
            
            Write-Host "update_rubygems" -ForegroundColor Gray
            & "$($ruby.install_path)\bin\ruby.exe" "$($ruby.install_path)\bin\update_rubygems" --silent
        } else {
            # Ruby > 2.5
            Write-Host "gem update --system" -ForegroundColor Gray
            cmd /c gem update --system
        }
    }

    # cleanup old gems
    Write-Host "gem cleanup" -ForegroundColor Gray
    cmd /c gem cleanup

    # list installed gems
    Write-Host "gem list --local" -ForegroundColor Gray
    cmd /c gem list --local

    # install bundler v1.x package
    Write-Host "gem install bundler -v `"~>1.17`" --force" -ForegroundColor Gray
    cmd /c gem install bundler -v `"~>1.17`" --force

    # install bundler v2.x package
    if ($ruby.bundlerV2) {
        Write-Host "gem install bundler --force" -ForegroundColor Gray
        cmd /c gem install bundler --force
    }

    # fix "bundler" executable
    Write-Host "fix bundler.bat"
    Copy-Item -Path "$($ruby.install_path)\bin\bundle" -Destination "$($ruby.install_path)\bin\bundler" -Force
    Copy-Item -Path "$($ruby.install_path)\bin\bundle.bat" -Destination "$($ruby.install_path)\bin\bundler.bat" -Force  

    Write-Host "  Done!" -ForegroundColor Green
}

# save current directory
for ($i = 0; $i -lt $rubies.Count; $i++) {
    Install-Ruby $rubies[$i]
}

for ($i = 0; $i -lt $rubies.Count; $i++) {
    Update-Ruby $rubies[$i]
}

# Fix bundler.bat
# @("Ruby193","Ruby200","Ruby200-x64","Ruby21","Ruby21-x64","Ruby22","Ruby22-x64","Ruby23","Ruby23-x64","Ruby24","Ruby24-x64") | % { Copy-Item "C:\$_\bin\bundle.bat" -Destination "C:\$_\bin\bundler.bat" -Force; Copy-Item "C:\$_\bin\bundle" -Destination "C:\$_\bin\bundler" -Force }

# print summary
for ($i = 0; $i -lt $rubies.Count; $i++) {
    $ruby = $rubies[$i]
    UpdateRubyPath "$($ruby.install_path)\bin"
    Write-Host "$($ruby.version)" -ForegroundColor Cyan
    Write-Host "  ruby --version: $(cmd /c ruby --version)"
    Write-Host "  gem --version: $(cmd /c gem --version)"
    Write-Host "  gem list bundler --local: $(cmd /c gem list bundler --local)"
    Write-Host "  bundle --version: $(cmd /c bundle --version)"
    Write-Host "  bundler --version: $(cmd /c bundler --version)"
}

Add-Path 'C:\Ruby31\bin'

((Get-Date) - $started)