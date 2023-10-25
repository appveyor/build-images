$installDir = "C:\Qt"

# set aliases
$sym_links = @{
    "latest" = "5.15.2"
    "6.5"    = "6.5.3"
    "6.4"    = "6.4.3"    
    "6.2"    = "6.2.4"
    "5.15"   = "5.15.2"
    "5.9"    = "5.9.9"
}

foreach ($link in $sym_links.Keys) {
    $target = $sym_links[$link]
    New-Item -ItemType SymbolicLink -Path "$installDir\$link" -Target "$installDir\$target" -Force | Out-Null
}
