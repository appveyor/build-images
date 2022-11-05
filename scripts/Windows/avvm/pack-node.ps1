$ErrorActionPreference = 'Stop'

$avvmRoot = 'c:\avvm\node'

$node_versions = @(
    "14.20.1"
    "14.21.1"
    "16.18.0"
    "16.18.1"
    "17.9.1"
    "18.12.0"
    "19.0.0"
    "19.0.1"
)

foreach ($node_version in $node_versions) {
    $x86path = "$avvmRoot\$node_version\x86\nodejs\node.exe"
    if (-not $node_version.StartsWith('18.0')) {
        if (Test-Path $x86path) {
            $x86 = $(& "$x86path" --version)
            if ($x86 -eq "v$node_version") { Write-Host "$node_version x86 good" -ForegroundColor Green } else { Write-Host "$node_version x86 wrong" -ForegroundColor Red }
        }
        else {
            throw "$x86path not found"
        }
    }

    $x64path = "$avvmRoot\$node_version\x64\nodejs\node.exe"
    if (Test-Path $x64path) {
        $x64 = $(& "$x64path" --version)
        if ($x64 -eq "v$node_version") { Write-Host "$node_version x64 good" -ForegroundColor Green } else { Write-Host "$node_version x64 wrong" -ForegroundColor Red }
    }
    else {
        throw "$x64path not found"
    }    
}

foreach ($node_version in $node_versions) {

    if (-not $node_version.StartsWith('18.0')) {
        Write-Host "Packing $node_version x86"
        7z a "$avvmRoot\node-$node_version-x86.7z" "$avvmRoot\$node_version\x86\*"
    }

    Write-Host "Packing $node_version x64"
    7z a "$avvmRoot\node-$node_version-x64.7z" "$avvmRoot\$node_version\x64\*"
}