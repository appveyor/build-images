$ErrorActionPreference = 'Stop'

$avvmRoot = 'c:\avvm\node'

$node_versions = @(
    "20.14.0",
    "20.15.0"
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