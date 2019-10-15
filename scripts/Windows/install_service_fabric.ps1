# install runtime
$exePath = "$env:TEMP\MicrosoftServiceFabric-Runtime.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/5/5/5/555B653A-4893-4FBD-A256-3CFC555D626E/MicrosoftServiceFabric.6.3.162.9494.exe', $exePath)
cmd /c start /wait $exePath /AcceptEULA
del $exePath

# install SDK and VS Tools
if (test-path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community") {
    # SDK only
    cmd /c start /wait webpicmd /Install /Products:MicrosoftAzure-ServiceFabric-CoreSDK /AcceptEula
} else {
    # SDK and Tools
    cmd /c start /wait webpicmd /Install /Products:MicrosoftAzure-ServiceFabric-VS2015 /AcceptEula
}

del "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Service Fabric Local Cluster Manager.lnk"
