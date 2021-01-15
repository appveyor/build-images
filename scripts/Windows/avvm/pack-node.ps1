$ErrorActionPreference = 'Stop'

$avvmRoot = 'c:\avvm\node'

$node_versions = @(
    "10.23.1"
    "12.20.1"
    "14.15.4"
    "15.5.1"
    "15.6.0"
)

foreach($node_version in $node_versions) {
    $x86path = "$avvmRoot\$node_version\x86\nodejs\node.exe"
    if (Test-Path $x86path){
        $x86 = $(& "$x86path" --version)
        if ($x86 -eq "v$node_version") { Write-Host "$node_version x86 good" -ForegroundColor Green } else { Write-Host "$node_version x86 wrong" -ForegroundColor Red }
    } else {
        throw "$x86path not found"
    }

    $x64path = "$avvmRoot\$node_version\x64\nodejs\node.exe"
    if (Test-Path $x64path){
        $x64 = $(& "$x64path" --version)
        if ($x64 -eq "v$node_version") { Write-Host "$node_version x64 good" -ForegroundColor Green } else { Write-Host "$node_version x64 wrong" -ForegroundColor Red }
    } else {
        throw "$x64path not found"
    }    
}

foreach($node_version in $node_versions) {

    Write-Host "Packing $node_version x86"
    7z a "$avvmRoot\node-$node_version-x86.7z" "$avvmRoot\$node_version\x86\*"

    Write-Host "Packing $node_version x64"
    7z a "$avvmRoot\node-$node_version-x64.7z" "$avvmRoot\$node_version\x64\*"
}