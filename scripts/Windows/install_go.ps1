. "$PSScriptRoot\common.ps1"

$go_versions = @(
    @{
        "version" = "1.16.3"
        "folder" = "go116"
    }
)

if (-not $env:INSTALL_LATEST_ONLY) {
    $go_versions = $go_versions + @(
        @{
            "version" = "1.15.11"
            "folder" = "go115"
        }        
        @{
            "version" = "1.14.15"
            "folder" = "go114"
        }
        @{
            "version" = "1.13.15"
            "folder" = "go113"
        }
        @{
            "version" = "1.12.17"
            "folder" = "go112"
        }
        @{
            "version" = "1.11.13"
            "folder" = "go111"
        }
        @{
            "version" = "1.10.8"
            "folder" = "go110"
        }
        @{
            "version" = "1.9.7"
            "folder" = "go19"
        }
        @{
            "version" = "1.8.7"
            "folder" = "go18"
        }
        @{
            "version" = "1.7.6"
            "folder" = "go17"
        }
        @{
            "version" = "1.6.4"
            "folder" = "go16"
        }
        @{
            "version" = "1.5.4"
            "folder" = "go15"
        }
        @{
            "version" = "1.4.3"
            "folder" = "go14"
        }
    )    
}

function InstallGo ($go_version, $folder_name) {

    Write-Host "Installing Go $go_version x86..." -ForegroundColor Cyan

    $destDir = "C:\$folder_name"

    Write-Host "Removing Go in $destDir..."
    if(Test-Path $destDir) {
        Remove-Item $destDir -Recurse -Force
    }
    if(Test-Path "$destDir-x86") {
        Remove-Item "$destDir-x86" -Recurse -Force
    }
    
    Write-Host "Downloading..."
    $goDistPath = "$env:TEMP\go$go_version.windows-386.zip"
    (New-Object Net.WebClient).DownloadFile("https://dl.google.com/go/go$go_version.windows-386.zip", $goDistPath)
    
    Write-Host "Unpacking..."
    7z x $goDistPath -o"$destDir-temp-x86" | Out-Null
    [IO.Directory]::Move("$destDir-temp-x86\go", "$destDir-x86")
    Remove-Item "$destDir-temp-x86" -Recurse -Force
    del $goDistPath
    
    Write-Host "Installing Go $go_version x64..." -ForegroundColor Cyan
    
    Write-Host "Downloading..."
    $goDistPath = "$env:TEMP\go$go_version.windows-amd64.zip"
    (New-Object Net.WebClient).DownloadFile("https://dl.google.com/go/go$go_version.windows-amd64.zip", $goDistPath)
    
    Write-Host "Unpacking..."
    7z x $goDistPath -o"$destDir-temp-x64" | Out-Null
    [IO.Directory]::Move("$destDir-temp-x64\go", "$destDir")
    Remove-Item "$destDir-temp-x64" -Recurse -Force
    del $goDistPath
}

if(Test-Path 'C:\go') {
    Remove-Item 'C:\go' -Recurse -Force
}
if(Test-Path 'C:\go-x86') {
    Remove-Item 'C:\go-x86' -Recurse -Force
}

# install go
for($i = 0; $i -lt $go_versions.Count; $i++) {
    InstallGo $go_versions[$i].version $go_versions[$i].folder
}

cmd /c mklink /J C:\go "C:\$($go_versions[0].folder)"
cmd /c mklink /J C:\go-x86 "C:\$($go_versions[0].folder)-x86"

# make sure paths added
Add-Path C:\go\bin
Add-SessionPath C:\go\bin

# set GOROOT variable
[Environment]::SetEnvironmentVariable("GOROOT", 'C:\go', "Machine")

Start-ProcessWithOutput "go version"

# test go installations

for($i = 0; $i -lt $go_versions.Count; $i++) {
    Write-Host "$($go_versions[$i].version)" -ForegroundColor Cyan
    Start-ProcessWithOutput "C:\$($go_versions[$i].folder)\bin\go.exe version" -IgnoreExitCode
    Start-ProcessWithOutput "C:\$($go_versions[$i].folder)-x86\bin\go.exe version" -IgnoreExitCode
}
