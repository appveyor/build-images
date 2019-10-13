if ($env:avma_key) {
    cmd /c cscript "%windir%\system32\slmgr.vbs" /ipk $env:avma_key
}
